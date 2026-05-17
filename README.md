# Resto Queue

Sistem Manajemen Antrian Pintar untuk restoran berbasis Flutter dengan notifikasi real-time via Firebase.

## Fitur

- **Customer**: ambil nomor, lihat posisi antrian real-time, estimasi waktu tunggu, notifikasi saat dekat giliran & saat dipanggil.
- **Operator**: dashboard antrian aktif, panggil berikutnya, tandai serving/done/skip, pilih loket aktif.
- **QR Hybrid**:
  - **QR statik di meja** (cetak sekali): tamu scan → langsung halaman ambil antrian dengan nomor meja sudah terisi.
  - **QR dinamis di tiket**: tampil di kartu tiket customer; operator bisa scan untuk validasi & langsung tandai serving/done.
- **Real-time**: Firestore streams untuk update instan di semua device.
- **Offline-friendly**: persistence Firestore aktif, app tetap jalan saat WiFi ngadat.

## Format QR

```
Statik (sticker meja):  restoqueue://take?meja=5
                        https://restoqueue.app/take?meja=5  (fallback kamera bawaan)

Dinamis (tiket):        restoqueue://ticket?id=<ticketId>
                        https://restoqueue.app/ticket?id=<ticketId>
```

Untuk fallback HTTPS yang asli (Android App Links / iOS Universal Links), kamu perlu hosting `assetlinks.json` & `apple-app-site-association` di domain `restoqueue.app`. Untuk MVP, custom scheme `restoqueue://` sudah cukup (asal tamu pakai scanner di dalam app, atau ada redirect dari halaman web `/take`).

## Arsitektur

```
Flutter (Customer / Operator)
    └─ Firebase Auth (opsional: anonymous untuk customer)
    └─ Cloud Firestore (queues, counters, settings)
    └─ Cloud Functions (trigger FCM saat status → called)
    └─ Firebase Cloud Messaging (push notification)
```

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Buat Firebase Project

1. Buka [console.firebase.google.com](https://console.firebase.google.com) → Create Project
2. Beri nama (misal: `resto-queue-prod`)
3. Aktifkan service: **Firestore Database**, **Authentication**, **Cloud Messaging**, **Cloud Functions** (perlu Blaze plan untuk Functions, tapi free-tier-nya cukup besar)

### 3. Konfigurasi Flutter ↔ Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Pilih project Firebase yang baru dibuat. Ini auto-generate `lib/firebase_options.dart`.
Setelah itu, edit `lib/main.dart`:

```dart
import 'firebase_options.dart';
// ...
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

Hapus `lib/firebase_options_placeholder.dart`.

### 4. Setup Firestore (rules, indexes, seed data)

```bash
cd firebase
firebase login
firebase use --add                              # pilih project yang sama
firebase deploy --only firestore:rules,firestore:indexes
```

Lalu seed data awal (2 loket + counter prefix "A"):

```bash
# Download service-account.json dari Firebase Console:
# Project Settings → Service Accounts → Generate new private key
# Simpan sebagai firebase/service-account.json
npm install firebase-admin
node seed.js
```

### 5. Deploy Cloud Function (untuk push notification)

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### 6. Run

```bash
flutter run
```

### 7. (Opsional) Mock Data untuk Testing UI

## Database — Cloud Firestore

App ini pakai **Cloud Firestore** sebagai database utama. Bukan SQL, bukan local DB — semua data tersimpan di cloud Firebase dan ter-sync real-time ke semua device. Saat offline, Flutter SDK auto-cache di device dan sync balik begitu online.

### Skema (3 collection)

```
queues/{ticketId}                     ← tiap tiket = 1 dokumen
  prefix:        string               "A"
  number:        int                  12
  status:        string               "waiting" | "called" | "serving" | "done" | "skipped"
  customerName:  string?              "Budi"
  tableNumber:   string?              "5"
  fcmToken:      string?              token FCM device customer
  counterId:     string?              "counter-1"
  createdAt:     timestamp
  calledAt:      timestamp?
  servedAt:      timestamp?
  doneAt:        timestamp?

counters/{counterId}                  ← loket fisik di restoran
  name:             string            "Loket 1"
  isActive:         bool              true
  currentNumber:    int               12
  servingTicketId:  string?

settings/{prefix}                     ← counter increment harian
  prefix:      string                 "A"
  lastNumber:  int                    12        ← di-increment saat takeTicket via transaksi
  date:        string                 "2026-05-14" ← auto-reset kalau hari berubah
```

## Roadmap

- [ ] Auth (anonymous customer + login operator)
- [x] QR code untuk ambil antrian dari meja
- [x] QR code di tiket untuk validasi cepat
- [ ] Display screen mode (TV di restoran)
- [ ] Laporan harian (PDF/CSV)
- [ ] Multi-cabang
```
