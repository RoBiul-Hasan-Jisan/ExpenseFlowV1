import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/transaction_model.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/transaction_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();

  void _changeMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1));
  }

  @override
  Widget build(BuildContext context) {
    final txns = ref.watch(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <TransactionModel>[]);
    final categoryMap = ref.watch(categoryMapProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    final byDay = <int, List<TransactionModel>>{};
    for (final t in txns) {
      if (t.date.year == _visibleMonth.year && t.date.month == _visibleMonth.month) {
        byDay.putIfAbsent(t.date.day, () => []).add(t);
      }
    }

    final firstWeekday = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday; // 1=Mon
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = firstWeekday - 1;

    final selectedTxns = txns
        .where((t) => t.date.year == _selectedDate.year && t.date.month == _selectedDate.month && t.date.day == _selectedDate.day)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Calendar')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.space(2)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left_rounded)),
                Text('${_monthName(_visibleMonth.month)} ${_visibleMonth.year}', style: theme.textTheme.titleMedium),
                IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right_rounded)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.space(2)),
            child: Row(
              children: [for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S']) Expanded(child: Center(child: Text(d, style: theme.textTheme.bodySmall)))],
            ),
          ),
          SizedBox(height: AppTheme.space(1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.space(1.5.round())),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemCount: leadingBlanks + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leadingBlanks) return const SizedBox.shrink();
                final day = index - leadingBlanks + 1;
                final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
                final hasIncome = (byDay[day] ?? []).any((t) => t.type == TransactionType.income);
                final hasExpense = (byDay[day] ?? []).any((t) => t.type == TransactionType.expense);
                final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
                final isToday = DateTime.now().year == date.year && DateTime.now().month == date.month && DateTime.now().day == date.day;

                return InkWell(
                  onTap: () => setState(() => _selectedDate = date),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : (isToday ? theme.colorScheme.primary.withValues(alpha: 0.1) : null),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day', style: TextStyle(color: isSelected ? Colors.white : null, fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasIncome) Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: const BoxDecoration(color: AppColors.income, shape: BoxShape.circle)),
                            if (hasExpense) Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: isSelected ? Colors.white : AppColors.expense, shape: BoxShape.circle)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedTxns.isEmpty
                ? const EmptyState(icon: Icons.event_note_outlined, title: 'No activity', message: 'No transactions on this day.')
                : ListView.separated(
                    padding: EdgeInsets.all(AppTheme.space(2)),
                    itemCount: selectedTxns.length,
                    separatorBuilder: (_, __) => SizedBox(height: AppTheme.space(1)),
                    itemBuilder: (context, i) => TransactionCard(
                      transaction: selectedTxns[i],
                      category: categoryMap[selectedTxns[i].categoryId],
                      currency: settings.currency,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return names[month - 1];
  }
}
