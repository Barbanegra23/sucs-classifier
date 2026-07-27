import 'package:flutter/material.dart';

// =============================================================
// APP THEME COLORS — ThemeExtension con soporte light / dark
// =============================================================

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  // Paleta principal
  final Color primary;
  final Color primaryLight;
  final Color secondary;

  // Fondos
  final Color background;
  final Color card;
  final Color surface;

  // Header
  final Color headerBg;
  final Color headerSubtitle;
  final Color headerStatValue;
  final Color headerStatLabel;
  final Color headerAccentFade;

  // Texto
  final Color textPrimary;
  final Color textSecondary;

  // Inputs
  final Color inputFill;
  final Color inputBorder;
  final Color inputFocused;

  // Bordes y sombras
  final Color border;
  final Color shadow;
  final Color divider;

  // Colores de suelo (resultado)
  final Color soilClay;
  final Color soilSilt;
  final Color soilGravel;
  final Color soilSand;
  final Color soilError;

  const AppThemeColors({
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.background,
    required this.card,
    required this.surface,
    required this.headerBg,
    required this.headerSubtitle,
    required this.headerStatValue,
    required this.headerStatLabel,
    required this.headerAccentFade,
    required this.textPrimary,
    required this.textSecondary,
    required this.inputFill,
    required this.inputBorder,
    required this.inputFocused,
    required this.border,
    required this.shadow,
    required this.divider,
    required this.soilClay,
    required this.soilSilt,
    required this.soilGravel,
    required this.soilSand,
    required this.soilError,
  });

  // ── PALETA CLARA ──────────────────────────────────────────
  static const light = AppThemeColors(
    primary: Color(0xFFE5662A),
    primaryLight: Color(0xFFFF9A6C),
    secondary: Color(0xFF2F4F54),
    background: Color(0xFFFFF0E8),
    card: Color(0xFFFFFFFF),
    surface: Color(0xFFFFF8F5),
    headerBg: Color(0xFF1F3638),
    headerSubtitle: Color(0xFF7A9FA5),
    headerStatValue: Color(0xFFFF9A6C),
    headerStatLabel: Color(0xFF5A8088),
    headerAccentFade: Color(0x66E5662A),
    textPrimary: Color(0xFF1F3D42),
    textSecondary: Color(0xFF7A9295),
    inputFill: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFDDDDDD),
    inputFocused: Color(0xFFE5662A),
    border: Color(0xFFDDDDDD),
    shadow: Color(0x1A000000),
    divider: Color(0xFFEEEEEE),
    soilClay: Color(0xFFA0522D),
    soilSilt: Color(0xFFB8860B),
    soilGravel: Color(0xFF4A7C9E),
    soilSand: Color(0xFF5A7A5A),
    soilError: Color(0xFFCC3333),
  );

  // ── PALETA OSCURA ─────────────────────────────────────────
  // Mantiene la identidad de marca LINARE pero en tono oscuro.
  // Base: verde petróleo casi negro (#0E1D20) con acentos naranja.
  static const dark = AppThemeColors(
    primary: Color(0xFFFF7A3D), // naranja más brillante
    primaryLight: Color(0xFFFFAB7A),
    secondary: Color(0xFF4D8A92), // teal más claro
    background: Color(0xFF0E1D20), // fondo negro verdoso
    card: Color(0xFF162A2E), // card oscuro
    surface: Color(0xFF1A3236), // superficie ligeramente más clara
    headerBg: Color(0xFF060E10), // header más oscuro que el bg
    headerSubtitle: Color(0xFF507279),
    headerStatValue: Color(0xFFFF9A6C),
    headerStatLabel: Color(0xFF4A7A82),
    headerAccentFade: Color(0x66FF7A3D),
    textPrimary: Color(0xFFDEECEE), // blanco verdoso
    textSecondary: Color(0xFF7AA0A5),
    inputFill: Color(0xFF0E2024), // input aún más oscuro
    inputBorder: Color(0xFF2A4448),
    inputFocused: Color(0xFFFF7A3D),
    border: Color(0xFF2A4448),
    shadow: Color(0x40000000),
    divider: Color(0xFF1E3438),
    soilClay: Color(0xFFD07040), // arcilla — más brillante para fondo oscuro
    soilSilt: Color(0xFFD4A020), // limo
    soilGravel: Color(0xFF5E9ABF), // grava
    soilSand: Color(0xFF7A9E7A), // arena
    soilError: Color(0xFFE05050),
  );

  // ── ThemeExtension boilerplate ────────────────────────────

  @override
  AppThemeColors copyWith({
    Color? primary,
    Color? primaryLight,
    Color? secondary,
    Color? background,
    Color? card,
    Color? surface,
    Color? headerBg,
    Color? headerSubtitle,
    Color? headerStatValue,
    Color? headerStatLabel,
    Color? headerAccentFade,
    Color? textPrimary,
    Color? textSecondary,
    Color? inputFill,
    Color? inputBorder,
    Color? inputFocused,
    Color? border,
    Color? shadow,
    Color? divider,
    Color? soilClay,
    Color? soilSilt,
    Color? soilGravel,
    Color? soilSand,
    Color? soilError,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      card: card ?? this.card,
      surface: surface ?? this.surface,
      headerBg: headerBg ?? this.headerBg,
      headerSubtitle: headerSubtitle ?? this.headerSubtitle,
      headerStatValue: headerStatValue ?? this.headerStatValue,
      headerStatLabel: headerStatLabel ?? this.headerStatLabel,
      headerAccentFade: headerAccentFade ?? this.headerAccentFade,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      inputFill: inputFill ?? this.inputFill,
      inputBorder: inputBorder ?? this.inputBorder,
      inputFocused: inputFocused ?? this.inputFocused,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      divider: divider ?? this.divider,
      soilClay: soilClay ?? this.soilClay,
      soilSilt: soilSilt ?? this.soilSilt,
      soilGravel: soilGravel ?? this.soilGravel,
      soilSand: soilSand ?? this.soilSand,
      soilError: soilError ?? this.soilError,
    );
  }

  @override
  AppThemeColors lerp(AppThemeColors other, double t) {
    return AppThemeColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      headerBg: Color.lerp(headerBg, other.headerBg, t)!,
      headerSubtitle: Color.lerp(headerSubtitle, other.headerSubtitle, t)!,
      headerStatValue: Color.lerp(headerStatValue, other.headerStatValue, t)!,
      headerStatLabel: Color.lerp(headerStatLabel, other.headerStatLabel, t)!,
      headerAccentFade:
          Color.lerp(headerAccentFade, other.headerAccentFade, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      inputFocused: Color.lerp(inputFocused, other.inputFocused, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      soilClay: Color.lerp(soilClay, other.soilClay, t)!,
      soilSilt: Color.lerp(soilSilt, other.soilSilt, t)!,
      soilGravel: Color.lerp(soilGravel, other.soilGravel, t)!,
      soilSand: Color.lerp(soilSand, other.soilSand, t)!,
      soilError: Color.lerp(soilError, other.soilError, t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EXTENSIÓN DE CONTEXTO — acceso rápido: context.appColors.X
// ─────────────────────────────────────────────────────────────
extension AppThemeColorsX on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

// ─────────────────────────────────────────────────────────────
// AppColors — mantiene compatibilidad con archivos no migrados
// (header_widgets, historial_panel, etc. siguen usando AppColors.X)
// ─────────────────────────────────────────────────────────────
class AppColors {
  static const primary = Color(0xFFE5662A);
  static const primaryLight = Color(0xFFFF9A6C);
  static const secondary = Color(0xFF2F4F54);
  static const background = Color(0xFFFFF0E8);
  static const card = Colors.white;
  static const headerBg = Color(0xFF1F3638);
  static const headerSubtitle = Color(0xFF7A9FA5);
  static const headerStatValue = Color(0xFFFF9A6C);
  static const headerStatLabel = Color(0xFF5A8088);
  static const headerAccentFade = Color(0x66E5662A);
  static const textPrimary = Color(0xFF1F3D42);
  static const textSecondary = Colors.grey;
  static const error = Colors.red;
  static const success = Colors.green;
  static const border = Color(0xFFDDDDDD);
  static const shadow = Colors.black12;
  static const soilClay = Color(0xFFA0522D);
  static const soilSilt = Color(0xFFB8860B);
  static const soilGravel = Color(0xFF4A7C9E);
  static const soilSand = Color(0xFF5A7A5A);
  static const soilError = Color(0xFFCC3333);
}
