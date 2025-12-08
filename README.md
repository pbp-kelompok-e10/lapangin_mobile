# lapangin

# TUGAS KELOMPOK PBP E

# KELOMPOK E10

### ANGGOTA KELOMPOK

  - Prasetya Surya Syahputra
  - Rheina Adinda Morani Sinurat 2406435881
  - Muhammad Fadhlurrohman Pasya 2406411830
  - Angga Ziaurrohchman 2406495943
  - Muhammad Tristan Malik Anbiya 2406409196

## Aplikasi

Aplikasi Lapangin dirancang untuk membantu klub atau panitia pertandingan untuk mencari stadion yang sesuai untuk menggelar pertandingan. Platform ini menyediakan informasi lengkap seputar lokasi, kapasitas,dan pengelola stadion di berbagai daerah, serta memungkinkan pengguna menyewa langsung pada aplikasi.

## Daftar Modul

1.  Review Stadion (Rheina Adinda Morani Sinurat)
    Pada halaman ini, pengguna dapat menambahkan ulasan atau review terhadap Stadion yang telah mereka sewa. Pengguna dan admin memiliki akses untuk mengedit dan menghapus review.

2.  Pencarian Stadion (Prasetya Surya Syahputra)
    Menu ini memungkinkan pengguna untuk menjelajahi daftar Stadion yang tersedia berdasarkan lokasi, kapasitas, dan pengelola stadion. Admin memiliki akses untuk menambahkan, mengedit, dan menghapus data venue agar informasi selalu up to date.

3.  Booking Stadion (Muhammad Fadhlurrohman Pasya)
    Pengguna dapat melakukan pemesanan Stadion untuk tanggal dan waktu tertentu. Saat melakukan booking, Pengguna dan admin juga dapat mengedit atau membatalkan booking sebelum waktu penyewaan dimulai.

4.  User (Muhammad Tristan Malik Anbiya)
    Admin dapat melihat daftar pengguna yang terdaftar dalam aplikasi. Selain itu, admin juga dapat menambahkan pengguna baru, mengedit data pengguna, atau menghapus akun pengguna yang tidak aktif.

5.  FAQ (Angga Ziaurrohchman)
    Pengguna dapat melihat jawaban dari FAQ, admin dapat menambahkan, menghapus, dan mengedit FAQ

## Sumber Initial Dataset kategori utama produk

- Kaggle:
[https://www.kaggle.com/datasets/antimoni/football-stadiums](https://www.kaggle.com/datasets/antimoni/football-stadiums)
- Dummy Data untuk harga sewa

## Role pengguna beserta deskripsi

2. Pengguna (User):
Menggunakan Lapangin untuk menelusuri dan menemukan Stadion yang bisa disewa
Menyewa Stadion untuk keperluan latihan atau pertandingan
Memberikan ulasan setelah menyewa Stadion atau menyewakan stadionnya
3. Administrator (Admin):
Mengelola seluruh aplikasi, termasuk memantau aktivitas pengguna.
Menangani permasalahan teknis dan memberikan bantuan.
Memastikan aplikasi berfungsi dengan baik, selalu diperbarui, dan tetap aman digunakan.

-----

## Alur pengintegrasian dengan web service untuk terhubung dengan aplikasi web yang sudah dibuat saat Proyek Tengah Semester

1. Authentication
User input -> flutter -> django API -> success -> accese granted/deleted and session created/deleted

2. Create Data
User input -> flutter -> django API -> save to database -> response back -> UI update

3. Get Data
Flutter request -> django API -> get from database -> response back -> UI update


----- 

## Tautan deplomen PWS dan Link design

- PWS : [https://angga-ziaurrohchman-lapangin.pbp.cs.ui.ac.id/](https://angga-ziaurrohchman-lapangin.pbp.cs.ui.ac.id/)
- Link Design : [https://www.figma.com/design/RaRxA8STyW3ax1YRha9lYu/PBP?node-id=1-2\&t=6U2el2vgKl0KXWTc-1](https://www.figma.com/design/RaRxA8STyW3ax1YRha9lYu/PBP?node-id=1-2&t=6U2el2vgKl0KXWTc-1)