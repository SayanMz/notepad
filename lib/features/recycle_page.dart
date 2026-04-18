import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:notepad/core/constants/ui_constants.dart';
import 'package:notepad/core/data/app_data.dart';
import 'package:notepad/core/theme/app_colors.dart';
import 'package:notepad/features/note/data/note_repository.dart';
import 'package:notepad/main.dart';

class RecyclePage extends StatefulWidget {
  const RecyclePage({super.key});

  @override
  State<RecyclePage> createState() => _RecyclePageState();
}

class _RecyclePageState extends State<RecyclePage> {
  /// LOGIC: Handles permanent, irreversible data deletion.
  Future<void> _confirmDeleteForever(NotesSection note) async {
    final navigator = Navigator.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete forever?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    // ARCHITECTURE NOTE: Reactive State.
    // Calling deleteForever triggers notifyListeners()
    // inside the repository, which automatically commands the ListenableBuilder to redraw.
    noteRepository.deleteForever(note.id);

    if (!mounted) return;
    navigator.pop();
  }

  /// UI: Bottom sheet for secondary actions.
  void _showNoteActionSheet(BuildContext context, NotesSection note) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(UIConstants.recycleSheetRadius),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: UIConstants.paddingSM),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete forever'),
              onTap: () => _confirmDeleteForever(note),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ARCHITECTURE NOTE: Reactive UI
    // The screen is "glued" to the repository. Any changes to data instantly reflect here.
    return ListenableBuilder(
      listenable: noteRepository,
      builder: (context, child) {
        // Fetching the data inside the builder, makes sure it grabs the freshest state on every rebuild
        final deletedNotes = noteRepository.deletedNotes;

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkScaffold
              : AppColors.lightScaffold,
          appBar: AppBar(
            title: Text(
              'Recycle Bin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: deletedNotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/lotties/Ai_Robot.json',
                        height: UIConstants.recycleEmptyLottieHeight,
                      ),
                      const Text(
                        'Trash is empty',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: UIConstants.recycleEmptyTextFontSize,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(UIConstants.recycleListPadding),
                  itemCount: deletedNotes.length,
                  itemBuilder: (context, index) {
                    final note = deletedNotes[index];

                    return Dismissible(
                      key: ValueKey('restore_${note.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.all(
                          UIConstants.recycleCardMargin,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.green.withValues(alpha: 0.2)
                              : const Color(0xFFC8E6C9),
                          borderRadius: BorderRadius.circular(
                            UIConstants.recycleCardRadius,
                          ),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: UIConstants.paddingLG,
                        ),
                        child: Icon(
                          Icons.restore,
                          color: isDark
                              ? Colors.greenAccent
                              : Color(0xFF2E7D32),
                          size: UIConstants.recycleIconSize,
                        ),
                      ),
                      onDismissed: (direction) {
                        final restoredTitle = note.title.isEmpty
                            ? 'Untitled note'
                            : note.title;

                        // This mutates the data AND saves it directly to Hive
                        noteRepository.restoreNote(note.id);
                        if (!mounted) return;

                        showRootSnackBar(
                          SnackBar(
                            content: Text('$restoredTitle is now restored.'),
                            duration: UIConstants.saveIndicatorDuration,
                            behavior: SnackBarBehavior.floating,
                          ),
                          autoHideAfter: UIConstants.saveIndicatorDuration,
                        );
                      },
                      child: Card(
                        elevation: UIConstants.elevationLow,
                        margin: const EdgeInsets.all(
                          UIConstants.recycleCardMargin,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            UIConstants.recycleCardRadius,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(
                            UIConstants.recycleCardPadding,
                          ),
                          title: Text(
                            note.title.isEmpty ? 'Untitled note' : note.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            note.content.isEmpty
                                ? 'No additional text'
                                : note.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          trailing: IconButton(
                            onPressed: () =>
                                _showNoteActionSheet(context, note),
                            icon: const Icon(Icons.more_vert),
                          ),
                          onLongPress: HapticFeedback.mediumImpact,
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
