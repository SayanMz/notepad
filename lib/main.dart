import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notepad/data/app_settings_repository.dart';
import 'package:notepad/data/note_repository.dart';
import 'package:notepad/views/home/home_page.dart';
import 'package:notepad/theme/app_theme.dart';

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

/// ---------------------------------------------------------------------------
/// APPLICATION ENTRY POINT
/// ---------------------------------------------------------------------------

void main() {
  /// Bootstraps the Flutter application.
  ///
  /// This is the first executed function and injects the root widget.
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
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// Internal state for MyApp.
///
/// Manages:
/// - Data hydration from repositories
/// - Triggering UI readiness after async operations
class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    /// Initiates app data loading immediately on startup.
    ///
    /// Ensures:
    /// - Notes and settings are available before full UI interaction
    _initData();
  }

  /// -------------------------------------------------------------------------
  /// DATA INITIALIZATION
  /// -------------------------------------------------------------------------
  ///
  /// PURPOSE:
  /// Loads persisted data (notes + app settings) from local storage.
  ///
  /// PERFORMANCE:
  /// - Uses Future.wait() to execute both operations concurrently
  /// - Reduces total startup time compared to sequential loading
  ///
  /// SAFETY:
  /// - Uses `mounted` check to avoid calling setState on disposed widget
  void _initData() async {
    await Future.wait([noteRepository.load(), appSettingsRepository.load()]);

    if (!mounted) {
      return;
    }

    /// Triggers UI rebuild after data is ready.
    ///
    /// EFFECT:
    /// - Rebuilds MaterialApp with fully loaded repositories
    setState(() {});
  }

  /// -------------------------------------------------------------------------
  /// BUILD METHOD
  /// -------------------------------------------------------------------------
  ///
  /// Defines:
  /// - Reactive theme switching
  /// - Root MaterialApp configuration
  /// - Localization setup
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
        );
      },
    );
  }
}

/*
📌 Interview Framing Tip:

"This is the root orchestration layer. It handles app bootstrap, async hydration of local persistence, 
and global reactive theming using a lightweight ChangeNotifier pattern. 
I intentionally avoided over-engineering state management at this stage."
*/
