import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import 'category_icon.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.category,
    required this.currency,
    this.onTap,
    this.onDelete,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor = transaction.type == TransactionType.income
        ? AppColors.income
        : (transaction.type == TransactionType.expense ? AppColors.expense : AppColors.transfer);
    final sign = transaction.type == TransactionType.income ? '+' : (transaction.type == TransactionType.expense ? '-' : '');

    final card = Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppTheme.space(1.5.round())),
          child: Row(
            children: [
              CategoryIcon(category: category, size: 44),
              SizedBox(width: AppTheme.space(1.5.round())),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaction.title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${category?.name ?? 'Other'} · ${DateFormatter.relative(transaction.date)}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '$sign${CurrencyFormatter.format(transaction.amount, currency)}',
                style: AppTheme.amountStyle(size: 15, color: amountColor, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );

    if (onDelete == null) return card;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: AppTheme.space(2.5.round())),
        decoration: BoxDecoration(color: AppColors.expense, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete transaction?'),
                content: Text('This will permanently delete "${transaction.title}".'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(foregroundColor: AppColors.expense),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete?.call(),
      child: card,
    );
  }
}
