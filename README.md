# biliardino

Flutter app for tracking office table football matches.

## Features

- Manage players and office presence.
- Compose two-player teams.
- Track live scores and save match results.
- Browse match history.
- View leaderboard standings.

## Development

Use the Flutter version installed at:

```sh
/Users/alessandroantonio.delgaudio/fvm/versions/3.44.1/bin/flutter
```

Run tests:

```sh
/Users/alessandroantonio.delgaudio/fvm/versions/3.44.1/bin/flutter test
```

Build for iOS simulator:

```sh
/Users/alessandroantonio.delgaudio/fvm/versions/3.44.1/bin/flutter build ios --simulator
```

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
