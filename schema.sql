-- NOVA FASHION — SUPABASE DATABASE SETUP
-- Jalankan seluruh script ini di Supabase > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

create or replace function public.is_nova_admin()
returns boolean language sql stable security definer
set search_path = public
as $$ select exists(select 1 from public.admins where user_id = auth.uid()); $$;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  clothing_id text,
  image_url text,
  status text not null default 'available' check (status in ('available','claimed')),
  created_at timestamptz not null default now()
);

create table if not exists public.claims (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null unique references public.products(id) on delete restrict,
  roblox_username text not null,
  username_normalized text not null unique,
  claimed_at timestamptz not null default now()
);

alter table public.products enable row level security;
alter table public.claims enable row level security;
alter table public.admins enable row level security;

drop policy if exists "Public can view products" on public.products;
create policy "Public can view products" on public.products for select using (true);
drop policy if exists "Admins manage products" on public.products;
create policy "Admins manage products" on public.products for all using (public.is_nova_admin()) with check (public.is_nova_admin());
drop policy if exists "Admins view claims" on public.claims;
create policy "Admins view claims" on public.claims for select using (public.is_nova_admin());
drop policy if exists "Admins view own admin row" on public.admins;
create policy "Admins view own admin row" on public.admins for select using (user_id = auth.uid());

-- Atomic claim: row lock + unique constraints prevent double claims/race conditions.
create or replace function public.claim_product(p_product_id uuid, p_roblox_username text)
returns jsonb language plpgsql security definer
set search_path = public
as $$
declare
  v_product public.products%rowtype;
  v_username text := btrim(p_roblox_username);
  v_normalized text := lower(btrim(p_roblox_username));
begin
  if v_username is null or length(v_username) < 3 or length(v_username) > 20
     or v_username !~ '^[A-Za-z0-9_]+$' then
    return jsonb_build_object('success',false,'message','Roblox Username tidak valid.');
  end if;

  select * into v_product from public.products where id = p_product_id for update;
  if not found then
    return jsonb_build_object('success',false,'message','Produk tidak ditemukan.');
  end if;
  if v_product.status <> 'available' then
    return jsonb_build_object('success',false,'message','Produk sudah diklaim peserta lain.');
  end if;
  if exists(select 1 from public.claims where username_normalized = v_normalized) then
    return jsonb_build_object('success',false,'message','Username ini sudah pernah mengklaim satu produk.');
  end if;

  begin
    insert into public.claims(product_id,roblox_username,username_normalized)
    values(p_product_id,v_username,v_normalized);
  exception when unique_violation then
    return jsonb_build_object('success',false,'message','Produk atau username sudah diklaim.');
  end;

  update public.products set status='claimed' where id=p_product_id;
  return jsonb_build_object('success',true,'message','Klaim berhasil.');
end;
$$;
revoke all on function public.claim_product(uuid,text) from public;
grant execute on function public.claim_product(uuid,text) to anon, authenticated;

-- Storage bucket for product photos.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('product-images','product-images',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

drop policy if exists "Public read product images" on storage.objects;
create policy "Public read product images" on storage.objects for select
using (bucket_id = 'product-images');
drop policy if exists "Admins upload product images" on storage.objects;
create policy "Admins upload product images" on storage.objects for insert
with check (bucket_id = 'product-images' and public.is_nova_admin());
drop policy if exists "Admins update product images" on storage.objects;
create policy "Admins update product images" on storage.objects for update
using (bucket_id = 'product-images' and public.is_nova_admin())
with check (bucket_id = 'product-images' and public.is_nova_admin());
drop policy if exists "Admins delete product images" on storage.objects;
create policy "Admins delete product images" on storage.objects for delete
using (bucket_id = 'product-images' and public.is_nova_admin());

-- AFTER creating your admin user in Supabase Authentication > Users,
-- replace the UUID below and run:
-- insert into public.admins(user_id) values ('PASTE-ADMIN-USER-UUID-HERE');

-- Explicit table privileges used by the website.
grant select on public.products to anon, authenticated;
grant select on public.claims to authenticated;
grant select on public.admins to authenticated;
grant insert, update, delete on public.products to authenticated;
