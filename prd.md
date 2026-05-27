# Product Requirements Document (PRD)

## Aplikasi Navigasi & Perjalanan Ibadah

Version: 1.0
Status: Draft
Platform: Android (Flutter)
Prepared For: Mobile Navigation & Islamic Travel Assistant Application

---

# 1. Ringkasan Produk

Aplikasi ini adalah platform navigasi mobile berbasis Flutter yang membantu pengguna melakukan perjalanan seperti aplikasi navigasi modern, sekaligus memberikan dukungan ibadah bagi musafir.

Aplikasi akan menyediakan:

* Navigasi real-time
* GPS tracking
* Turn-by-turn navigation
* Informasi rute perjalanan
* Estimasi waktu dan jarak
* Status safar
* Informasi qasar dan jamak
* Pengingat waktu salat
* Masjid dan fasilitas ibadah terdekat

Tujuan utama aplikasi adalah menggabungkan pengalaman navigasi modern dengan kebutuhan ibadah selama perjalanan.

---

# 2. Visi Produk

Menjadi aplikasi navigasi perjalanan yang membantu pengguna mencapai tujuan dengan aman sekaligus menjaga kemudahan ibadah selama perjalanan.

---

# 3. Target Pengguna

## 3.1 Pengguna Utama

* Pengendara motor
* Pengendara mobil
* Musafir
* Driver travel
* Pengguna muslim yang sering bepergian
* Jamaah perjalanan jauh

## 3.2 Pengguna Sekunder

* Wisatawan muslim
* Kurir
* Driver online
* Komunitas touring
* Travel umrah dan ziarah

---

# 4. Tujuan Bisnis

* Menyediakan alternatif navigasi lokal
* Menawarkan fitur islami yang belum umum pada aplikasi navigasi
* Membangun ekosistem perjalanan muslim
* Menjadi platform navigasi komunitas

---

# 5. Teknologi yang Digunakan

## 5.1 Frontend

* Flutter
* Dart

## 5.2 Peta & Navigasi

* OpenStreetMap
* MapLibre GL
* OSRM / GraphHopper / Valhalla

## 5.3 Backend

* Firebase / Supabase / VPS Ubuntu

## 5.4 Database

* PostgreSQL
* Firebase Firestore

## 5.5 GPS & Sensor

* Geolocator
* Flutter Compass

## 5.6 Voice Navigation

* Flutter TTS

---

# 6. Fitur Utama

# 6.1 Sistem Peta

## Fitur

* Menampilkan peta interaktif
* Zoom in/out
* Rotasi peta
* Mode satelit (opsional)
* Tampilan 2D dan 3D
* Marker lokasi
* Layer jalan
* Layer bangunan
* Layer masjid
* Layer SPBU
* Layer rest area

## Kebutuhan Teknis

* Tile rendering
* Tile caching
* Marker management
* Smooth animation

---

# 6.2 GPS & Lokasi Real-Time

## Fitur

* Menampilkan lokasi pengguna
* Tracking posisi real-time
* Akurasi GPS
* Deteksi heading kendaraan
* Auto follow location
* Recenter map
* Live speed detection
* Altitude detection

## Tampilan

* Panah kendaraan
* Lingkaran akurasi GPS
* Indikator arah kompas

---

# 6.3 Sistem Pencarian Lokasi

## Fitur

* Cari alamat
* Cari nama tempat
* Autocomplete pencarian
* Riwayat pencarian
* Favorit lokasi
* Reverse geocoding

## Jenis Lokasi

* Rumah
* Masjid
* Rest area
* SPBU
* Rumah makan
* Hotel
* Tempat wisata
* Rumah sakit

---

# 6.4 Sistem Routing

## Fitur

* Cari rute tercepat
* Cari rute terdekat
* Alternatif rute
* Multi-stop destination
* Hindari tol
* Hindari macet
* Hindari jalan rusak
* Mode kendaraan:

  * Motor
  * Mobil
  * Jalan kaki

## Informasi Ditampilkan

* Jarak total
* Estimasi waktu
* Total belokan
* Jalan utama yang dilalui

---

# 6.5 Turn-by-Turn Navigation

## Fitur

* Navigasi real-time
* Instruksi belok
* Voice navigation
* Lane guidance
* Re-routing otomatis
* Perhitungan ulang rute
* Indikator belokan berikutnya
* Progress perjalanan

## Contoh Instruksi

* Belok kiri 200 meter lagi
* Tetap lurus
* Ambil putaran balik
* Tujuan ada di kanan

---

# 6.6 Voice Navigation

## Fitur

* Suara navigasi bahasa Indonesia
* Suara otomatis saat belok
* Pengaturan volume
* Mute navigation
* Background voice support

---

# 6.7 Sistem Safar, Qasar, dan Jamak

## Tujuan

Memberikan informasi perjalanan terkait status safar pengguna.

## Fitur

* Menghitung jarak safar
* Menentukan status musafir
* Informasi qasar
* Informasi jamak
* Pilihan mazhab
* Estimasi waktu salat selama perjalanan
* Pengingat salat musafir

## Mazhab

* Syafi'i
* Hanafi
* Maliki
* Hanbali

## Informasi yang Ditampilkan

* Jarak perjalanan
* Status safar
* Perkiraan memenuhi syarat safar
* Rekomendasi qasar/jamak
* Catatan perbedaan pendapat mazhab

## Catatan Penting

Aplikasi tidak mengeluarkan fatwa mutlak. Informasi bersifat panduan berdasarkan pengaturan pengguna.

---

# 6.8 Waktu Salat

## Fitur

* Jadwal salat otomatis
* Alarm adzan
* Notifikasi salat
* Countdown waktu salat
* Lokasi kiblat
* Mode musafir

