# SoloSprint 🏃

Offline running tracker for Android. Tracks GPS routes, counts steps, and helps you hit daily goals — no internet required.

## Features

- **GPS Run Tracking** — real-time distance, pace, duration, and route map (OpenStreetMap)
- **Step Counter** — runs in background, logs daily totals
- **StatMaps** — route lines colored by pace (green = fast, red = slow)
- **Weekly Summary** — circular progress bars, swipe between weeks
- **Daily Goals** — set step & distance targets, get notifications
- **Share Cards** — export your run as an image (Classic / Photo / Map template)
- **Dark Mode** — toggle in Settings
- **English / Indonesia** — pick your language
- **Backup & Restore** — export/import all data as Hive files

## Download

Grab the latest APK from the [Releases page](https://github.com/andarezabasni/solosprint/releases).

## Build

```bash
flutter build apk --release
```

APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Tech Stack

- Flutter
- Provider (state management)
- Hive (local storage)
- geolocator + flutter_map (GPS & maps)
- pedometer (step counter)

## Support

- Saweria — https://saweria.co/andreza09
- PayPal — https://www.paypal.com/paypalme/andreza110

## License

MIT
