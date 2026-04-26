import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:notepad/core/constants/ui_constants.dart';
import 'package:notepad/core/data/app_data.dart';
import 'package:notepad/core/theme/app_colors.dart';
import 'package:notepad/features/note/data/note_repository.dart';
import 'package:notepad/main.dart';
import 'package:notepad/features/note/services/note_text_utils.dart';
//import 'package:flutter_slidable/flutter_slidable.dart';

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
            ? _buildEmptyState()
            : Column(
                children: [
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

                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: activeNotes.length,
                      padding: const EdgeInsets.all(UIConstants.listPadding),
                      itemBuilder: (context, index) {
                        final note = activeNotes[index];

                        return _SwipeableNoteItem(
                          note: note,
                          isDark: isDark,
                          isSelectionMode: isSelectionMode,
                          isSavingNotifier: isSavingNotifier,
                          onOpenNote: onOpenNote,
                          onSelectionToggle: onSelectionToggle,
                          onTogglePin: onTogglePin,
                          onDeleted: _showUndoSnackbar,
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
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: note.isSelected ? 8 : UIConstants.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusMD),
      ),
      child: InkWell(
        borderRadius: BorderRadius.zero,
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
            borderRadius: BorderRadius.circular(UIConstants.radiusMD),
            border: note.isSelected
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.6),
                    width: UIConstants.selectionBorderWidth,
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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

              // RIGHT SIDE: The Pin
              AnimatedScale(
                scale: note.isPinned ? UIConstants.pinnedScale : 1.0,
                duration: UIConstants.animationFast,
                child: IconButton(
                  icon: Icon(
                    note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: UIConstants.iconSM,
                    color: colorScheme.primary.withValues(alpha: 0.6),
                  ),
                  onPressed: onPin,
                ),
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

/// ---------------------------------------------------------------------------
/// SWIPEABLE NOTE ITEM (The Physics Engine)
/// ---------------------------------------------------------------------------
class _SwipeableNoteItem extends StatefulWidget {
  const _SwipeableNoteItem({
    required this.note,
    required this.isDark,
    required this.isSelectionMode,
    required this.isSavingNotifier,
    required this.onOpenNote,
    required this.onSelectionToggle,
    required this.onTogglePin,
    required this.onDeleted,
  });

  final NotesSection note;
  final bool isDark;
  final bool isSelectionMode;
  final ValueNotifier<bool> isSavingNotifier;
  final Future<void> Function(String) onOpenNote;
  final VoidCallback onSelectionToggle;
  final Future<void> Function(String) onTogglePin;
  final void Function(NotesSection) onDeleted;

  @override
  State<_SwipeableNoteItem> createState() => _SwipeableNoteItemState();
}

class _SwipeableNoteItemState extends State<_SwipeableNoteItem> {
  // 1. ISOLATED STATE: Tracks thumb drag percentage without rebuilding the card
  final ValueNotifier<double> _dragProgress = ValueNotifier<double>(0.0);

  @override
  void dispose() {
    _dragProgress.dispose(); // Prevent memory leaks when scrolling
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: widget.note.isSelected
            ? UIConstants.paddingMD
            : UIConstants.cardVerticalMargin,
        horizontal: widget.note.isSelected
            ? UIConstants.paddingXXS
            : UIConstants.paddingSM,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0.5,
                bottom: 0.5,
                left: 0.5,
                right: 16,
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: widget.isDark
                      ? AppColors.deleteDarkBg
                      : AppColors.deleteLightBg,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(UIConstants.radiusMD - 1.0),
                      right: Radius.zero,
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: UIConstants.paddingLG),

                    // 2. THE ANIMATION BUILDER: Listens to the thumb drag
                    child: ValueListenableBuilder<double>(
                      valueListenable: _dragProgress,
                      builder: (context, progress, child) {
                        final draggedPixels = progress * cardWidth;
                        const iconWidth = UIConstants.iconLG;
                        const targetPadding = UIConstants.paddingLG;

                        // PHASE 1: Center-Gap Slide
                        double xOffset = (draggedPixels / 2) - (iconWidth / 2);
                        xOffset = xOffset.clamp(
                          double.negativeInfinity,
                          targetPadding,
                        );

                        // The exact pixel mark where the icon locks into place
                        const lockPoint =
                            (targetPadding * 2) + iconWidth; // 60.0

                        final scale = (draggedPixels / lockPoint).clamp(
                          0.5,
                          1.0,
                        );
                        final opacity = (draggedPixels / lockPoint).clamp(
                          0.0,
                          1.0,
                        );

                        // PHASE 2: The Lid Pop
                        // Only starts opening AFTER draggedPixels passes the 60.0 lockPoint.
                        // Full open is reached 90 pixels after the lockPoint (150px total drag).
                        final lidProgress = ((draggedPixels - lockPoint) / 90.0)
                            .clamp(0.0, 1.0);

                        return Transform.translate(
                          offset: Offset(xOffset, 0),
                          child: Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              // Replace the static Icon with our new Custom Vector!
                              child: _AnimatedTrashIcon(
                                lidProgress: lidProgress,
                                color: widget.isDark
                                    ? AppColors.deleteDarkIcon
                                    : AppColors.deleteLightIcon,
                                size: UIConstants.iconLG,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Dismissible(
                key: ValueKey('dismiss_${widget.note.id}'),
                direction: widget.isSelectionMode
                    ? DismissDirection.none
                    : DismissDirection.startToEnd,
                background: const ColoredBox(color: Colors.transparent),

                // 3. THE SENSOR: Streams the exact decimal of your thumb position
                onUpdate: (details) {
                  if (!mounted) return;
                  _dragProgress.value = details.progress;
                },

                onDismissed: (_) {
                  noteRepository.moveToRecycleBin(widget.note.id);
                  widget.onDeleted(widget.note);
                },
                child: _NoteCard(
                  note: widget.note,
                  isSelectionMode: widget.isSelectionMode,
                  isSavingNotifier: widget.isSavingNotifier,
                  onTap: () async {
                    if (widget.isSelectionMode) {
                      noteRepository.toggleSelected(widget.note.id);
                      return;
                    }
                    noteRepository.moveOnTop(widget.note);
                    await widget.onOpenNote(widget.note.id);
                  },
                  onLongPress: () {
                    HapticFeedback.selectionClick();
                    widget.onSelectionToggle();
                    noteRepository.clearSelection();
                  },
                  onPin: () => widget.onTogglePin(widget.note.id),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// CUSTOM ANIMATED TRASH CAN (Pure Vertical Lift)
/// ---------------------------------------------------------------------------
class _AnimatedTrashIcon extends StatelessWidget {
  const _AnimatedTrashIcon({
    required this.lidProgress,
    required this.color,
    this.size = 28.0,
  });

  final double lidProgress;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    // THE PHYSICS: Pure linear vertical lift.
    // As lidProgress goes from 0.0 to 1.0, the lid lifts exactly 4.5 pixels straight up.
    // Because it is tied to your thumb, swiping backwards naturally pulls it down!
    final yOffset = lidProgress * -4.5;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // --- THE BIN (Static Base) ---
          Positioned(
            bottom: 2,
            child: Container(
              width: size * 0.55,
              height: size * 0.60,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 2.0),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(width: 1.5, height: size * 0.3, color: color),
                  Container(width: 1.5, height: size * 0.3, color: color),
                ],
              ),
            ),
          ),

          // --- THE LID (Straight Up & Down) ---
          Positioned(
            top: size * 0.15,
            child: Transform.translate(
              // Only shifting the Y-axis. No rotation, no X-axis shifting.
              offset: Offset(0, yOffset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The Handle
                  Container(
                    width: size * 0.2,
                    height: 2.0,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ),
                  // The Lid Base
                  Container(
                    width: size * 0.75,
                    height: 2.0,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
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
