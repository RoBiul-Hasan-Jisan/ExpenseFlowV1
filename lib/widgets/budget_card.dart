import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/currency_formatter.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import 'category_icon.dart';

class BudgetCard extends StatelessWidget {
  final BudgetProgress progress;
  final CategoryModel? category;
  final String currency;
  final VoidCallback? onTap;

  const BudgetCard({super.key, required this.progress, this.category, required this.currency, this.onTap});

  Color _statusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.onTrack:
        return AppColors.success;
      case BudgetStatus.warning:
        return AppColors.warning;
      case BudgetStatus.critical:
      case BudgetStatus.exceeded:
        return AppColors.critical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(progress.status);
    final title = progress.budget.isOverall ? 'Monthly Budget' : (category?.name ?? 'Category');
    final pct = (progress.fraction * 100).clamp(0, 999).toStringAsFixed(0);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppTheme.space(2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!progress.budget.isOverall) ...[
                    CategoryIcon(category: category, size: 32),
                    SizedBox(width: AppTheme.space(1.5.round())),
                  ],
                  Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                  Text('$pct%', style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
                ],
              ),
              SizedBox(height: AppTheme.space(1.25.round())),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.fraction.clamp(0, 1).toDouble(),
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              SizedBox(height: AppTheme.space(1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${CurrencyFormatter.format(progress.spent, currency)} / ${CurrencyFormatter.format(progress.budget.limit, currency)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    progress.remaining >= 0
                        ? '${CurrencyFormatter.format(progress.remaining, currency)} left'
                        : '${CurrencyFormatter.format(progress.remaining.abs(), currency)} over',
                    style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
