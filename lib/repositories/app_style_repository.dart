import '../data/database_helper.dart';
import '../models/app_style.dart';

/// Local appearance setting, independent of player/match backups.
class AppStyleRepository {
  AppStyleRepository(this._database);

  static const storageKey = 'appearance.style';
  final DatabaseHelper _database;
  AppStyle _style = AppStyle.southAfrica2010;
  AppStyle get style => _style;

  Future<void> load() async {
    final values = await _database.getSettings([storageKey]);
    // Loading a future/unknown value must not overwrite the user's preference.
    _style = AppStyle.fromStorage(values[storageKey]);
  }

  Future<void> save(AppStyle style) async {
    await _database.setSettings({storageKey: style.storageValue});
    _style = style;
  }
}