## Metode Perhitungan

* Kemenag
* Muslim World League
* Umm al-Qura

---

# 6.9 Masjid dan Tempat Ibadah

## Fitur

* Masjid terdekat
* Masjid di sepanjang rute
* Musholla terdekat
* Tempat wudhu
* Informasi fasilitas

## Informasi Tempat

* Nama masjid
* Jam buka
* Rating pengguna
* Fasilitas parkir
* Tempat wudhu
* Foto lokasi

---

# 6.10 Sistem Offline

## Fitur

* Download area map
* Offline routing
* Offline navigation
* Offline search
* Cache lokasi favorit

## Kebutuhan

* Penyimpanan lokal
* Compression data
* Tile offline storage

---

# 6.11 Traffic & Kondisi Jalan

## Fitur

* Kemacetan real-time
* Laporan pengguna
* Jalan ditutup
* Kecelakaan
* Banjir
* Jalan rusak

## Sumber Data

* Komunitas pengguna
* API traffic pihak ketiga

---

# 6.12 Sistem Komunitas

## Fitur

* Laporan jalan
* Laporan kemacetan
* Tambah lokasi baru
* Review tempat
* Rating jalan

---

# 6.13 Profil Pengguna

## Fitur

* Login Google
* Login email
* Pengaturan kendaraan
* Pengaturan mazhab
* Riwayat perjalanan
* Tempat favorit
* Sinkronisasi cloud

---

# 6.14 Keamanan

## Fitur

* Permission management
* Enkripsi data lokasi
* Session management
* Anti GPS spoofing

---

# 6.15 Mode Tampilan

## Tema

* Light mode
* Dark mode
* Auto night mode

## Navigasi

* Tampilan sederhana
* Tampilan detail
* Mode hemat baterai

---

# 7. Struktur Halaman Aplikasi

# 7.1 Splash Screen

* Logo aplikasi
* Loading sistem

# 7.2 Onboarding

* Penjelasan fitur
* Permission lokasi
* Permission notifikasi

# 7.3 Home

* Peta utama
* Search bar
* Tombol lokasi saya
* Tombol mulai navigasi

# 7.4 Search Page

* Input tujuan
* Riwayat pencarian
* Favorit lokasi

# 7.5 Route Preview

* Detail rute
* Jarak
* Estimasi waktu
* Status safar

# 7.6 Navigation Page

* Peta fullscreen
* Panah navigasi
* Instruksi belok
* ETA
* Progress route
* Waktu salat berikutnya

# 7.7 Prayer Travel Assistant

* Status qasar
* Status jamak
* Jadwal salat
* Masjid terdekat

# 7.8 Settings

* Pengaturan suara
* Pengaturan mazhab
* Download offline map
* Tema aplikasi

# 7.9 Profile

* Informasi pengguna
* Riwayat perjalanan
* Statistik penggunaan

---

# 8. User Flow

## Flow Navigasi

1. User membuka aplikasi
2. GPS aktif
3. User mencari tujuan
4. Sistem menghitung rute
5. Sistem menampilkan estimasi perjalanan
6. User mulai navigasi
7. Voice navigation berjalan
8. Sistem memberikan info safar dan waktu salat
9. User tiba di tujuan

---

# 9. Non Functional Requirements

## Performance

* Startup < 3 detik
* Update GPS real-time
* FPS stabil saat navigasi

## Reliability

* Crash rate rendah
* Recovery koneksi otomatis

## Security

* HTTPS API
* Enkripsi data sensitif

## Scalability

* Support ribuan pengguna
* Support cloud scaling

---

# 10. Integrasi API

## Navigasi

* OSRM
* GraphHopper
* Valhalla

## Peta

* OpenStreetMap
* MapLibre

## Cuaca (Opsional)

* OpenWeather API

## Waktu Salat

* Aladhan API

---

# 11. MVP (Minimum Viable Product)

## Target MVP v1

### Fitur Wajib

* Peta interaktif
* GPS tracking
* Cari lokasi
* Routing sederhana
* Panah navigasi
* Voice navigation sederhana
* Status safar
* Informasi qasar/jamak
* Waktu salat
* Masjid terdekat

## Yang Belum Masuk MVP

* Traffic real-time
* Offline map penuh
* Komunitas pengguna
* AI recommendation
* Sinkronisasi cloud kompleks

---

# 12. Roadmap Pengembangan

# Phase 1

## Foundation

* Flutter setup
* Map integration
* GPS integration
* Basic routing

# Phase 2

## Navigation

* Voice navigation
* Re-routing
* Camera follow

# Phase 3

## Islamic Features

* Safar system
* Prayer notification
* Mosque finder

# Phase 4

## Advanced

* Offline map
* Traffic
* Community report

# Phase 5

## Scale

* Cloud infrastructure
* User synchronization
* Analytics

---

# 13. Potensi Monetisasi

## Gratis

* Navigasi dasar
* Waktu salat
* Safar information

## Premium

* Offline map lengkap
* Voice pack premium
* Traffic premium
* Cloud sync
* Advanced travel analytics

---

# 14. Risiko Pengembangan

## Risiko Teknis

* Konsumsi baterai tinggi
* Akurasi GPS
* Kompleksitas routing
* Traffic data mahal

## Risiko Operasional

* Server map besar
* Penyimpanan tile map
* Biaya bandwidth

---

# 15. Kesimpulan

Aplikasi ini berpotensi menjadi platform navigasi muslim modern dengan kombinasi:

* navigasi real-time
* perjalanan pintar
* dukungan ibadah
* komunitas pengguna

Dengan pengembangan bertahap menggunakan Flutter dan teknologi open source, aplikasi dapat dimulai dari MVP sederhana lalu berkembang menjadi platform navigasi lengkap.
