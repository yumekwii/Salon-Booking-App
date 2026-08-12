import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static const Color ink = Color(0xFF241E21);
  static const Color muted = Color(0xFF75696E);

  // Poppins is the primary UI family. Headers use heavy weights deliberately.
  static TextStyle _ui({
    required double size,
    required FontWeight weight,
    Color color = ink,
    double height = 1.2,
    double letterSpacing = 0,
  }) => GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextTheme buildTextTheme() => TextTheme(
        displayLarge: _ui(size: 44, weight: FontWeight.w900, height: 1.02, letterSpacing: -1.1),
        displayMedium: _ui(size: 38, weight: FontWeight.w900, height: 1.04, letterSpacing: -0.9),
        displaySmall: _ui(size: 32, weight: FontWeight.w900, height: 1.06, letterSpacing: -0.8),
        headlineLarge: _ui(size: 30, weight: FontWeight.w900, height: 1.08, letterSpacing: -0.8),
        headlineMedium: _ui(size: 26, weight: FontWeight.w900, height: 1.12, letterSpacing: -0.6),
        headlineSmall: _ui(size: 23, weight: FontWeight.w900, height: 1.16, letterSpacing: -0.5),
        titleLarge: _ui(size: 20, weight: FontWeight.w900, height: 1.18, letterSpacing: -0.35),
        titleMedium: _ui(size: 16, weight: FontWeight.w800, height: 1.22, letterSpacing: -0.15),
        titleSmall: _ui(size: 14, weight: FontWeight.w800, height: 1.22),
        bodyLarge: _ui(size: 15, weight: FontWeight.w700, height: 1.4),
        bodyMedium: _ui(size: 13, weight: FontWeight.w600, color: muted, height: 1.4),
        bodySmall: _ui(size: 11.5, weight: FontWeight.w700, color: muted, height: 1.35),
        labelLarge: _ui(size: 13, weight: FontWeight.w900, height: 1.18, letterSpacing: 0.05),
        labelMedium: _ui(size: 11.5, weight: FontWeight.w900, height: 1.18, letterSpacing: 0.2),
        labelSmall: _ui(size: 10, weight: FontWeight.w900, height: 1.14, letterSpacing: 0.35),
      );

  static TextStyle get brand => _ui(size: 29, weight: FontWeight.w900, letterSpacing: -1.0, height: 0.98);
  static TextStyle get price => _ui(size: 24, weight: FontWeight.w900, letterSpacing: -0.6, height: 1.0);
  static TextStyle get time => _ui(size: 16, weight: FontWeight.w900, letterSpacing: -0.25, height: 1.05);
}
