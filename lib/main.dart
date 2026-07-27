import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_colors.dart';
import 'screens/welcome_screen.dart';

// ─────────────────────────────────────────────────────────────
// NOTIFIER global — permite cambiar el tema desde cualquier
// widget sin InheritedWidget ni state management externo.
// ─────────────────────────────────────────────────────────────
final appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

const _kThemeKey = 'theme_mode';

Future<void> _cargarTema() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_kThemeKey);
  if (saved == 'dark') appThemeMode.value = ThemeMode.dark;
  if (saved == 'light') appThemeMode.value = ThemeMode.light;
  // 'system' o null → no cambia (valor inicial es system)
}

Future<void> toggleTheme() async {
  final isDark = appThemeMode.value == ThemeMode.dark;
  appThemeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kThemeKey, isDark ? 'light' : 'dark');
}

// ─────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _cargarTema();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final colors = brightness == Brightness.dark
        ? AppThemeColors.dark
        : AppThemeColors.light;

    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [colors],
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: Colors.white,
        secondary: colors.secondary,
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: colors.background,
        onSurface: colors.textPrimary,
      ),
      scaffoldBackgroundColor: colors.background,
      cardColor: colors.card,
      dividerColor: colors.divider,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.inputFocused, width: 2),
        ),
      ),
      // Transición de status bar según tema
      appBarTheme: AppBarTheme(
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Clasificador SUCS',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const WelcomeScreen(),
        );
      },
    );
  }
}
