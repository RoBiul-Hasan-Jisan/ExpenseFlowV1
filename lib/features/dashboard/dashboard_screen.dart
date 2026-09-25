import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/budget_model.dart';
import '../../models/financial_health_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/budget_card.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(transactionsProvider);
    final session = ref.watch(sessionProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: txnsAsync.when(
          loading: () => const DashboardSkeleton(),
          error: (e, _) => Center(child: Text('Failed to load: $e')),
          data: (txns) {
            if (txns.isEmpty) {
              return CustomScrollView(slivers: [
                _header(context, ref, session),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No transactions yet',
                    message: 'Start tracking your finances today.',
                    actionLabel: 'Add Transaction',
                    onAction: () => context.push('/add-transaction'),
                  ),
                ),
              ]);
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(transactionsProvider),
              child: CustomScrollView(
                slivers: [
                  _header(context, ref, session),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.space(2)),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _BalanceCard(currency: settings.currency),
                        SizedBox(height: AppTheme.space(2)),
                        _SummaryRow(currency: settings.currency),
                        SizedBox(height: AppTheme.space(2)),
                        const _CashFlowChart(),
                        SizedBox(height: AppTheme.space(2)),
                        const _CategoryBreakdownChart(),
                        SizedBox(height: AppTheme.space(2)),
                        _BudgetSnapshot(currency: settings.currency),
                        SizedBox(height: AppTheme.space(2)),
                        const _FinancialHealthCard(),
                        SizedBox(height: AppTheme.space(2)),
                        _UpcomingBills(currency: settings.currency),
                        SizedBox(height: AppTheme.space(2)),
                        _RecentTransactions(currency: settings.currency),
                        SizedBox(height: AppTheme.space(10)),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, SessionState session) {
    final theme = Theme.of(context);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(AppTheme.space(2), AppTheme.space(2), AppTheme.space(2), 0),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormatter.greeting(), style: theme.textTheme.bodyMedium),
                Text(session.user?.name ?? 'there', style: theme.textTheme.headlineMedium),
                if (session.isDemo)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: const Text('DEMO MODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning)),
                  )
                else
                  Text('Your financial overview', style: theme.textTheme.bodySmall),
              ],
            ),
            IconButton(
              onPressed: () => context.go('/profile'),
              icon: CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  final String currency;
  const _BalanceCard({required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(totalBalanceProvider);
    final changePct = ref.watch(balanceChangePctProvider);
    final positive = changePct >= 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: MeshDots(color: Colors.white)),
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withValues(alpha: 0.16)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppTheme.space(3)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Balance', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.gold, size: 16),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.space(1)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(balance, currency),
                    style: AppTheme.amountStyle(size: 36, color: Colors.white),
                  ),
                ),
                SizedBox(height: AppTheme.space(1.5.round())),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (positive ? AppColors.primaryLight : AppColors.expense).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(positive ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: Colors.white, size: 15),
                      const SizedBox(width: 4),
                      Text('${positive ? '+' : ''}${changePct.toStringAsFixed(1)}% this month',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends ConsumerWidget {
  final String currency;
  const _SummaryRow({required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(currentMonthSummaryProvider);
    return Row(
      children: [
        Expanded(child: SummaryCard(label: 'Income', amount: summary.income, currency: currency, color: AppColors.income, icon: Icons.arrow_downward_rounded)),
        SizedBox(width: AppTheme.space(1.5.round())),
        Expanded(child: SummaryCard(label: 'Expenses', amount: summary.expenses, currency: currency, color: AppColors.expense, icon: Icons.arrow_upward_rounded)),
        SizedBox(width: AppTheme.space(1.5.round())),
        Expanded(child: SummaryCard(label: 'Savings', amount: summary.net, currency: currency, color: AppColors.accent, icon: Icons.savings_rounded)),
      ],
    );
  }
}

class _CashFlowChart extends ConsumerWidget {
  const _CashFlowChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(cashFlowSeriesProvider);
    final theme = Theme.of(context);
    final spots = <FlSpot>[
      for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), series[i].value),
    ];
    final maxAbs = series.fold<double>(1, (m, e) => e.value.abs() > m ? e.value.abs() : m);

    return ChartCard(
      title: 'Cash Flow (14 days)',
      child: LineChart(
        LineChartData(
          minY: -maxAbs * 1.2,
          maxY: maxAbs * 1.2,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.12)),
            ),
          ],
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(y: 0, color: theme.dividerColor, strokeWidth: 1),
          ]),
        ),
      ),
    );
  }
}

class _CategoryBreakdownChart extends ConsumerWidget {
  const _CategoryBreakdownChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(categoryBreakdownProvider);
    final categoryMap = ref.watch(categoryMapProvider);

    if (breakdown.isEmpty) {
      return ChartCard(
        title: 'Spending by Category',
        height: 120,
        child: const Center(child: Text('No expenses recorded this month yet.')),
      );
    }

