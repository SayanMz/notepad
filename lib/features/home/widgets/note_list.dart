import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:notepad/core/constants/ui_constants.dart';
import 'package:notepad/core/data/app_data.dart';
import 'package:notepad/features/note/data/note_repository.dart';
import 'package:notepad/main.dart';
import 'package:notepad/features/note/services/note_text_utils.dart';
import 'package:notepad/core/theme/app_colors.dart';

import 'selection_toolbar.dart';

/// ---------------------------------------------------------------------------
/// NOTE LIST
/// ---------------------------------------------------------------------------
///
/// RESPONSIBILITIES:
/// - Displays list of notes
/// - Handles selection mode UI
/// - Swipe-to-delete interaction
/// - Delegates actions via callbacks
///
/// DESIGN:
/// - Stateless (UI only)
/// - Reacts to repository via ListenableBuilder
/// - No business logic (delegated upward)
class NoteList extends StatelessWidget {
  const NoteList({
    super.key,
    required this.isSelectionMode,
    required this.isSavingNotifier,
    required this.onOpenNote,
    required this.onTogglePin,
    required this.onShare,
    required this.onDeleteSelected,
    required this.onSelectionToggle,
    required this.scrollController,
  });

  final bool isSelectionMode;
  final ValueNotifier<bool> isSavingNotifier;

  final Future<void> Function(String noteId) onOpenNote;
  final Future<void> Function(String noteId) onTogglePin;

  final VoidCallback onShare;
  final VoidCallback onDeleteSelected;

  final VoidCallback onSelectionToggle;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: noteRepository,
      builder: (_, _) {
        final activeNotes = noteRepository.activeNotes;
        final allSelected = noteRepository.areAllActiveNotesSelected;

        return activeNotes.isEmpty
            /// Builds list UI including:
            /// - Selection controls
            /// - Swipe-to-delete
            /// - Note cards
            ? _buildEmptyState()
            : Column(
                children: [
                  /// Selection toolbar
                  if (isSelectionMode)
                    SelectionToolbar(
                      isDark: isDark,
                      allSelected: allSelected,
                      onSelectAll: (value) {
                        noteRepository.setSelectAllForAllActiveNotes(value);
                      },
                      onShare: onShare,
                      onDelete: onDeleteSelected,
                    ),

                  /// Note list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: activeNotes.length,
                      padding: EdgeInsets.all(UIConstants.listPadding),
                      itemBuilder: (context, index) {
                        final note = activeNotes[index];

                        return Dismissible(
                          key: ValueKey('dismiss_${note.id}'),

                          /// Disable swipe in selection mode
                          direction: isSelectionMode
                              ? DismissDirection.none
                              : DismissDirection.startToEnd,

                          background: _buildDeleteBackground(isDark),

                          onDismissed: (_) async {
                            noteRepository.moveToRecycleBin(note.id);
                            _showUndoSnackbar(note);
                          },

                          child: _NoteCard(
                            note: note,
                            isSelectionMode: isSelectionMode,
                            isSavingNotifier: isSavingNotifier,
                            onTap: () async {
                              if (isSelectionMode) {
                                noteRepository.toggleSelected(note.id);
                                return;
                              }

                              noteRepository.moveOnTop(note);
                              await onOpenNote(note.id);
                            },
                            onLongPress: () {
                              HapticFeedback.selectionClick();
                              onSelectionToggle();
                              noteRepository.clearSelection();
                            },
                            onPin: () => onTogglePin(note.id),
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

  /// -------------------------------------------------------------------------
  /// EMPTY STATE: UI when no notes exist.
  /// -------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lotties/Ai_Robot.json',
            height: UIConstants.noteCardPreviewHeight,
            repeat: false,
            frameRate: FrameRate.max,
          ),
          const Text(
            'No notes yet',
            style: TextStyle(
              fontSize: UIConstants.noteCardPreviewTitleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: UIConstants.paddingSM),
          const Text(
            'Your thoughts belong here.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// DELETE BACKGROUND
  /// -------------------------------------------------------------------------
  Widget _buildDeleteBackground(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: UIConstants.cardVerticalMargin),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deleteDarkBg : AppColors.deleteLightBg,
        borderRadius: BorderRadius.circular(UIConstants.radiusMD),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.paddingLG),
      child: Icon(
        Icons.delete_outline,
        size: UIConstants.iconLG,
        color: isDark ? AppColors.deleteDarkIcon : AppColors.deleteLightIcon,
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// UNDO SNACKBAR: For single swipe delete.
  /// -------------------------------------------------------------------------
  void _showUndoSnackbar(NotesSection note) {
    showRootSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          '${note.title.isEmpty ? "Note" : note.title} moved to recycle bin',
        ),
        action: SnackBarAction(
          label: 'Restore',
          onPressed: () async {
            noteRepository.restoreNote(note.id);
          },
        ),
      ),
      autoHideAfter: UIConstants.saveIndicatorDuration,
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
    final screenWidth = MediaQuery.of(context).size.width;

    /// Responsive preview density:
    /// - Smaller screens → fewer lines
    /// - Larger screens → more content preview
    final maxPreviewLines = screenWidth > 1200
        ? UIConstants
              .noteCardPreviewLargeDesktopLines // Desktop/Large Tablet
        : screenWidth > 900
        ? UIConstants
              .noteCardPreviewTabletLines // Standard Tablet
        : screenWidth > 600
        ? UIConstants
              .noteCardPreviewSmallTabletLines // Small Tablet/Foldable
        : UIConstants.noteCardPreviewPhoneLines;

    /// Extracts formatted preview lines from rich/plain content.
    final previewLines = extractPreviewLines(
      note.content,
      maxLines: maxPreviewLines,
    );

    return Card(
      margin: EdgeInsets.symmetric(
        vertical: note.isSelected
            ? UIConstants.paddingMD
            : UIConstants.cardVerticalMargin,
        horizontal: note.isSelected
            ? UIConstants.paddingXXS
            : UIConstants.paddingSM,
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
          padding: EdgeInsets.all(
            note.isSelected ? UIConstants.paddingXLarge : UIConstants.paddingLG,
          ),
          decoration: BoxDecoration(
            color: note.isSelected
                ? colorScheme.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            border: note.isSelected
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.6),
                    width: UIConstants.selectionBorderWidth,
                  )
                : Border.all(
                    color: Colors.transparent,
                    width: UIConstants.selectionBorderWidth,
                  ),
            borderRadius: BorderRadius.circular(_cardRadius),
          ),
          child: Row(
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
                        fontSize: UIConstants.noteCardTitleFontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: UIConstants.paddingXS),

                    Text(
                      'Edited: ${_formatTimestamp(note.updatedAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: UIConstants.noteCardEditedFontSize,
                      ),
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
                    scale: note.isPinned ? UIConstants.pinnedScale : 1.0,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders a preview line of note content.
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
              padding: const EdgeInsets.only(
                right: UIConstants.noteCardBulletRightPadding,
                top: UIConstants.noteCardBulletTopPadding,
              ),
              child: Container(
                width: UIConstants.noteCardBulletSize,
                height: UIConstants.noteCardBulletSize,
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
                fontSize: UIConstants.noteCardPreviewFontSize,
                height: width < UIConstants.noteCardPreviewMaxWidthBreakpoint
                    ? UIConstants.noteCardPreviewLineHeightCompact
                    : UIConstants.noteCardPreviewLineHeightExpanded,
              ),
            ),
          ),
        ],
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
