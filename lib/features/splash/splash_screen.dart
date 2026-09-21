import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 84),
            SizedBox(height: AppTheme.space(2.5.round())),
            const Text(
              'ExpenseFlow',
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
            ),
            SizedBox(height: AppTheme.space(1)),
            Text(
              'Manage your money. Understand your spending.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.space(4)),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