    final total = breakdown.values.fold(0.0, (a, b) => a + b);
    final top = breakdown.entries.take(5).toList();

    return ChartCard(
      title: 'Spending by Category',
      height: 200,
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: [
                  for (final e in top)
                    PieChartSectionData(
                      value: e.value,
                      color: categoryMap[e.key]?.color ?? AppColors.primary,
                      radius: 22,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: AppTheme.space(2)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final e in top)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: categoryMap[e.key]?.color ?? AppColors.primary, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(categoryMap[e.key]?.name ?? 'Other', style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                        Text('${(e.value / total * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSnapshot extends ConsumerWidget {
  final String currency;
  const _BudgetSnapshot({required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overall = ref.watch(overallBudgetProgressProvider);
    final theme = Theme.of(context);
    if (overall == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space(2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monthly Budget', style: theme.textTheme.titleSmall),
                TextButton(onPressed: () => context.go('/budgets'), child: const Text('View all')),
              ],
            ),
            SizedBox(height: AppTheme.space(0.5.round())),
            Text(
              '${CurrencyFormatter.format(overall.spent, currency)} / ${CurrencyFormatter.format(overall.budget.limit, currency)}',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: AppTheme.space(1)),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: overall.fraction.clamp(0, 1).toDouble(),
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(_statusColor(overall.status)),
              ),
            ),
            SizedBox(height: AppTheme.space(1)),
            Text('${(overall.fraction * 100).toStringAsFixed(0)}% used · ${CurrencyFormatter.format(overall.remaining.abs(), currency)} ${overall.remaining >= 0 ? 'remaining' : 'over'}',
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

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

class _FinancialHealthCard extends ConsumerWidget {
  const _FinancialHealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(financialHealthProvider);
    final theme = Theme.of(context);

    Color scoreColor;
    switch (health.rating.name) {
      case 'excellent':
        scoreColor = AppColors.success;
        break;
      case 'good':
        scoreColor = AppColors.primary;
        break;
      case 'fair':
        scoreColor = AppColors.warning;
        break;
      default:
        scoreColor = AppColors.critical;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space(2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Financial Health', style: theme.textTheme.titleSmall),
                const Spacer(),
                Text('${health.score}', style: AppTheme.amountStyle(size: 22, color: scoreColor)),
                Text(' / 100', style: theme.textTheme.bodySmall),
              ],
            ),
            SizedBox(height: AppTheme.space(0.5.round())),
            Text(health.rating.label, style: theme.textTheme.bodyMedium?.copyWith(color: scoreColor, fontWeight: FontWeight.w600)),
            SizedBox(height: AppTheme.space(1.5.round())),
            for (final s in health.strengths.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(child: Text(s, style: theme.textTheme.bodySmall)),
                ]),
              ),
            if (health.improvements.isNotEmpty) ...[
              SizedBox(height: AppTheme.space(1)),
              Text('Areas to improve', style: theme.textTheme.labelLarge),
              for (final i in health.improvements.take(3))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(child: Text(i, style: theme.textTheme.bodySmall)),
                  ]),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UpcomingBills extends ConsumerWidget {
  final String currency;
  const _UpcomingBills({required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingRecurringProvider);
    final categoryMap = ref.watch(categoryMapProvider);
    final theme = Theme.of(context);
    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Upcoming Bills', style: theme.textTheme.titleSmall),
            TextButton(onPressed: () => context.push('/recurring'), child: const Text('View all')),
          ],
        ),
        SizedBox(height: AppTheme.space(1)),
        for (final r in upcoming.take(3))
          Card(
            margin: EdgeInsets.only(bottom: AppTheme.space(1)),
            child: ListTile(
              leading: Icon(categoryMap[r.categoryId]?.icon ?? Icons.event_repeat_rounded, color: categoryMap[r.categoryId]?.color),
              title: Text(r.name),
              subtitle: Text(r.daysUntilNext == 0 ? 'Due today' : 'Due in ${r.daysUntilNext} day${r.daysUntilNext == 1 ? '' : 's'}'),
              trailing: Text(CurrencyFormatter.format(r.amount, currency), style: theme.textTheme.titleSmall),
            ),
          ),
      ],
    );
  }
}

class _RecentTransactions extends ConsumerWidget {
  final String currency;
  const _RecentTransactions({required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <TransactionModel>[]);
    final categoryMap = ref.watch(categoryMapProvider);
    final theme = Theme.of(context);
    final recent = txns.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions', style: theme.textTheme.titleSmall),
            TextButton(onPressed: () => context.go('/transactions'), child: const Text('View all')),
          ],
        ),
        SizedBox(height: AppTheme.space(1)),
        for (final t in recent)
          Padding(
            padding: EdgeInsets.only(bottom: AppTheme.space(1)),
            child: TransactionCard(transaction: t, category: categoryMap[t.categoryId], currency: currency),
          ),
      ],
    );
  }
}
