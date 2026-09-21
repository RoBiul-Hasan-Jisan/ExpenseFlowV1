import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Standard chrome (title, optional trailing widget, card frame) that
/// wraps every chart on the analytics/dashboard screens for visual
/// consistency.
class ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final double height;

  const ChartCard({super.key, required this.title, required this.child, this.trailing, this.height = 220});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space(2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: AppTheme.space(2)),
            SizedBox(height: height, child: child),
          ],
        ),
      ),
    );
  }
}
