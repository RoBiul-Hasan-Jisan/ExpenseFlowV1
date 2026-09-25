import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Material 3 theme definitions for ExpenseFlow — "Emerald & Gold".
///
/// Type system: Space Grotesk carries numbers and headlines (it has the
/// slightly mechanical, confident character a money app wants for large
/// figures); Inter carries body copy and UI labels for maximum legibility
/// at small sizes. An 8px spacing baseline underlies all layout.
class AppTheme {
  AppTheme._();

  static const double spacingUnit = 8.0;
  static double space(int units) => spacingUnit * units;

  static const double radiusSm = 12;
  static const double radiusMd = 20;
  static const double radiusLg = 28;
  static const double radiusPill = 100;

  static TextStyle _display(double size, FontWeight weight, Color color, {double? letterSpacing, double? height}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle _body(double size, FontWeight weight, Color color, {double? letterSpacing}) {
    return GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);
  }

  static TextTheme _textTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: _display(36, FontWeight.w700, primaryText, letterSpacing: -0.8, height: 1.05),
      displayMedium: _display(30, FontWeight.w700, primaryText, letterSpacing: -0.6),
      headlineMedium: _display(24, FontWeight.w700, primaryText, letterSpacing: -0.4),
      headlineSmall: _display(20, FontWeight.w700, primaryText, letterSpacing: -0.2),
      titleLarge: _display(18, FontWeight.w600, primaryText),
      titleMedium: _body(16, FontWeight.w600, primaryText),
      titleSmall: _body(14, FontWeight.w600, primaryText),
      bodyLarge: _body(16, FontWeight.w400, primaryText),
      bodyMedium: _body(14, FontWeight.w400, primaryText),
      bodySmall: _body(12.5, FontWeight.w400, secondaryText),
      labelLarge: _body(13.5, FontWeight.w600, primaryText, letterSpacing: 0.1),
      labelSmall: _body(11, FontWeight.w600, secondaryText, letterSpacing: 0.2),
    );
  }

  /// Numeric display style for money figures — used on hero/balance cards.
  static TextStyle amountStyle({required double size, required Color color, FontWeight weight = FontWeight.w700}) {
    return GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: weight, color: color, letterSpacing: -1.0, height: 1.0);
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.gold,
      surface: AppColors.lightSurface,
      error: AppColors.expense,
    );
    final textTheme = _textTheme(AppColors.lightTextPrimary, AppColors.lightTextSecondary);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _display(21, FontWeight.w700, AppColors.lightTextPrimary, letterSpacing: -0.3),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceAlt,
        contentPadding: EdgeInsets.symmetric(horizontal: space(2), vertical: space(2)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.75),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.expense, width: 1),
        ),
        hintStyle: _body(15, FontWeight.w400, AppColors.lightTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, space(7)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          side: const BorderSide(color: AppColors.lightBorder, width: 1.25),
          minimumSize: Size(double.infinity, space(7)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
          textStyle: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceAlt,
        selectedColor: AppColors.primary,
        labelStyle: _body(13, FontWeight.w600, AppColors.lightTextPrimary),
        secondaryLabelStyle: _body(13, FontWeight.w600, Colors.white),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return _body(11.5, selected ? FontWeight.w700 : FontWeight.w500, selected ? AppColors.primary : AppColors.lightTextSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.primary : AppColors.lightTextSecondary, size: 24);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 6,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightBorder, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.forest,
        contentTextStyle: _body(14, FontWeight.w500, Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryLight,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      secondary: AppColors.gold,
      surface: AppColors.darkSurface,
      error: AppColors.expense,
    );
    final textTheme = _textTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _display(21, FontWeight.w700, AppColors.darkTextPrimary, letterSpacing: -0.3),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceAlt,
        contentPadding: EdgeInsets.symmetric(horizontal: space(2), vertical: space(2)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.75),
        ),
        hintStyle: _body(15, FontWeight.w400, AppColors.darkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.midnight,
          minimumSize: Size(double.infinity, space(7)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          side: const BorderSide(color: AppColors.darkBorder, width: 1.25),
          minimumSize: Size(double.infinity, space(7)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
          textStyle: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceAlt,
        selectedColor: AppColors.primaryLight,
        labelStyle: _body(13, FontWeight.w600, AppColors.darkTextPrimary),
        secondaryLabelStyle: _body(13, FontWeight.w600, AppColors.midnight),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.16),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return _body(11.5, selected ? FontWeight.w700 : FontWeight.w500, selected ? AppColors.primaryLight : AppColors.darkTextSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.primaryLight : AppColors.darkTextSecondary, size: 24);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.midnight,
        elevation: 4,
        highlightElevation: 6,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceAlt,
        contentTextStyle: _body(14, FontWeight.w500, AppColors.darkTextPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primaryLight),
    );
  }
}
