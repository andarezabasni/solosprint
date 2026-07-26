# SoloSprint

Offline running tracker for Android. Tracks GPS routes, counts steps, helps you hit daily goals. No internet required.

## Features

- GPS Run Tracking (real-time distance, pace, duration, route map)
- Step Counter (runs in background, logs daily totals)
- StatMaps (route lines colored by pace: green/yellow/red)
- Weekly Summary (circular progress bars, swipe between weeks)
- Daily Goals (set step & distance targets, get notifications)
- Share Cards (export run as image: Classic, Photo, or Map template)
- Dark Mode
- English / Bahasa Indonesia
- Backup & Restore (export/import Hive files)

## Download

Download the APK from the [Releases page](https://github.com/andarezabasni/solosprint/releases).

## Build

```
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Tech Stack

- Flutter
- Provider
- Hive
- geolocator + flutter_map
- pedometer

## License

MIT
