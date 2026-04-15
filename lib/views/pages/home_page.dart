import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

import 'package:notepad/constants/ui_constants.dart';
import 'package:notepad/data/app_data.dart';
import 'package:notepad/data/app_settings_repository.dart';
import 'package:notepad/services/note_document_service.dart';
import 'package:notepad/services/note_recovery_service.dart';
import 'package:notepad/data/note_repository.dart';
import 'package:notepad/services/note_text_utils.dart';
import 'package:notepad/main.dart';
import 'package:notepad/views/pages/note_page.dart';
import 'package:notepad/views/pages/recycle_page.dart';
import 'package:notepad/views/pages/search_page.dart';

import 'package:animations/animations.dart';

/// Primary home screen responsible for:
/// - Rendering active notes
/// - Managing selection mode and bulk actions
/// - Coordinating navigation and recovery flows
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSelectionMode = noteRepository.selectedNotes.isNotEmpty;

  final NoteRecoveryService _recoveryService = NoteRecoveryService();

  /// Local snapshot of repository data.
  /// Always refreshed during build → not a persistent source of truth.
  List<NotesSection> activeNotes = noteRepository.activeNotes;

  /// Controls top progress indicator visibility during async operations.
  final ValueNotifier<bool> _isSavingNotifier = ValueNotifier(false);

  /// Unused state (likely leftover UI experiment).
  bool waitingBarAtTop = false;

  Future<void> _handleInitialRecovery(List<String> shadowData) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recover Unsaved Changes?'),
        content: const Text(
          'It looks like the app closed unexpectedly. Would you like to restore your last edit?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _recoveryService.clearShadowDraft('new_note');
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (mounted) {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  _slideRoute(
                    NotePage(title: shadowData[0], content: shadowData[1]),
                  ),
                );
              }
              await _recoveryService.clearShadowDraft('new_note');
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Attempt crash recovery at startup.
    _recoveryService.checkAndRecoverCrashData(activeNotes).then((shadowData) {
      if (shadowData != null && mounted) {
        // Assumes last note is a temporary placeholder.
        activeNotes.removeLast();
        _handleInitialRecovery(shadowData);
      }
    });
  }

  @override
  void dispose() {
    _isSavingNotifier.dispose();
    super.dispose();
  }

  void _setSelectionMode(bool enabled) {
    isSelectionMode = enabled;

    if (!enabled) noteRepository.clearSelection();
  }

  Future<void> _openNote({String? noteId}) async {
    rootScaffoldMessengerKey.currentState?.clearSnackBars();
    await Navigator.push(context, _slideRoute(NotePage(noteId: noteId)));
  }

  Future<void> _togglePin(String noteId) async {
    noteRepository.togglePin(noteId);
    await noteRepository.persist();
  }

  Future<void> _shareSelectedNotesAsHTML() async {
    _isSavingNotifier.value = true;

    final selectedNotes = noteRepository.selectedNotes;
    if (selectedNotes.isEmpty) {
      _isSavingNotifier.value = false;
      return;
    }

    try {
      await NoteDocumentService.shareNotesAsHTML(
        selectedNotes,
        text: 'Sharing ${selectedNotes.length} Notes',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share selected notes: $e')),
      );
    } finally {
      _isSavingNotifier.value = false;
    }
  }

  Future<void> _confirmBulkDelete() async {
    final selectedNotes = noteRepository.selectedNotes;
    if (selectedNotes.isEmpty) return;

    final selectedCount = selectedNotes.length;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move selected notes to recycle bin?'),
        content: Text(
          selectedCount == 1
              ? 'The selected note will be moved to the recycle bin.'
              : '$selectedCount notes will be moved to the recycle bin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Move'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final movedNoteIds = selectedNotes.map((n) => n.id).toList();

    final movedCount = noteRepository.moveSelectedNotesToRecycleBin();

    _setSelectionMode(false);
    await noteRepository.persist();

    final messenger = rootScaffoldMessengerKey.currentState;
    messenger?.clearSnackBars();

    messenger?.showSnackBar(
      SnackBar(
        key: UniqueKey(),
        duration: const Duration(seconds: 3),
        content: Text(
          '$movedCount ${movedCount == 1 ? 'note' : 'notes'} moved to recycle bin',
        ),
        action: SnackBarAction(
          label: 'Restore',
          onPressed: () async {
            messenger.hideCurrentSnackBar();
            for (final id in movedNoteIds) {
              noteRepository.restoreNote(id);
            }
            await noteRepository.persist();
          },
        ),
      ),
    );

    Timer(const Duration(seconds: 3), () {
      messenger?.hideCurrentSnackBar();
    });
  }

  Route _slideRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: UIConstants.animationSlow,
      reverseTransitionDuration: UIConstants.animationMedium,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;

        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: UIConstants.animationMedium,
      reverseTransitionDuration: UIConstants.animationFast,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      // Prevent back navigation while in selection mode
      canPop: !isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isSelectionMode) _setSelectionMode(false);
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF8F9FA),

        /// AppBar does NOT depend on noteRepository → no need to rebuild it
        appBar: _buildAppBar(isDark),

        /// Only this part reacts to repository changes
        body: ListenableBuilder(
          listenable: noteRepository,
          builder: (context, child) {
            activeNotes = noteRepository.activeNotes;
            final allSelected = noteRepository.areAllActiveNotesSelected;

            return activeNotes.isEmpty
                ? _buildEmptyState()
                : _buildNoteList(activeNotes, allSelected);
          },
        ),

        /// FAB is static → no dependency on repository
        floatingActionButton: OpenContainer(
          closedColor: Colors.transparent,
          closedElevation: 0,
          transitionType: ContainerTransitionType.fadeThrough,
          transitionDuration: UIConstants.animationSlow,
          openColor: Theme.of(context).scaffoldBackgroundColor,

          // Refresh UI after returning from NotePage
          onClosed: (_) {
            if (mounted) setState(() {});
          },

          openBuilder: (context, action) => const NotePage(),

          closedBuilder: (context, action) {
            return FloatingActionButton.extended(
              elevation: 4,
              onPressed: action,
              label: const Text('New Note'),
              icon: const Icon(Icons.add),
            );
          },
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  /// Builds AppBar with:
  /// - Theme toggle
  /// - Search navigation
  /// - Recycle bin access
  /// - Saving indicator
  PreferredSizeWidget _buildAppBar(bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      leading: IconButton(
        onPressed: () async {
          final currentIsDark = appSettingsRepository.settings.isDarkMode;

          // Toggles persisted theme setting → triggers Listenable rebuild
          await appSettingsRepository.update(
            appSettingsRepository.settings.copyWith(isDarkMode: !currentIsDark),
          );
        },
        icon: const Icon(Icons.light),
      ),
      title: const Text(
        'Notepad',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,

      // Top progress indicator driven by ValueNotifier
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: ValueListenableBuilder(
          valueListenable: _isSavingNotifier,
          builder: (_, isSaving, _) {
            if (!isSaving) return const SizedBox(height: 2);
            return LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            );
          },
        ),
      ),

      actions: [
        IconButton(
          icon: Icon(
            Icons.search,
            size: UIConstants.iconMD,
            color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
          ),
          onPressed: () async {
            await noteRepository.persist();
            if (!mounted) return;
            rootScaffoldMessengerKey.currentState?.clearSnackBars();
            await Navigator.push(context, _fadeRoute(const SearchPage()));
          },
        ),
        IconButton(
          icon: Icon(
            Icons.restore_from_trash,
            size: UIConstants.iconMD,
            color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
          ),
          onPressed: () async {
            await noteRepository.persist();
            if (!mounted) return;
            rootScaffoldMessengerKey.currentState?.clearSnackBars();
            await Navigator.push(context, _fadeRoute(const RecyclePage()));
          },
        ),
      ],
    );
  }

  /// Empty state UI when no notes exist.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/lotties/Ai_Robot.json', height: 250.0),
          const Text(
            'No notes yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your thoughts belong here.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Shows undo snackbar for single swipe delete.
  void _showSingleUndoSnackbar(String noteId) {
    final messenger = rootScaffoldMessengerKey.currentState;
    messenger?.clearSnackBars();

    final note = noteRepository.findById(noteId);

    messenger?.showSnackBar(
      SnackBar(
        key: UniqueKey(),
        duration: const Duration(seconds: 3),
        content: Text('${note?.title ?? "Note"} moved to recycle bin'),
        action: SnackBarAction(
          label: 'Restore',
          onPressed: () async {
            messenger.hideCurrentSnackBar();
            noteRepository.restoreNote(noteId);
            await noteRepository.persist();
          },
        ),
      ),
    );

    Timer(const Duration(seconds: 3), () {
      messenger?.hideCurrentSnackBar();
    });
  }

  /// Builds list UI including:
  /// - Selection controls
  /// - Swipe-to-delete
  /// - Note cards
  Widget _buildNoteList(List<NotesSection> activeNotes, bool allSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: noteRepository,
      builder: (_, _) {
        return Column(
          children: [
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.all(UIConstants.paddingSM),
                child: Row(
                  children: [
                    Checkbox(
                      side: BorderSide(
                        color: isDark
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                        width: 2,
                      ),
                      value: allSelected,
                      onChanged: (value) => noteRepository
                          .setSelectAllForAllActiveNotes(value ?? false),
                    ),
                    const Text('Select All'),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.share,
                        size: UIConstants.iconMD,
                        color: isDark
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                      ),
                      onPressed: _shareSelectedNotesAsHTML,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        size: UIConstants.iconMD,
                        color: isDark
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                      ),
                      onPressed: _confirmBulkDelete,
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView.builder(
                itemCount: activeNotes.length,
                padding: EdgeInsets.all(UIConstants.listPadding),
                itemBuilder: (context, index) {
                  final note = activeNotes[index];

                  return Dismissible(
                    key: ValueKey('dismiss_${note.id}'),

                    // Disabled while selecting to prevent accidental deletes
                    direction: isSelectionMode
                        ? DismissDirection.none
                        : DismissDirection.startToEnd,

                    background: Container(
                      margin: EdgeInsets.symmetric(
                        vertical: UIConstants.cardVerticalMargin,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color.fromARGB(255, 102, 44, 44)
                            : const Color.fromARGB(255, 236, 105, 105),
                        borderRadius: BorderRadius.circular(
                          UIConstants.radiusMD,
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.paddingLG,
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: UIConstants.iconLG,
                        color: isDark
                            ? const Color(0xFFFF5252)
                            : const Color.fromARGB(255, 196, 44, 44),
                      ),
                    ),

                    onDismissed: (_) async {
                      noteRepository.clearSelection();
                      noteRepository.setSelected(note.id, true);
                      noteRepository.moveSelectedNotesToRecycleBin();
                      await noteRepository.persist();

                      setState(() {});
                      _showSingleUndoSnackbar(note.id);
                    },

                    child: _NoteCard(
                      note: note,
                      isSelectionMode: isSelectionMode,
                      isSavingNotifier: _isSavingNotifier,
                      onTap: () async {
                        if (isSelectionMode) {
                          noteRepository.toggleSelected(note.id);
                          return;
                        }
                        noteRepository.moveOnTop(note);
                        await _openNote(noteId: note.id);
                      },
                      onLongPress: () {
                        HapticFeedback.selectionClick();
                        isSelectionMode = !isSelectionMode;
                        noteRepository.clearSelection();
                      },
                      onPin: () => _togglePin(note.id),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Stateless UI component representing a single note item.
///
/// RESPONSIBILITIES:
/// - Displays note metadata (title, timestamp, preview)
/// - Handles selection state visuals
/// - Exposes interaction callbacks (tap, long press, pin, export)
///
/// DESIGN:
/// - Pure UI component (no direct repository mutation)
/// - All side effects delegated via callbacks
class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onPin,
    required this.isSavingNotifier,
  });

  final NotesSection note;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onPin;

  /// Shared notifier to indicate export/save progress.
  final ValueNotifier<bool> isSavingNotifier;

  static const double _cardRadius = UIConstants.radiusMD;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    /// Responsive preview density:
    /// - Smaller screens → fewer lines
    /// - Larger screens → more content preview
    final maxPreviewLines = screenWidth > 1200
        ? 12 // Desktop/Large Tablet
        : screenWidth > 900
        ? 8 // Standard Tablet
        : screenWidth > 600
        ? 5 // Small Tablet/Foldable
        : 2;

    /// Extracts formatted preview lines from rich/plain content.
    final previewLines = extractPreviewLines(
      note.content,
      maxLines: maxPreviewLines,
    );

    return Card(
      margin: EdgeInsets.symmetric(
        vertical: note.isSelected ? 12 : UIConstants.cardVerticalMargin,
        horizontal: note.isSelected ? 4 : 8, // Makes the card slightly wider
      ),
      elevation: note.isSelected ? 8 : UIConstants.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(_cardRadius),
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: UIConstants.animationMedium,
          padding: EdgeInsets.all(note.isSelected ? 20 : UIConstants.paddingLG),
          decoration: BoxDecoration(
            color: note.isSelected
                ? colorScheme.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            border: note.isSelected
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.6),
                    width: 2,
                  )
                : Border.all(color: Colors.transparent, width: 2),
            borderRadius: BorderRadius.circular(_cardRadius),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment
                  .stretch, // Stretches columns to full height
              children: [
                /// Selection indicator
                AnimatedSwitcher(
                  duration: UIConstants.animationFast,
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: isSelectionMode
                      ? Padding(
                          padding: const EdgeInsets.only(
                            right: UIConstants.paddingMD,
                          ),
                          child: Icon(
                            note.isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: note.isSelected
                                ? colorScheme.primary.withValues(alpha: 0.6)
                                : Colors.grey,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // LEFT SIDE: The content column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title.isEmpty ? 'Untitled note' : note.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: UIConstants.paddingXS),

                      Text(
                        'Edited: ${_formatTimestamp(note.updatedAt)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),

                      const SizedBox(height: UIConstants.paddingSM),

                      /// Preview lines loop
                      ...previewLines.map(
                        (line) => _PreviewLine(line: line, width: screenWidth),
                      ),
                    ],
                  ),
                ),

                // RIGHT SIDE: The action column
                Column(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween, // Uses SizedBox for precise gaps
                  children: [
                    /// Pin toggle
                    AnimatedScale(
                      scale: note.isPinned ? 1.2 : 1.0,
                      duration: UIConstants.animationFast,
                      child: IconButton(
                        icon: Icon(
                          note.isPinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          size: UIConstants.iconSM,
                          color: colorScheme.primary.withValues(alpha: 0.6),
                        ),
                        onPressed: onPin,
                      ),
                    ),

                    /// Export to PDF
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.picture_as_pdf,
                        size: UIConstants.iconSM,
                        color: isDark
                            ? Colors.white70
                            : colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () async {
                        isSavingNotifier.value = true;
                        try {
                          final List<dynamic> richData =
                              note.richContent.isNotEmpty
                              ? jsonDecode(note.richContent)
                              : NoteDocumentService.decodeRichContent(
                                  '',
                                  note.content,
                                );
                          await NoteDocumentService.saveNoteAsPdf(
                            title: note.title,
                            richContent: richData,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: Duration(seconds: 2),
                              content: Text('Could not export PDF: $e'),
                            ),
                          );
                        } finally {
                          isSavingNotifier.value = false;
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Formats DateTime into user-readable string.
///
/// OUTPUT FORMAT:
/// Example → "Jan 12, 2026 • 3:45 PM"
///
/// DESIGN:
/// - Lightweight formatter (no intl dependency)
/// - Assumes local device time
String _formatTimestamp(DateTime value) {
  final month = _monthName(value.month);

  final hour = value.hour == 0
      ? 12
      : (value.hour > 12 ? value.hour - 12 : value.hour);

  final minute = value.minute.toString().padLeft(2, '0');
  final meridiem = value.hour >= 12 ? 'PM' : 'AM';

  return '$month ${value.day}, ${value.year} • $hour:$minute $meridiem';
}

/// Maps month index → abbreviated name.
///
/// NOTE:
/// - Assumes valid 1–12 input
/// - No bounds checking (caller responsibility)
String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

/// Renders a single preview line of note content.
///
/// RESPONSIBILITIES:
/// - Handles list-style formatting (bullet stripping)
/// - Applies responsive typography
/// - Ensures overflow safety

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.line, required this.width});
  final String line;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 1. ADVANCED DETECTION: Uses a RegExp to find markers even with hidden characters
    // Matches: •, -, *, 1. at the start of the line
    final listRegex = RegExp(r'^[\s]*([•\-\*\u2022]|\d+\.)[\s]*(.*)');
    final match = listRegex.firstMatch(line);
    
    final bool isListLine = match != null;
    
    // 2. DATA EXTRACTION: group(2) is the actual text content after the marker
    final String displayText = isListLine 
        ? (match.group(2) ?? '').trim() 
        : line.trim();

    // Safety: If the line is empty and not a list, don't render
    if (displayText.isEmpty && !isListLine) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.paddingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isListLine)
            Padding(
              // Align bullet to the vertical center of the first line
              padding: const EdgeInsets.only(right: 10.0, top: 7.0),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  // Using Primary color for the bullet to make it pop on the A55
                  color: colorScheme.primary.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Expanded(
            child: Text(
              displayText,
              // Responsive line logic for your BCA project
              maxLines: width > 600 ? 2 : 1, 
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                height: width < 600 ? 1.2 : 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}