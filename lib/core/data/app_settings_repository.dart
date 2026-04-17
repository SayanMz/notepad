import 'package:flutter/material.dart';
import 'package:notepad/core/data/app_data.dart';
import 'package:notepad/core/services/storage_service.dart';

/// In-memory settings store that keeps UI state and disk state aligned.
class AppSettingsRepository extends ChangeNotifier {
  AppSettings _settings = const AppSettings();

  /// Exposes the current settings snapshot as read-only state.
  AppSettings get settings => _settings;

  /// Loads saved settings when the app starts.
  Future<void> load() async {
    _settings = StorageService.loadSettings();
  }

  /// Writes the current settings snapshot to local storage.
  Future<void> persist() => StorageService.saveSettings(_settings);

  /// Replaces the current settings and notifies listeners.
  Future<void> update(AppSettings newSettings) async {
    _settings = newSettings;
    await persist();
    notifyListeners();
  }
}

/// Shared instance used by the app root and settings UI.
final AppSettingsRepository appSettingsRepository = AppSettingsRepository();
