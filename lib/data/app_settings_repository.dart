import 'package:flutter/material.dart';
import 'package:notepad/data/app_data.dart';
import 'package:notepad/services/storage_service.dart';

class AppSettingsRepository extends ChangeNotifier {
  AppSettings _settings = const AppSettings();

  // Public getter to keep the internal state read-only
  AppSettings get settings => _settings;

  Future<void> load() async {
    _settings = await StorageService.loadSettings();
  }

  Future<void> persist() => StorageService.saveSettings(_settings);

  /// Updates user preferred settings and syncs to disk immediately
  Future<void> update(AppSettings newSettings) async {
    _settings = newSettings;
    await persist();
    notifyListeners();
  }
}

/// Global singleton instance for easy access across the app.
final AppSettingsRepository appSettingsRepository = AppSettingsRepository();
