import 'package:notepad/data/app_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteRecoveryService {
  static const String _prefix = 'shadow_';
  static const String draftKey = 'new_note';

  /// Logic: Saves the 'Dirty Draft' as a List [Title, Content]
  Future<void> saveShadowDraft(String noteId, List<String> draftData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_prefix$noteId', draftData);
  }

  /// Logic: Retrieves the draft List
  Future<List<String>?> getShadowDraft(String noteId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$_prefix$noteId');
  }

  /// Logic: Clears the draft completely
  Future<void> clearShadowDraft(String noteId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$noteId');
  }

  /// FIX: Changed return type to List<String>? to match your Home Page
  Future<List<String>?> checkAndRecoverCrashData(List<NotesSection> activeNotes) async {
    final idForRecovery = draftKey;
    
    // 1. Fetch the shadow draft list
    final shadowData = await getShadowDraft(idForRecovery);
    
    // 2. Early exit if there's nothing or it's malformed
    if (shadowData == null || shadowData.length < 2 || shadowData[1].trim().isEmpty) {
      return null; 
    }

    // 3. The Efficient Check: Checks if content (index 1) is already saved
    final shadowContentLower = shadowData[1].toLowerCase();
    final isAlreadySaved = activeNotes.any((note) {
      return note.content.toLowerCase().contains(shadowContentLower);
    });

    // 4. If not saved, return the List to trigger the UI dialog
    if (!isAlreadySaved) {
      return shadowData; 
    }

    // 5. If it WAS already saved, clean up the redundant draft
    await clearShadowDraft(idForRecovery);
    return null;
  }
}