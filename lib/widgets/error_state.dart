import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, this.message = 'Something went wrong.', this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(AppTheme.space(4)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: theme.colorScheme.error),
          SizedBox(height: AppTheme.space(2)),
          Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            SizedBox(height: AppTheme.space(2)),
            OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ],
      ),
    );
  }
}
