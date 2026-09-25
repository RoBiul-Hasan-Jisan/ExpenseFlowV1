import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// The ExpenseFlow brand mark. Use this everywhere the app needs to show
/// its logo (splash, login/auth screens, empty states, about section)
/// instead of duplicating Image.asset calls with ad-hoc sizing.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 84, this.rounded = true, this.glow = false});

  final double size;
  final bool rounded;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (!rounded) return image;

    final mark = ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        padding: EdgeInsets.all(size * 0.08),
        child: image,
      ),
    );

    if (!glow) return mark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(color: AppColors.gold.withValues(alpha: 0.35), blurRadius: size * 0.45, spreadRadius: size * 0.02),
          BoxShadow(color: AppColors.primaryLight.withValues(alpha: 0.25), blurRadius: size * 0.7, spreadRadius: -size * 0.05),
        ],
      ),
      child: mark,
    );
  }
}
