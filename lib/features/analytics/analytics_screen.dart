import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/empty_state.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(transactionsProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: txnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (txns) {
          if (txns.isEmpty) {
            return const EmptyState(
              icon: Icons.insights_outlined,
              title: 'No data yet',
              message: 'Add transactions to see your spending analytics.',
            );
          }
          return ListView(
            padding: EdgeInsets.all(AppTheme.space(2)),
            children: [
              const _MonthlyTrendChart(),
              SizedBox(height: AppTheme.space(2)),
              _IncomeVsExpenseSummary(currency: settings.currency),
              SizedBox(height: AppTheme.space(2)),
              const _CategoryDistributionChart(),
              SizedBox(height: AppTheme.space(2)),
              _BudgetUtilizationChart(currency: settings.currency),
              SizedBox(height: AppTheme.space(2)),
              _SavingsTrendChart(currency: settings.currency),
              SizedBox(height: AppTheme.space(6)),
            ],
          );
        },
      ),
    );
  }
}

class _MonthlyTrendChart extends ConsumerWidget {
  const _MonthlyTrendChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(monthlyTrendProvider);
    final maxVal = trend.fold<double>(1, (m, e) => [m, e.income, e.expense].reduce((a, b) => a > b ? a : b));

    return ChartCard(
      title: 'Income vs Expenses (6 months)',
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= trend.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateFormat('MMM').format(trend[idx].month), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < trend.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: trend[i].income, color: AppColors.income, width: 8, borderRadius: BorderRadius.circular(3)),
                BarChartRodData(toY: trend[i].expense, color: AppColors.expense, width: 8, borderRadius: BorderRadius.circular(3)),
              ], barsSpace: 4),
          ],
        ),
      ),
    );
  }
}

class _IncomeVsExpenseSummary extends ConsumerWidget {
  final String currency;
  const _IncomeVsExpenseSummary({required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(currentMonthSummaryProvider);
    final theme = Theme.of(context);
    return Row(
      children: [
        _LegendStat(label: 'Income', value: summary.income, color: AppColors.income, currency: currency),
        SizedBox(width: AppTheme.space(1.5.round())),
        _LegendStat(label: 'Expenses', value: summary.expenses, color: AppColors.expense, currency: currency),
        SizedBox(width: AppTheme.space(1.5.round())),
        _LegendStat(label: 'Savings rate', value: summary.savingsRatePct, color: theme.colorScheme.primary, currency: null, suffix: '%'),
      ],
    );
  }
}

class _LegendStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String? currency;
  final String suffix;

  const _LegendStat({required this.label, required this.value, required this.color, required this.currency, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = currency != null ? CurrencyFormatter.format(value, currency!) : '${value.toStringAsFixed(1)}$suffix';
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.space(1.5.round())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              SizedBox(height: AppTheme.space(1)),
              Text(label, style: theme.textTheme.bodySmall),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(text, style: theme.textTheme.titleSmall)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDistributionChart extends ConsumerWidget {
  const _CategoryDistributionChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(categoryBreakdownProvider);
    final categoryMap = ref.watch(categoryMapProvider);

    if (breakdown.isEmpty) {
      return ChartCard(title: 'Category Distribution', height: 100, child: const Center(child: Text('No expenses this month.')));
    }
    final total = breakdown.values.fold(0.0, (a, b) => a + b);

    return ChartCard(
      title: 'Category Distribution',
      height: 260,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 36,
          sections: [
            for (final e in breakdown.entries)
              PieChartSectionData(
                value: e.value,
                color: categoryMap[e.key]?.color ?? AppColors.primary,
                title: '${(e.value / total * 100).toStringAsFixed(0)}%',
                radius: 60,
                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class _BudgetUtilizationChart extends ConsumerWidget {
  final String currency;
  const _BudgetUtilizationChart({required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(categoryBudgetProgressProvider);
    final categoryMap = ref.watch(categoryMapProvider);

    if (progress.isEmpty) {
      return ChartCard(title: 'Budget Utilization', height: 100, child: const Center(child: Text('No category budgets set.')));
    }

    return ChartCard(
      title: 'Budget Utilization',
      height: 60.0 * progress.length + 20,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: progress.length,
        itemBuilder: (context, i) {
          final p = progress[i];
          final cat = categoryMap[p.budget.categoryId];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cat?.name ?? 'Category', style: Theme.of(context).textTheme.bodySmall),
                    Text('${(p.fraction * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: p.fraction.clamp(0, 1).toDouble(),
                    minHeight: 6,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(cat?.color ?? AppColors.primary),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SavingsTrendChart extends ConsumerWidget {
  final String currency;
  const _SavingsTrendChart({required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(monthlyTrendProvider);
    final spots = <FlSpot>[
      for (var i = 0; i < trend.length; i++) FlSpot(i.toDouble(), trend[i].income - trend[i].expense),
    ];

    return ChartCard(
      title: 'Savings Trend',
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= trend.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateFormat('MMM').format(trend[idx].month), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.accent,
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: AppColors.accent.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }
}
