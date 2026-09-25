import 'package:flutter/material.dart';

/// Central color palette for ExpenseFlow — "Emerald & Gold".
/// Derived from the logo: a green wallet with a gold coin.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0C8F62); // emerald
  static const Color primaryLight = Color(0xFF34D399); // mint (used on dark surfaces)
  static const Color primaryDark = Color(0xFF065A40);
  static const Color forest = Color(0xFF063B2C);
  static const Color midnight = Color(0xFF03211A);
  static const Color accent = Color(0xFF3B82F6);
  static const Color gold = Color(0xFFF8BC3B); // the coin
  static const Color goldDeep = Color(0xFFE79A10);

  // Semantic
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFF0506E);
  static const Color transfer = Color(0xFF7C8CF8);
  static const Color warning = Color(0xFFF59E0B);
  static const Color critical = Color(0xFFF0506E);
  static const Color success = Color(0xFF10B981);

  // Neutrals — light
  static const Color lightBackground = Color(0xFFF2F6F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFE9F0EC);
  static const Color lightBorder = Color(0xFFDCE7E1);
  static const Color lightTextPrimary = Color(0xFF0B1F18);
  static const Color lightTextSecondary = Color(0xFF5A6E64);

  // Neutrals — dark
  static const Color darkBackground = Color(0xFF06100C);
  static const Color darkSurface = Color(0xFF0E1A15);
  static const Color darkSurfaceAlt = Color(0xFF15251E);
  static const Color darkBorder = Color(0xFF223529);
  static const Color darkTextPrimary = Color(0xFFEAF5EF);
  static const Color darkTextSecondary = Color(0xFF9DB5A9);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E8A61), Color(0xFF075B41), Color(0xFF032A1F)],
    stops: [0, 0.55, 1],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B87D), Color(0xFF0A7A55)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD26A), Color(0xFFF0A81C)],
  );

  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF07402F), Color(0xFF042A1F), Color(0xFF021711)],
  );

  // Category palette (deterministic assignment by index — no randomness)
  static const List<Color> categoryPalette = [
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFF0506E),
    Color(0xFF14B8A6),
    Color(0xFFEAB308),
    Color(0xFF6366F1),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF64748B),
  ];
}
