# NOVA FASHION — LIMITED EDITION

Website katalog dan order gratis dengan aturan:
- Satu produk hanya dapat diorder satu kali oleh satu peserta.
- Satu Roblox Username hanya dapat mengorder satu produk.
- Produk yang berhasil diorder otomatis menjadi TAKEN / SOLD OUT.
- Order diproses di database dengan row lock + unique constraints, sehingga dua peserta tidak bisa mengambil produk yang sama bersamaan.
- Tidak ada pembayaran/transaksi; semua klaim Rp0.
- Peserta tidak perlu membuat akun. Admin login memakai akun Supabase.

## Penting
Ini adalah paket website yang terhubung ke backend Supabase, tetapi **belum live** sampai pemilik membuat project Supabase, menjalankan SQL, membuat akun admin, dan mengisi `config.js`. Jangan publikasikan dengan konfigurasi placeholder.

## Setup database (sekali oleh admin)
1. Buat project di https://supabase.com (akun admin/pengelola saja).
2. Buka SQL Editor, tempel seluruh isi `schema.sql`, lalu Run.
3. Buka Authentication > Users > Add user. Buat email dan password khusus admin.
4. Salin UUID user admin tersebut, lalu jalankan di SQL Editor:
   `insert into public.admins(user_id) values ('UUID-ADMIN');`
5. Buka Project Settings > API. Salin Project URL dan anon/public key.
6. Isi `config.js`:
   `url: "https://....supabase.co"` dan `anonKey: "ey..."`.
   Anon key memang digunakan di website publik; keamanan berasal dari RLS dan function di database. Jangan pernah memasukkan service_role key ke website.
7. Hosting: unggah seluruh isi folder ini ke layanan static hosting (misalnya Cloudflare Pages). Pastikan `index.html`, `config.js`, dan file lain berada di root yang dipublikasikan.

## Cara pakai
- Peserta membuka website, memilih produk AVAILABLE, memasukkan Roblox Username, lalu menekan tombol order. Clothing ID ditampilkan setelah order berhasil.
- Order sukses akan mengubah produk menjadi TAKEN. Clothing ID langsung ditampilkan kepada peserta dan produk tidak bisa diorder lagi.
- Username yang sama tidak bisa mengorder produk kedua.
- Admin membuka tombol Admin, login dengan akun yang dibuat di Supabase, lalu dapat menambah, mengedit, menghapus produk yang belum diklaim, mengunggah foto dari perangkat, dan melihat daftar klaim.

## Catatan operasional
- Status klaim bersifat permanen pada paket ini. Jangan menghapus data klaim langsung dari database tanpa prosedur koreksi yang jelas.
- Menghapus produk yang sudah diklaim akan ditolak oleh database karena riwayat klaim harus dipertahankan.
- Untuk menjaga keamanan, gunakan password admin yang kuat dan jangan bagikan ke peserta.
- Website ini tidak memverifikasi kepemilikan Roblox Username; peserta mengetik username sendiri. Jika verifikasi identitas dibutuhkan, perlu alur tambahan.
- Foto maksimal 5 MB; format JPG, PNG, WebP.
- Website memerlukan koneksi internet dan Supabase aktif.
