# Nada — pemutar musik lokal

Aplikasi Flutter Android untuk memutar musik lokal secara offline tanpa iklan.

## Menjalankan aplikasi

1. Pasang Flutter dan Android SDK yang mendukung Dart SDK `^3.13.4`.
2. Jalankan `flutter pub get`.
3. Jalankan `flutter run` pada perangkat Android.
4. Izinkan akses **Musik dan audio** ketika diminta. Android 13+ memakai
   `READ_MEDIA_AUDIO`; Android 12L dan versi sebelumnya memakai izin
   `READ_EXTERNAL_STORAGE`.

Pemindai memakai MediaStore melalui `on_audio_query`. Karena itu, kartu SD
akan ikut dipindai jika media audionya diindeks Android dan tersedia bagi
MediaStore. Format yang dimasukkan ke library adalah MP3, M4A, dan FLAC.

## Fitur

- Library lagu, album, artis, dan folder; pencarian judul/artis.
- Pemutaran lokal dengan seek, next/previous, shuffle, repeat one/all.
- Pemutaran latar, notifikasi media, dan kontrol lockscreen Android.
- Favorit serta playlist buatan pengguna yang disimpan di SharedPreferences.
- Mini player persisten dan layar Now Playing dengan artwork beranimasi.
- Status izin, kondisi tanpa lagu, dan kesalahan pemindaian ditampilkan di UI.

## Struktur kode

```text
lib/
  main.dart
  models/track.dart
  providers/music_provider.dart
  services/audio_player_handler.dart
  screens/
    main_screen.dart
    now_playing_screen.dart
    playlist_detail_screen.dart
  widgets/
    album_art.dart
    mini_player.dart
    track_tile.dart
```

Konfigurasi izin media serta foreground media playback berada di
`android/app/src/main/AndroidManifest.xml`. Untuk membangun rilis, gunakan
keystore milik aplikasi, bukan signing konfigurasi debug yang dibuat template
Flutter.

`android/build.gradle.kts` mengisi namespace yang belum ditetapkan oleh modul
Android `on_audio_query` lama, agar tetap bisa dikonfigurasi oleh Android
Gradle Plugin versi baru dan menyamakan target JVM modul plugin Android di
Java 17. Modul scanner lama juga dikompilasi dengan API Android 36 karena
dependensi AndroidX-nya sudah mensyaratkan API 34 atau lebih baru.
