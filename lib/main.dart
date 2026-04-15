import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notepad/data/app_settings_repository.dart';
import 'package:notepad/data/note_repository.dart';
import 'package:notepad/views/pages/home_page.dart';

/// Global key to access the ScaffoldMessenger from anywhere in the app.
/// ARCHITECTURE NOTE: This is crucial for showing SnackBars (like "Undo Delete")
/// from repositories or isolated functions without needing to pass BuildContext around.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // The initial data loading process the moment the app launches.
    _initData();
  }

  /// Logic: Asynchronously loads saved user data from local device storage.
  /// Uses Future.wait to load both Notes and Settings concurrently, cutting startup time in half.
  void _initData() async {
    await Future.wait([noteRepository.load(), appSettingsRepository.load()]);

    if (!mounted) {
      return;
    }

    // Triggers a UI rebuild to transition from a blank state to the actual HomePage
    // once the data is fully loaded into memory.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // --- Theme Definitions ---
    // Defining themes here keeps the MaterialApp clean and allows for instant swapping.
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      shadowColor: const Color(0xFF0D9488).withOpacity(0.4),
      // Inside ThemeData...
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: const Color(
          0xFF14B8A6,
        ), // Your Teal (use Amber for darkTheme)
        selectionColor: const Color(0xFF14B8A6).withOpacity(0.3),
        selectionHandleColor: const Color(0xFF14B8A6),
      ),

      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
        ),
      ),

      // ... (AppBarTheme, FAB Theme, etc.) ...

      // 5. The Core Palette
      scaffoldBackgroundColor: const Color(0xFFF0FDF4),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF0FDF4), // Match the background
        // ... rest of your settings
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF14B8A6),
        brightness: Brightness.light,
        primary: const Color(0xFF14B8A6),
        surface: Colors.white,
        // ... other colors ...
      ), // <--- CRITICAL: Make sure colorScheme closes here!
      // 6. Card Theme (MUST be on the same level as colorScheme)
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE4E4E7), width: 1.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      // Inside ThemeData...
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Colors.amberAccent, // Your Teal (use Amber for darkTheme)
        selectionColor: const Color(0xFF14B8A6).withOpacity(0.3),
        selectionHandleColor: const Color(0xFF14B8A6),
      ),

      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
        ),
      ),

      // 1. Root-Level Shadow Fix: Softens shadows globally for a premium feel
      shadowColor: Colors.black.withOpacity(0.4),
      scaffoldBackgroundColor: const Color(
        0xFF09090B,
      ), // Deep Onyx (AMOLED friendly)
      // 2. AppBar Optimization: Prevents the 'grey-out' on scroll
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF18181B), // Matches surface
        elevation: 0,
        scrolledUnderElevation: 0, // CRITICAL: Keeps AppBar from changing color
        centerTitle: true,
      ),

      // 3. Optimized FAB: Low elevation, high impact
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.amberAccent,
        foregroundColor: const Color(0xFF09090B),
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // 4. ColorScheme Optimization: Explicit mapping for better performance
      colorScheme: const ColorScheme.dark(
        primary: Colors.amberAccent,
        secondary: Color(0xFFFFD54F), // Amber[300] - better contrast than [400]
        // Surface roles for a layered look
        surface: Color(0xFF18181B),
        surfaceContainerLowest: Color(0xFF09090B),
        surfaceContainer: Color(0xFF1C1C1E), // For cards
        surfaceContainerHighest: Color(0xFF27272A), // For search bars/dialogs
        // Content colors
        onSurface: Color(0xFFF4F4F5),
        onSurfaceVariant: Colors.black,
      ),
    );
    // ARCHITECTURE NOTE: Reactive UI
    // ListenableBuilder listens to appSettingsRepository. If the user toggles dark mode
    // inside NotePage, notifyListeners() fires, and ONLY this block rebuilds to instantly
    // apply the new theme app-wide without restarting.
    return ListenableBuilder(
      listenable: appSettingsRepository,
      builder: (context, child) {
        return MaterialApp(
          title: 'My Notepad--',
          darkTheme: darkTheme,
          theme: lightTheme,
          // Dynamically apply the correct theme based on the user's saved settings
          themeMode: appSettingsRepository.settings.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: const HomePage(),
          // Attach the global key for app-wide SnackBar control
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          // Localization Delegates:
          // Required for flutter_quill (Rich Text Editor) to format toolbars,
          // menus, and copy/paste functionality correctly across different global regions.
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
