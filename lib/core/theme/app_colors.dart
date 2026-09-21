import 'package:flutter/material.dart';

/// Central color palette for ExpenseFlow.
/// Kept deliberately restrained (fintech, not "rainbow app").
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2F6B4F); // deep money-green
  static const Color primaryLight = Color(0xFF4E8A6C);
  static const Color primaryDark = Color(0xFF1E4A35);
  static const Color accent = Color(0xFF1F6FEB); // trust blue, used sparingly

  // Semantic
  static const Color income = Color(0xFF2E9E6B);
  static const Color expense = Color(0xFFD64545);
  static const Color transfer = Color(0xFF6B7FD7);
  static const Color warning = Color(0xFFE0A429);
  static const Color critical = Color(0xFFD64545);
  static const Color success = Color(0xFF2E9E6B);

  // Neutrals — light
  static const Color lightBackground = Color(0xFFF6F7F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEFF2EE);
  static const Color lightBorder = Color(0xFFE1E5DF);
  static const Color lightTextPrimary = Color(0xFF14201B);
  static const Color lightTextSecondary = Color(0xFF5B6B62);

  // Neutrals — dark
  static const Color darkBackground = Color(0xFF0E1512);
  static const Color darkSurface = Color(0xFF161F1A);
  static const Color darkSurfaceAlt = Color(0xFF1D2822);
  static const Color darkBorder = Color(0xFF2A3831);
  static const Color darkTextPrimary = Color(0xFFEAF1EC);
  static const Color darkTextSecondary = Color(0xFFA3B3AA);

  // Category palette (deterministic assignment by index — no randomness)
  static const List<Color> categoryPalette = [
    Color(0xFF2F6B4F),
    Color(0xFF1F6FEB),
    Color(0xFFD6893A),
    Color(0xFF9B59B6),
    Color(0xFFD64545),
    Color(0xFF2E9E6B),
    Color(0xFFE0A429),
    Color(0xFF6B7FD7),
    Color(0xFF00897B),
    Color(0xFFC2185B),
    Color(0xFF5B6B62),
  ];
}
