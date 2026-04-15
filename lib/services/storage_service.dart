import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:notepad/data/app_data.dart';

/// A static utility class that handles reading from and writing to the device's physical storage.
class StorageService {
  
  // --- NOTES Section ---

  /// Helper function for compute: Must be static to be used in an isolate.
  static List<NotesSection> _parseNotesJson(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => NotesSection.fromJson(json)).toList();
  }

  /// Helper function for compute: Handles heavy JSON stringification in the background.
  static String _serializeNotes(List<NotesSection> notes) {
    // This works now because n.toJson() in app_data.dart has an optional parameter.
    return jsonEncode(notes.map((n) => n.toJson()).toList());
  }

  /// Helper method to locate the app's private folder on the device.
  static Future<File> _getLocalStorageFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  /// Saves the list of Note objects into a JSON string using a background isolate.
  static Future<void> saveNotes(List<NotesSection> notesList) async {
    debugPrint("Listener fired from storage_service saveNotes");
    final stopwatch = Stopwatch()..start();
    try {
      // Offload heavy CPU work to a separate isolate to keep UI smooth.
      final String jsonString = await compute(_serializeNotes, notesList);

      final file = await _getLocalStorageFile('notes_data.json');

      // Writing to disk is already asynchronous.
      await file.writeAsString(jsonString);
      
      debugPrint("Notes saved successfully using compute.");
    } catch (e) {
      debugPrint("Error during background save: $e");
    } 
    stopwatch.stop();
    debugPrint('💾 Full Persist Cycle: ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Reads the JSON file and converts it back into a List of NotesSection objects.
  static Future<List<NotesSection>> loadNotes() async {
    final stopwatch = Stopwatch()..start();
    try {
      final file = await _getLocalStorageFile('notes_data.json');
      
      if (!await file.exists()) return [];

      final String jsonString = await file.readAsString();
      
      // Use compute for decoding to prevent UI jank during app startup.
      return await compute(_parseNotesJson, jsonString);
    } catch (e) {
      debugPrint('Error loading notes: $e');
      return [];
    } finally {
      stopwatch.stop();
      print('📁 Isolate Disk Write & JSON: ${stopwatch.elapsedMilliseconds}ms');
    }
    
    
  }

  // --- SETTINGS Section ---
  
  /// Saves the user's preferences to a dedicated settings file.
  static Future<void> saveSettings(AppSettings settings) async {
    try {
      final file = await _getLocalStorageFile('settings_data.json');
      await file.writeAsString(jsonEncode(settings.toJson()));
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  /// Retrieves the saved AppSettings or returns default settings if none are found.
  static Future<AppSettings> loadSettings() async {
    try {
      final file = await _getLocalStorageFile('settings_data.json');
      
      if (!await file.exists()) {
        return const AppSettings();
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(jsonString);
      
      return AppSettings.fromJson(json);
    } catch (e) {
      debugPrint('Error loading settings: $e');
      return const AppSettings();
    }
  }
}