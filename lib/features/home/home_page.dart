import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notepad/core/constants/ui_constants.dart';
import 'package:notepad/core/services/google_drive_service.dart';
import 'package:notepad/core/theme/app_colors.dart';
import 'package:notepad/features/home/controllers/home_controller.dart';
import 'package:notepad/features/home/widgets/spinning_sync_icon.dart';
import 'package:notepad/features/home/widgets/storage_progress_bar.dart';
import 'package:notepad/features/note/data/note_repository.dart';
import 'package:notepad/features/note/services/note_recovery_service.dart';
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
  double _storageProgress = 0.0;
  var user = googleDriveService.currentUser;
  String _storageText = 'Sync and protect your data';

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
  late final HomeController _controller;

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
    _controller = HomeController(_recoveryService);
    if (user != null) {
      _updateStorageStats();
    }

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
    _controller.toggleSelectionMode(enabled);
    // if (!enabled) {
    //   noteRepository.clearSelection();
    // }
  }

  /// Shares selected notes as HTML.
  ///
  /// UX:
  /// - Shows loading indicator via ValueNotifier
  /// - Handles errors gracefully
  Future<void> _shareSelectedNotesAsHTML() async {
    _isSavingNotifier.value = true;

    await _controller.shareSelectedNotes(context);

    if (mounted) {
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

    if (shouldDelete != true || !mounted) return;

    _setSelectionMode(false);

    await _controller.deleteSelected(selectedNotes);
  }

  Future<void> _updateStorageStats() async {
    final stats = await googleDriveService.getDetailedStorageUsage();
    if (mounted) {
      setState(() {
        // This fills your blue progress bar
        _storageProgress = stats['percent'];
        // This fills your text label
        _storageText = stats['text'];
      });
    }
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
    user = googleDriveService.currentUser;

    return PopScope(
      /// Prevents exit through system back navigation during selection mode for 1st time
      canPop: !isSelectionMode,

      /// Back button exits selection mode instead of leaving page
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isSelectionMode) {
          _setSelectionMode(false);
        }
      },

      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkScaffold
            : AppColors.lightScaffold,

        /// AppBar is isolated widget (better performance)
        appBar: HomeAppBar(
          isDark: isDark,
          isSavingNotifier: _isSavingNotifier,
          fadeRoute: AppRouter.fade,
        ),

        endDrawer: Container(
          margin: EdgeInsets.only(top: 90),
          child: Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.50,
              width: MediaQuery.of(context).size.width * 0.50, // Standard width
              child: Drawer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(UIConstants.paddingLG),
                      color: !isDark
                          ? Theme.of(context).colorScheme.primaryContainer
                          : AppColors.darkScaffold,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            //User profile picture
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.brown,
                                  backgroundImage:
                                      (user?.photoUrl != null &&
                                          user!.photoUrl!.isNotEmpty)
                                      ? NetworkImage(user!.photoUrl!)
                                      : null,
                                  child:
                                      (user?.photoUrl == null ||
                                          user!.photoUrl!.isEmpty)
                                      ? Text(
                                          user?.displayName?[0].toUpperCase() ??
                                              'User',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: UIConstants.paddingSM),
                                //User name
                                FittedBox(
                                  child: Text(
                                    (user == null)
                                        ? 'Sign in'
                                        : user?.displayName?.toUpperCase() ??
                                              'User',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: UIConstants.paddingXS),
                                //Storage space in text
                                Text(
                                  (user == null)
                                      ? 'Sync and protect your data'
                                      : _storageText,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),

                                //Storage space in %
                                ///Hide this if the user hasn't logged in yet.
                                ValueListenableBuilder(
                                  valueListenable: _isSavingNotifier,
                                  builder: (context, isSaving, child) {
                                    return Container(
                                      width: 170,
                                      height: 30,
                                      margin: EdgeInsets.only(top: 10),
                                      child: !isSaving
                                          ? StorageProgressBar(
                                              progress: 0.45,
                                              //_storageProgress, // Fills 45% of the bar
                                              color: Colors
                                                  .lightBlueAccent, // You can customize the color here
                                            )
                                          : const SpinningSyncIcon(),
                                    );
                                  },
                                ),
                                const SizedBox(height: UIConstants.paddingXS),
                              ],
                            ),
                          ), // Prep for Firebase
                        ],
                      ),
                    ),
                    const SizedBox(height: UIConstants.paddingSM),
                    ListTile(
                      leading: const Icon(Icons.backup),
                      title: const Text('Backup to Cloud'),
                      onTap: () async {
                        // Navigator.pop(context); // Close drawer
                        _isSavingNotifier.value = true; // Show top progress bar

                        try {
                          final success = await googleDriveService.signIn();
                          if (success) {
                            setState(() {});
                            final backupString = await noteRepository
                                .exportNotesToBackupString();
                            await googleDriveService.uploadBackup(backupString);
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   const SnackBar(
                            //     content: Text('Backup successful!'),
                            //   ),
                            // );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sign-in cancelled or failed.'),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint("CLOUD ERROR: $e");
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        } finally {
                          _isSavingNotifier.value = false;
                          _updateStorageStats();
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('Restore from Cloud'),
                      onTap: () async {
                        // Navigator.pop(context);
                        _isSavingNotifier.value = true;

                        try {
                          final success = await googleDriveService.signIn();
                          if (success) {
                            final jsonContent = await googleDriveService
                                .downloadBackup();
                            if (jsonContent != null) {
                              await noteRepository.importNotesFromBackupString(
                                jsonContent,
                              );

                              // ADD THIS SNACKBAR:
                              if (context.mounted) {
                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   const SnackBar(
                                //     content: Text(
                                //       'Restore successful! Notes updated.',
                                //     ),
                                //   ),
                                // );
                              }
                            } else {
                              // Handle case where no backup exists
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No backup found in the cloud.',
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        } catch (e) {
                          debugPrint("RESTORE ERROR: $e");
                        } finally {
                          _isSavingNotifier.value = false;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// Main content delegated to NoteList
        body: NoteList(
          scrollController: _scrollController,
          isSelectionMode: isSelectionMode,
          isSavingNotifier: _isSavingNotifier,
          onOpenNote: (noteId) => _controller.openNote(context, noteId: noteId),
          onTogglePin: (noteId) => _controller.togglePin(noteId),
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
      ),
    );
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
