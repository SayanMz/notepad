import 'package:flutter/material.dart';
import 'package:notepad/core/constants/ui_constants.dart';
import 'package:notepad/core/data/app_settings_repository.dart';
import 'package:notepad/main.dart';
import 'package:notepad/features/recycle_page.dart';
import 'package:notepad/features/search_page.dart';

/// ---------------------------------------------------------------------------
/// HOME APP BAR
/// ---------------------------------------------------------------------------
///
/// RESPONSIBILITIES:
/// - Theme toggle
/// - Navigation (Search, Recycle Bin)
/// - Saving indicator (top progress bar)
///
/// DESIGN:
/// - Stateless UI component
/// - Receives dependencies via parameters
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({
    super.key,
    required this.isDark,
    required this.isSavingNotifier,
    required this.fadeRoute,
  });

  final bool isDark;
  final ValueNotifier<bool> isSavingNotifier;
  final Route Function(Widget) fadeRoute;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      leading: IconButton(
        onPressed: () async {
          final currentIsDark = appSettingsRepository.settings.isDarkMode;

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

      /// Top saving indicator
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(UIConstants.progressBarHeight),
        child: ValueListenableBuilder(
          valueListenable: isSavingNotifier,
          builder: (_, isSaving, _) {
            if (!isSaving) {
              return const SizedBox(height: UIConstants.progressBarHeight);
            }

            return LinearProgressIndicator(
              minHeight: UIConstants.progressBarHeight,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            );
          },
        ),
      ),

      actions: [
        /// Search
        IconButton(
          icon: Icon(
            Icons.search,
            size: UIConstants.iconMD,
            color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
          ),
          onPressed: () async {
            rootScaffoldMessengerKey.currentState?.clearSnackBars();
            await Navigator.push(context, fadeRoute(const SearchPage()));
          },
        ),

        /// Recycle bin
        IconButton(
          icon: Icon(
            Icons.restore_from_trash,
            size: UIConstants.iconMD,
            color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
          ),
          onPressed: () async {
            rootScaffoldMessengerKey.currentState?.clearSnackBars();

            await Navigator.push(context, fadeRoute(const RecyclePage()));
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + UIConstants.progressBarHeight);
}
