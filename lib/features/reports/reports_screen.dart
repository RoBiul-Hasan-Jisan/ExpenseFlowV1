import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/transaction_model.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/export_service.dart';

enum _ReportRange { current, previous, custom }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _ReportRange _range = _ReportRange.current;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _exporting = false;
  final _exportService = ExportService();

  ({DateTime start, DateTime end}) get _resolvedRange {
    final now = DateTime.now();
    switch (_range) {
      case _ReportRange.current:
        return (start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month + 1, 0));
      case _ReportRange.previous:
        final m = now.month == 1 ? 12 : now.month - 1;
        final y = now.month == 1 ? now.year - 1 : now.year;
        return (start: DateTime(y, m, 1), end: DateTime(y, m + 1, 0));
      case _ReportRange.custom:
        return (start: _customStart ?? DateTime(now.year, now.month, 1), end: _customEnd ?? now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txns = ref.watch(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <TransactionModel>[]);
    final categories = ref.watch(categoriesProvider).maybeWhen(data: (c) => c, orElse: () => <CategoryModel>[]);
    final settings = ref.watch(settingsProvider);
    final range = _resolvedRange;

    final inRange = txns.where((t) => !t.date.isBefore(range.start) && !t.date.isAfter(range.end)).toList();
    final income = inRange.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
    final expenses = inRange.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);
    final net = income - expenses;
    final savingsRate = income <= 0 ? 0.0 : (net / income * 100);

    final categoryTotals = <String, double>{};
    for (final t in inRange.where((t) => t.type == TransactionType.expense)) {
      categoryTotals[t.categoryId] = (categoryTotals[t.categoryId] ?? 0) + t.amount;
    }
    final topExpenses = [...inRange.where((t) => t.type == TransactionType.expense)]..sort((a, b) => b.amount.compareTo(a.amount));

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: EdgeInsets.all(AppTheme.space(2)),
        children: [
          Text('Select Period', style: theme.textTheme.titleSmall),
          SizedBox(height: AppTheme.space(1)),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('Current Month'), selected: _range == _ReportRange.current, onSelected: (_) => setState(() => _range = _ReportRange.current)),
            ChoiceChip(label: const Text('Previous Month'), selected: _range == _ReportRange.previous, onSelected: (_) => setState(() => _range = _ReportRange.previous)),
            ChoiceChip(label: const Text('Custom Range'), selected: _range == _ReportRange.custom, onSelected: (_) async {
              final picked = await showDateRangePicker(context: context, firstDate: DateTime(2015), lastDate: DateTime.now());
              if (picked != null) {
                setState(() {
                  _range = _ReportRange.custom;
                  _customStart = picked.start;
                  _customEnd = picked.end;
                });
              }
            }),
          ]),
          SizedBox(height: AppTheme.space(1)),
          Text('${DateFormatter.monthDayYear(range.start)} – ${DateFormatter.monthDayYear(range.end)}', style: theme.textTheme.bodySmall),
          SizedBox(height: AppTheme.space(3)),
          Card(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.space(2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reportRow(theme, 'Total Income', CurrencyFormatter.format(income, settings.currency)),
                  _reportRow(theme, 'Total Expenses', CurrencyFormatter.format(expenses, settings.currency)),
                  _reportRow(theme, 'Net Savings', CurrencyFormatter.format(net, settings.currency)),
                  _reportRow(theme, 'Savings Rate', '${savingsRate.toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ),
          SizedBox(height: AppTheme.space(3)),
          ElevatedButton.icon(
            onPressed: _exporting ? null : () => _exportPdf(range, income, expenses, categoryTotals, topExpenses, categories, settings.currency),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Export as PDF'),
          ),
          SizedBox(height: AppTheme.space(1.5.round())),
          OutlinedButton.icon(
            onPressed: _exporting ? null : () => _exportCsv(inRange, categories),
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            label: const Text('Export as CSV'),
          ),
        ],
      ),
    );
  }

  Widget _reportRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: theme.textTheme.bodyMedium), Text(value, style: theme.textTheme.titleSmall)],
      ),
    );
  }

  Future<void> _exportPdf(
    ({DateTime start, DateTime end}) range,
    double income,
    double expenses,
    Map<String, double> categoryTotals,
    List<TransactionModel> topExpenses,
    List categories,
    String currency,
  ) async {
    setState(() => _exporting = true);
    try {
      final file = await _exportService.exportMonthlyReportPdf(
        currency: currency,
        monthStart: range.start,
        totalIncome: income,
        totalExpenses: expenses,
        categoryBreakdown: categoryTotals,
        topExpenses: topExpenses.take(10).toList(),
        categories: categories.cast(),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report saved: ${file.path.split('/').last}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportCsv(List<TransactionModel> transactions, List categories) async {
    setState(() => _exporting = true);
    try {
      final file = await _exportService.exportTransactionsCsv(transactions, categories.cast());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV saved: ${file.path.split('/').last}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}
