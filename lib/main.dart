import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notepad/core/data/app_settings_repository.dart';
import 'package:notepad/features/note/data/note_repository.dart';
import 'package:notepad/core/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notepad/core/data/app_data.dart';
import 'package:notepad/features/home/home_page.dart';

/// ---------------------------------------------------------------------------
/// GLOBAL APPLICATION UTILITIES
/// ---------------------------------------------------------------------------

/// Global key to access the ScaffoldMessenger from anywhere in the app.
///
/// WHY THIS EXISTS:
/// - Enables showing SnackBars from non-UI layers (repositories/services)
///   without needing a BuildContext.
/// - Common use case: Undo actions, error messages, confirmations.
///
/// ARCHITECTURAL NOTE:
/// - This introduces a controlled global dependency for UI feedback.
/// - Acceptable for cross-cutting concerns, but should be used sparingly.

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Timer? _rootSnackBarTimer;

/// Shows a snackbar through the app-wide messenger and resets any pending hide timer.
void showRootSnackBar(SnackBar snackBar, {Duration? autoHideAfter}) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  _rootSnackBarTimer?.cancel();
  messenger.clearSnackBars();
  messenger.showSnackBar(snackBar);

  if (autoHideAfter != null) {
    _rootSnackBarTimer = Timer(autoHideAfter, () {
      messenger.hideCurrentSnackBar();
    });
  }
}

/// ---------------------------------------------------------------------------
/// APPLICATION ENTRY POINT
/// ---------------------------------------------------------------------------

Future<void> main() async {
  /// Bootstraps the Flutter application.
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Loads secret key
  await Hive.initFlutter();

  Hive.registerAdapter(NotesSectionAdapter());
  Hive.registerAdapter(AppSettingsAdapter());

  await Hive.openBox<NotesSection>('notes_box');
  await Hive.openBox<AppSettings>('settings_box');

  /// This is the first executed function and injects the root widget.
  await Future.wait([
    noteRepository.init(), // Handles seed notes + loading
    appSettingsRepository.load(), // Ensures dark/light mode is ready
  ]);
  runApp(const MyApp());
}

/// ---------------------------------------------------------------------------
/// ROOT APPLICATION WIDGET
/// ---------------------------------------------------------------------------

/// Root widget of the application.
///
/// WHY StatefulWidget:
/// - Handles asynchronous initialization (loading persisted data)
/// - Triggers UI rebuild once data is ready
///
/// RESPONSIBILITIES:
/// - App lifecycle initialization
/// - Global configuration (themes, localization, routing)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    /// -----------------------------------------------------------------------
    /// REACTIVE ROOT USING LISTENABLE BUILDER
    /// -----------------------------------------------------------------------
    ///
    /// WHY:
    /// - Listens to appSettingsRepository (ChangeNotifier)
    /// - Automatically rebuilds when user toggles dark mode
    ///
    /// BENEFIT:
    /// - Instant theme switching without app restart
    /// - Efficient rebuild (only MaterialApp subtree)
    return ListenableBuilder(
      listenable: appSettingsRepository,
      builder: (context, child) {
        return MaterialApp(
          /// App title (used by OS/task switchers)
          title: 'My Notepad',
          supportedLocales: const [Locale('en')],

          /// Theme configuration
          ///
          /// NOTE:
          /// - Themes are now modularized under /theme/
          /// - Improves maintainability and scalability
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,

          /// Dynamically selects theme based on user preference
          themeMode: appSettingsRepository.settings.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,

          /// Removes debug banner in development
          debugShowCheckedModeBanner: false,

          /// Root page of the application
          home: const HomePage(),

          /// Global ScaffoldMessenger for SnackBars
          ///
          /// Enables:
          /// - Undo actions
          /// - Error notifications
          /// - Cross-layer UI messaging
          scaffoldMessengerKey: rootScaffoldMessengerKey,

          /// -----------------------------------------------------------------
          /// LOCALIZATION CONFIGURATION
          /// -----------------------------------------------------------------
          ///
          /// REQUIRED FOR:
          /// - flutter_quill (rich text editor)
          /// - Proper formatting of toolbars, menus, clipboard actions
          ///
          /// ALSO ENABLES:
          /// - Internationalization support (i18n)
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            // Explicitly allow mouse dragging in note_toolbar
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
            },
          ),
        );
      },
    );
  }
}

/// -------------------------------------------------------------------------
/// BUILD METHOD
/// -------------------------------------------------------------------------
///
/// Defines:
/// - Reactive theme switching
/// - Root MaterialApp configuration
/// - Localization setup

/*
📌 Interview Framing Tip:

"This is the root orchestration layer. It handles app bootstrap, async hydration of local persistence, 
and global reactive theming using a lightweight ChangeNotifier pattern. 
I intentionally avoided over-engineering state management at this stage."
*/
