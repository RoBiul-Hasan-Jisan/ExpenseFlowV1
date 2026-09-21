import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/financial_health_calculator.dart';
import '../models/financial_health_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';
import 'budget_provider.dart';
import 'recurring_provider.dart';
import 'transaction_provider.dart';

/// All figures here are derived — never hardcoded — from the live
/// transactions stream, so the dashboard always reflects real data.
class MonthSummary {
  final double income;
  final double expenses;
  final double net;
  final double savingsRatePct;

  const MonthSummary({required this.income, required this.expenses, required this.net, required this.savingsRatePct});

  static const empty = MonthSummary(income: 0, expenses: 0, net: 0, savingsRatePct: 0);
}

List<TransactionModel> _inMonth(List<TransactionModel> txns, int month, int year) {
  return txns.where((t) => t.date.month == month && t.date.year == year).toList();
}

final currentMonthTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final txns = ref.watch(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <TransactionModel>[]);
  final now = DateTime.now();
  return _inMonth(txns, now.month, now.year);
});

final previousMonthTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final txns = ref.watch(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <TransactionModel>[]);
  final now = DateTime.now();
  final prevMonth = now.month == 1 ? 12 : now.month - 1;
  final prevYear = now.month == 1 ? now.year - 1 : now.year;
  return _inMonth(txns, prevMonth, prevYear);
});

final currentMonthSummaryProvider = Provider<MonthSummary>((ref) {
  final txns = ref.watch(currentMonthTransactionsProvider);
  if (txns.isEmpty) return MonthSummary.empty;
  final income = txns.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
  final expenses = txns.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);
  final net = income - expenses;
  final rate = income <= 0 ? 0.0 : (net / income * 100);
  return MonthSummary(income: income, expenses: expenses, net: net, savingsRatePct: rate);
});

/// Month-over-month % change in total balance (net across all history)
/// used for the dashboard's "+8.4% this month" style indicator.
final balanceChangePctProvider = Provider<double>((ref) {
  final current = ref.watch(currentMonthSummaryProvider);
  final txns = ref.watch(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <TransactionModel>[]);
  final now = DateTime.now();
  final priorBalance = txns
      .where((t) => t.date.isBefore(DateTime(now.year, now.month, 1)))
      .fold(0.0, (s, t) => s + t.signedAmount);
  if (priorBalance == 0) return current.net == 0 ? 0 : 100;
  return (current.net / priorBalance.abs()) * 100;
});

final totalBalanceProvider = Provider<double>((ref) {
  final txns = ref.watch(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <TransactionModel>[]);
  return txns.fold(0.0, (s, t) => s + t.signedAmount);
});

/// Category -> total spent this month, sorted descending.
final categoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final txns = ref.watch(currentMonthTransactionsProvider).where((t) => t.type == TransactionType.expense);
  final map = <String, double>{};
  for (final t in txns) {
    map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
  }
  final entries = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return {for (final e in entries) e.key: e.value};
});

/// Daily net cash flow for the last 14 days — used by the cash-flow chart.
final cashFlowSeriesProvider = Provider<List<MapEntry<DateTime, double>>>((ref) {
  final txns = ref.watch(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <TransactionModel>[]);
  final now = DateTime.now();
  final days = List.generate(14, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 13 - i)));
  return days.map((d) {
    final dayTotal = txns
        .where((t) => t.date.year == d.year && t.date.month == d.month && t.date.day == d.day)
        .fold(0.0, (s, t) => s + t.signedAmount);
    return MapEntry(d, dayTotal);
  }).toList();
});

/// Monthly totals (income vs expense) for the last 6 months.
final monthlyTrendProvider = Provider<List<({DateTime month, double income, double expense})>>((ref) {
  final txns = ref.watch(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <TransactionModel>[]);
  final now = DateTime.now();
  final months = List.generate(6, (i) {
    final m = now.month - (5 - i);
    final year = now.year + (m <= 0 ? -1 : 0);
    final month = ((m - 1) % 12 + 12) % 12 + 1;
    return DateTime(year, month, 1);
  });
  return months.map((m) {
    final inMonth = _inMonth(txns, m.month, m.year);
    final income = inMonth.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
    final expense = inMonth.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);
    return (month: m, income: income, expense: expense);
  }).toList();
});

final financialHealthProvider = Provider<FinancialHealthResult>((ref) {
  final current = ref.watch(currentMonthTransactionsProvider);
  final previous = ref.watch(previousMonthTransactionsProvider);
  final budgetProgress = ref.watch(budgetProgressProvider);
  final recurring = ref.watch(recurringProvider).maybeWhen(data: (r) => r, orElse: () => <RecurringTransactionModel>[]);

  return FinancialHealthCalculator.calculate(
    currentMonthTransactions: current,
    previousMonthTransactions: previous,
    budgetProgress: budgetProgress,
    recurring: recurring,
  );
});
