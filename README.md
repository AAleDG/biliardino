# biliardino

Flutter app for tracking office table football matches.

## Features

- Manage players and office presence.
- Compose two-player teams.
- Track live scores and save match results.
- Browse match history.
- View leaderboard standings.

## Development

The verified toolchain is **Flutter 3.44.9 / Dart 3.12.2**. Use the existing
installed SDK through `flutter` on your PATH. Golden comparisons are exact and
can differ between SDK versions; verification results must record the version
used. Confirm the toolchain and resolve the locked dependencies:

```sh
flutter --version
flutter pub get --enforce-lockfile
```

Run tests and static analysis:

```sh
flutter test --no-pub
flutter analyze --no-pub
```

Build for the iOS simulator using the existing CocoaPods project:

```sh
FLUTTER_SWIFT_PACKAGE_MANAGER=false flutter build ios --simulator --debug --no-pub
```

The environment override applies only to that command and prevents automatic
Swift Package Manager migration; it does not change global Flutter settings.

## Database migrations

The schema version and ordered upgrade path live in
`lib/data/database_helper.dart`. To add a migration:

1. Increase `DatabaseHelper.databaseVersion` by one.
2. Add a strictly version-gated step to `migrateDatabase`; never rewrite or
   remove an older step because users can upgrade from any previous version.
3. Keep the step compatible with SQLite transactions. Throw when validation
   fails so sqflite rolls back the complete `onUpgrade` callback.
4. Update `_onCreate` to produce the same final schema as a fully migrated
   database.
5. Add a migration test that starts with a populated database at the oldest
   affected version and verifies both preserved data and the new constraints.
