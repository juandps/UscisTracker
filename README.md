# Immigro USCIS Tracker

Personal USCIS case command center built with Flutter.

## Current App

- Local-first case tracking with `SharedPreferences` persistence.
- Add, search, sort, refresh, and delete USCIS receipt records.
- Case detail view with status, official USCIS link, timeline, checklist, and notes.
- Global history and task views.
- Safe status-refresh hook through `CASE_STATUS_API_BASE_URL`.

## Run Locally

```sh
flutter pub get
flutter run -d chrome
```

For a production-style web build:

```sh
flutter build web
python3 -m http.server 8080 --bind 127.0.0.1 --directory build/web
```

## Live Status Refresh

Do not ship USCIS API credentials in the Flutter client, especially on web. Build a small private backend proxy that owns the USCIS developer credentials, then run the app with:

```sh
flutter run -d chrome --dart-define=CASE_STATUS_API_BASE_URL=https://your-proxy.example.com
```

The app expects the proxy to expose:

```text
GET /case-status/{receiptNumber}
```

It accepts flexible JSON keys such as `statusTitle`, `statusDescription`, `stage`, `statusDate`, and `nextStep`.

## iOS / Xcode Cloud

- Public app name: `Immigro`
- Bundle identifier: `com.juandps.immigro`
- Apple team: `V72M69Q7Y2`
- Workspace: `ios/Runner.xcworkspace`
- Scheme: `Runner`
- Archive configuration: `Release`

Xcode Cloud needs Flutter available before it runs `xcodebuild`. The repo includes `ios/ci_scripts/ci_post_clone.sh`, which installs Flutter, runs `flutter pub get`, pre-caches iOS artifacts, and runs `pod install`.

Recommended first workflow:

1. Create or select the App Store Connect app record for bundle id `com.juandps.immigro`.
2. In Xcode Cloud, connect `juandps/UscisTracker`, choose `ios/Runner.xcworkspace`, then select the shared `Runner` scheme.
3. Add an Archive action for iOS using Release configuration and automatic signing.
4. Add TestFlight distribution as the post-action once the first archive succeeds.

Optional Xcode Cloud environment variable:

```text
FLUTTER_VERSION=stable
```

Set it to a specific Flutter tag later if you want fully pinned cloud builds.
