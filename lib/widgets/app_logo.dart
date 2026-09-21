import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// The ExpenseFlow brand mark. Use this everywhere the app needs to show
/// its logo (splash, login/auth screens, empty states, about section)
/// instead of duplicating Image.asset calls with ad-hoc sizing.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 84, this.rounded = true});

  final double size;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (!rounded) return image;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        padding: EdgeInsets.all(size * 0.08),
        child: image,
      ),
    );
  }
}
