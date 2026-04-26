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

                    return _SwipeableRestoreItem(
                      note: note,
                      isDark: isDark,
                      onShowActionSheet: _showNoteActionSheet,
                      onRestore: (restoredNote) {
                        final restoredTitle = restoredNote.title.isEmpty
                            ? 'Untitled note'
                            : restoredNote.title;

                        noteRepository.restoreNote(restoredNote.id);
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
                    );
                  },
                ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// SWIPEABLE RESTORE ITEM (The RTL Physics Engine)
/// ---------------------------------------------------------------------------
class _SwipeableRestoreItem extends StatefulWidget {
  const _SwipeableRestoreItem({
    required this.note,
    required this.isDark,
    required this.onRestore,
    required this.onShowActionSheet,
  });

  final NotesSection note;
  final bool isDark;
  final void Function(NotesSection) onRestore;
  final void Function(BuildContext, NotesSection) onShowActionSheet;

  @override
  State<_SwipeableRestoreItem> createState() => _SwipeableRestoreItemState();
}

class _SwipeableRestoreItemState extends State<_SwipeableRestoreItem> {
  // ISOLATED STATE: Tracks the thumb!
  final ValueNotifier<double> _dragProgress = ValueNotifier<double>(0.0);

  @override
  void dispose() {
    _dragProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.recycleCardMargin),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // --- THE PERMANENT GREEN BACKGROUND ---
              Positioned(
                top: 0.5,
                bottom: 0.5,
                right: 0.5, // Tucked to avoid right-side bleed
                left: 16, // Flat gap on the left
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  color: widget.isDark
                      ? Colors.green.withValues(alpha: 0.2)
                      : const Color(0xFFC8E6C9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(
                        UIConstants.recycleCardRadius - 1.0,
                      ),
                      left: Radius.zero, // Razor flat left edge
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.centerRight,
                    // The icon's resting place
                    padding: const EdgeInsets.only(
                      right: UIConstants.paddingLG,
                    ),

                    // --- THE ANIMATION BUILDER ---
                    child: ValueListenableBuilder<double>(
                      valueListenable: _dragProgress,
                      builder: (context, progress, child) {
                        final draggedPixels = progress * cardWidth;
                        const iconWidth = UIConstants.recycleIconSize;
                        const targetPadding = UIConstants.paddingLG;

                        // 1. RTL Center-Gap Slide Algorithm
                        const lockPoint = (targetPadding * 2) + iconWidth;

                        double xOffset = (lockPoint / 2) - (draggedPixels / 2);
                        xOffset = xOffset.clamp(0.0, double.infinity);

                        final scale = (draggedPixels / lockPoint).clamp(
                          0.5,
                          1.0,
                        );
                        final opacity = (draggedPixels / lockPoint).clamp(
                          0.0,
                          1.0,
                        );

                        // 2. THE WHEEL PHYSICS (Clamped Rotation)
                        // Tracks exactly when the icon hits the 60px lockPoint, capping at 1.0.
                        final rotationProgress = (draggedPixels / lockPoint)
                            .clamp(0.0, 2.0);

                        // Rotates exactly 180 degrees (-3.14 radians) and stops dead.
                        // If you want a smaller rotation, change -3.14 to -1.57 (90 degrees).
                        final angle = rotationProgress * -3.14;

                        return Transform.translate(
                          offset: Offset(xOffset, 0),
                          child: Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: Transform.rotate(
                                angle: angle,
                                child: Icon(
                                  Icons.restore,
                                  color: widget.isDark
                                      ? Colors.greenAccent
                                      : const Color(0xFF2E7D32),
                                  size: UIConstants.recycleIconSize,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // --- THE SWIPE MASK ---
              Dismissible(
                key: ValueKey('restore_${widget.note.id}'),
                // Right-to-Left swipe!
                direction: DismissDirection.endToStart,
                background: const ColoredBox(color: Colors.transparent),

                // THE SENSOR
                onUpdate: (details) {
                  if (!mounted) return;
                  _dragProgress.value = details.progress;
                },

                onDismissed: (_) => widget.onRestore(widget.note),
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: UIConstants.elevationLow,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      UIConstants.recycleCardRadius,
                    ),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        UIConstants.recycleCardRadius,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(
                      UIConstants.recycleCardPadding,
                    ),
                    title: Text(
                      widget.note.title.isEmpty
                          ? 'Untitled note'
                          : widget.note.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      widget.note.content.isEmpty
                          ? 'No additional text'
                          : widget.note.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    trailing: IconButton(
                      onPressed: () =>
                          widget.onShowActionSheet(context, widget.note),
                      icon: const Icon(Icons.more_vert),
                    ),
                    onLongPress: HapticFeedback.mediumImpact,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
