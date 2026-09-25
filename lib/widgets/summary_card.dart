import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/currency_formatter.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0.04)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      padding: EdgeInsets.all(AppTheme.space(1.75.round())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
            ],
          ),
          SizedBox(height: AppTheme.space(1)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(amount, currency),
              style: AppTheme.amountStyle(size: 19, color: theme.textTheme.titleMedium!.color!),
            ),
          ),
        ],
      ),
    );
  }
}
