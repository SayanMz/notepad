import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notepad/core/constants/ui_constants.dart';
import 'package:notepad/core/theme/app_colors.dart';
import 'package:notepad/features/note/data/note_repository.dart';
import 'package:notepad/features/note/services/note_document_service.dart';
import 'package:notepad/features/note/services/note_recovery_service.dart';
import 'package:notepad/main.dart';
import 'package:notepad/features/home/services/app_router.dart';
import 'package:notepad/features/home/widgets/home_app_bar.dart';
import 'package:notepad/features/home/widgets/note_list.dart';
import 'package:notepad/features/note/note_page.dart';
import 'package:animations/animations.dart';

/// ---------------------------------------------------------------------------
/// HOME PAGE (ROOT DASHBOARD)
/// ---------------------------------------------------------------------------
///
/// ROLE IN ARCHITECTURE:
/// - Acts as the primary orchestration layer for the notes feature
/// - Coordinates between:
///     • UI (widgets)
///     • Data (repositories)
///     • Services (recovery, export, etc.)
///
/// RESPONSIBILITIES:
/// - Render note list via composition (NoteList)
/// - Handle selection mode lifecycle
/// - Trigger navigation flows
/// - Coordinate recovery + async operations
///
/// DESIGN PRINCIPLES USED:
/// - Separation of concerns (UI split into widgets)
/// - Repository-driven state (single source of truth)
/// - Minimal local state (only UI concerns)
///
/// INTERVIEW NOTE:
/// This is a “thin orchestration layer” — not a business logic container.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Internal state for HomePage.
///
/// Contains ONLY:
/// - UI-level state (selection mode)
/// - Async indicators
/// - Lifecycle hooks (init/dispose)
class _HomePageState extends State<HomePage> {
  /// Tracks whether selection mode is active.
  ///
  /// NOTE:
  /// This is derived from repository state, but kept locally for UI toggling.
  /// (Could be fully derived in future refactor)
  var isSelectionMode = noteRepository.selectedNotes.isNotEmpty;

  late ScrollController _scrollController;
  // bool _isFabVisible = true;
  final ValueNotifier<bool> _isFabVisible = ValueNotifier(true);

  /// Handles crash recovery and draft restoration.
  final NoteRecoveryService _recoveryService = NoteRecoveryService();

  /// Local snapshot used ONLY during recovery flow.
  ///
  final activeNotes = noteRepository.activeNotes;

  /// Controls async UI feedback (e.g., export/share loading indicator).
  ///
  /// DESIGN:
  /// - Lightweight alternative to full state management
  /// - Scoped to UI-only async operations
  final ValueNotifier<bool> _isSavingNotifier = ValueNotifier(false);

  /// -------------------------------------------------------------------------
  /// CRASH RECOVERY FLOW
  /// -------------------------------------------------------------------------
  ///
  /// Displays a dialog when unsaved draft data is detected.
  ///
  /// UX:
  /// - User can restore or discard changes
  /// - Ensures data safety after unexpected app termination
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
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (mounted) {
                Navigator.pop(context);

                /// Navigates to NotePage with recovered data
                await Navigator.push(
                  context,
                  AppRouter.slide(
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

  /// -------------------------------------------------------------------------
  /// LIFECYCLE: INIT
  /// -------------------------------------------------------------------------
  ///
  /// Checks for crash recovery data at startup.
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _recoveryService.checkAndRecoverCrashData(activeNotes).then((shadowData) {
      if (shadowData != null && mounted) {
        /// Removes temporary placeholder note before restoring
        if (activeNotes.isNotEmpty) activeNotes.removeLast();
        _handleInitialRecovery(shadowData);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_isFabVisible.value) _isFabVisible.value = false;
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_isFabVisible.value) _isFabVisible.value = true;
      }
    });
  }

  /// -------------------------------------------------------------------------
  /// LIFECYCLE: DISPOSE
  /// -------------------------------------------------------------------------
  ///
  /// Cleans up ValueNotifier to prevent memory leaks.
  @override
  void dispose() {
    _isSavingNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Toggles selection mode.
  ///
  /// SIDE EFFECT:
  /// - Clears repository selection when exiting mode
  void _setSelectionMode(bool enabled) {
    setState(() {
      isSelectionMode = enabled;
    });

    if (!enabled) {
      noteRepository.clearSelection();
    }
  }

  /// Opens NotePage with optional noteId.
  ///
  /// ALSO:
  /// - Clears any active SnackBars for clean UX
  Future<void> _openNote({String? noteId}) async {
    rootScaffoldMessengerKey.currentState?.clearSnackBars();

    await Navigator.push(context, AppRouter.slide(NotePage(noteId: noteId)));
  }

  /// Toggles pin state of a note.
  ///
  /// PERSISTENCE:
  /// - Immediately saves after mutation
  Future<void> _togglePin(String noteId) async {
    noteRepository.togglePin(noteId);
    await noteRepository.persist();
  }

  /// Shares selected notes as HTML.
  ///
  /// UX:
  /// - Shows loading indicator via ValueNotifier
  /// - Handles errors gracefully
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

  /// Handles bulk delete with confirmation + undo.
  ///
  /// UX PATTERN:
  /// - Confirmation dialog
  /// - Snackbar with restore option
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
        duration: UIConstants.saveIndicatorDuration,
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

    /// Ensures snackbar is dismissed after duration
    Timer(UIConstants.saveIndicatorDuration, () {
      messenger?.hideCurrentSnackBar();
    });
  }

