import 'package:hive/hive.dart';
import 'package:notepad/core/data/app_data.dart';

/// Thin persistence layer for App Settings.
/// (Notes persistence is handled directly by NoteRepository).
class StorageService {
  static const String _settingsBoxName = 'settings_box';

  static Box<AppSettings> get _settingsBox =>
      Hive.box<AppSettings>(_settingsBoxName);

  /// Loads the saved settings snapshot, or returns defaults when empty.
  static AppSettings loadSettings() {
    return _settingsBox.get('current_settings') ?? const AppSettings();
  }

  /// Persists the current settings snapshot.
  static Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put('current_settings', settings);
  }
}