  /// -------------------------------------------------------------------------
  /// BUILD METHOD
  /// -------------------------------------------------------------------------
  ///
  /// Composes UI using extracted widgets.
  ///
  /// DESIGN:
  /// - Thin UI layer
  /// - Delegates heavy UI to NoteList
  /// - AppBar isolated (no rebuild dependency)
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      /// Prevent back navigation during selection mode
      canPop: !isSelectionMode,

      /// Back button exits selection mode instead of leaving page
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isSelectionMode) {
          _setSelectionMode(false);
        }
      },

      child: Scaffold(
        backgroundColor: AppColors.lightScaffold,

        /// AppBar is isolated widget (better performance)
        appBar: HomeAppBar(
          isDark: isDark,
          isSavingNotifier: _isSavingNotifier,
          fadeRoute: AppRouter.fade,
        ),

        /// Main content delegated to NoteList
        body: NoteList(
          scrollController: _scrollController,
          isSelectionMode: isSelectionMode,
          isSavingNotifier: _isSavingNotifier,
          onOpenNote: (noteId) => _openNote(noteId: noteId),
          onTogglePin: _togglePin,
          onShare: _shareSelectedNotesAsHTML,
          onDeleteSelected: _confirmBulkDelete,
          onSelectionToggle: () {
            setState(() {
              isSelectionMode = !isSelectionMode;
            });
          },
        ),

        /// FAB hidden during selection mode
        floatingActionButton: isSelectionMode
            ? null
            : ValueListenableBuilder<bool>(
                valueListenable: _isFabVisible,
                builder: (context, isVisible, child) {
                  return AnimatedScale(
                    scale: isVisible ? 1.0 : 0.0,
                    duration: UIConstants.animationFast,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: UIConstants.paddingXS,
                      ),
                      child: OpenContainer(
                        transitionType: ContainerTransitionType.fade,
                        transitionDuration: UIConstants.animationExtraSlow,
                        openColor: Theme.of(context).scaffoldBackgroundColor,
                        closedColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        closedElevation: UIConstants.elevationHigh,
                        closedShape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(UIConstants.radiusLG),
                          ),
                        ),
                        // This builds the FAB in its "closed" state
                        closedBuilder: (context, openContainer) =>
                            FloatingActionButton.extended(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              onPressed: openContainer,
                              icon: const Icon(Icons.add),
                              label: const Text(
                                'New Note',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                        // This builds the page the FAB "grows" into
                        openBuilder: (context, _) => const NotePage(),
                      ),
                    ),
                  );
                },
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        /*
          OpenContainer(
        //   transitionType: 
        //   ContainerTransitionType.fade,
        //   openBuilder: (context, _) => const NotePage(), // Correct destination
        //   tappable: false,
        //   closedShape: const RoundedRectangleBorder(
        //     borderRadius: BorderRadius.all(Radius.circular(UIConstants.radiusLG)),
        //   ),
        //   closedElevation: 0,
        //   closedColor: Colors.transparent,
        //   transitionDuration: const Duration(milliseconds: 350),
          */

        // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  /// Utility: toggle selection for a specific note
  void toggleSelection(String noteId) {
    noteRepository.toggleSelected(noteId);
  }

  /// Utility: clear all selections
  void clearSelection() {
    noteRepository.clearSelection();
  }
}

/// ---------------------------------------------------------------------------
/// INTERVIEW NOTES
/// ---------------------------------------------------------------------------
///
/// Key talking points:
///
/// 1. Architecture:
///    - "I decomposed a large UI into smaller reusable widgets"
///    - "HomePage acts as an orchestration layer, not a logic container"
///
/// 2. State Management:
///    - "I rely on repository as single source of truth"
///    - "UI only holds transient state (selection mode, loading)"
///
/// 3. UX:
///    - Undo delete (Snackbar)
///    - Crash recovery system
///    - Selection mode with bulk actions
///
/// 4. Scalability:
///    - Centralized routing (AppRouter)
///    - Service layer separation
///
/// This level of explanation is strong for mid → senior Flutter interviews.
