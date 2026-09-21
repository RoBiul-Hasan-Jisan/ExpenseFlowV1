import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/category_model.dart';
import '../../models/recurring_transaction_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/empty_state.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringProvider);
    final categoryMap = ref.watch(categoryMapProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Payments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const _RecurringFormSheet()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Recurring'),
      ),
      body: recurringAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.event_repeat_rounded,
              title: 'No recurring payments',
              message: 'Add salary, rent, subscriptions, and other repeating items.',
            );
          }
          final sorted = [...items]..sort((a, b) => a.nextDate.compareTo(b.nextDate));
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(AppTheme.space(2), AppTheme.space(2), AppTheme.space(2), AppTheme.space(10)),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => SizedBox(height: AppTheme.space(1)),
            itemBuilder: (context, i) {
              final r = sorted[i];
              final cat = categoryMap[r.categoryId];
              final color = r.type == TransactionType.income ? AppColors.income : AppColors.expense;
              return Card(
                child: ListTile(
                  leading: CategoryIcon(category: cat),
                  title: Text(r.name),
                  subtitle: Text('${r.frequency.name[0].toUpperCase()}${r.frequency.name.substring(1)} · Next: ${DateFormatter.monthDayYear(r.nextDate)}'),
                  trailing: Text(
                    '${r.type == TransactionType.income ? '+' : '-'}${CurrencyFormatter.format(r.amount, settings.currency)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _RecurringFormSheet(existing: r),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RecurringFormSheet extends ConsumerStatefulWidget {
  final RecurringTransactionModel? existing;
  const _RecurringFormSheet({this.existing});

  @override
  ConsumerState<_RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<_RecurringFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String? _categoryId;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  DateTime _startDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _amountController.text = e.amount.toStringAsFixed(2);
      _type = e.type;
      _categoryId = e.categoryId;
      _frequency = e.frequency;
      _startDate = e.startDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a category')));
      return;
    }
    setState(() => _saving = true);
    final item = RecurringTransactionModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      categoryId: _categoryId!,
      type: _type,
      frequency: _frequency,
      startDate: _startDate,
      nextDate: widget.existing?.nextDate ?? _startDate,
    );
    if (widget.existing != null) {
      await ref.read(recurringActionsProvider).update(item);
    } else {
      await ref.read(recurringActionsProvider).add(item);
    }
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.space(2.5.round()),
        AppTheme.space(2),
        AppTheme.space(2.5.round()),
        MediaQuery.of(context).viewInsets.bottom + AppTheme.space(3),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.existing != null ? 'Edit Recurring' : 'New Recurring', style: theme.textTheme.titleLarge),
              SizedBox(height: AppTheme.space(2)),
              Row(children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Expense'),
                    selected: _type == TransactionType.expense,
                    onSelected: (_) => setState(() {
                      _type = TransactionType.expense;
                      _categoryId = null;
                    }),
                  ),
                ),
                SizedBox(width: AppTheme.space(1)),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Income'),
                    selected: _type == TransactionType.income,
                    onSelected: (_) => setState(() {
                      _type = TransactionType.income;
                      _categoryId = null;
                    }),
                  ),
                ),
              ]),
              SizedBox(height: AppTheme.space(2)),
              Text('Name', style: theme.textTheme.labelLarge),
              SizedBox(height: AppTheme.space(1)),
              TextFormField(controller: _nameController, decoration: const InputDecoration(hintText: 'e.g. Netflix'), validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
              SizedBox(height: AppTheme.space(2)),
              Text('Amount', style: theme.textTheme.labelLarge),
              SizedBox(height: AppTheme.space(1)),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: '0.00'),
                validator: (v) {
                  final val = double.tryParse((v ?? '').trim());
                  if (val == null || val <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              SizedBox(height: AppTheme.space(2)),
              Text('Category', style: theme.textTheme.labelLarge),
              SizedBox(height: AppTheme.space(1)),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (categories) {
                  final filtered = categories.where((c) => c.type == _type).toList();
                  return Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final c in filtered)
                      ChoiceChip(label: Text(c.name), selected: _categoryId == c.id, onSelected: (_) => setState(() => _categoryId = c.id)),
                  ]);
                },
              ),
              SizedBox(height: AppTheme.space(2)),
              Text('Frequency', style: theme.textTheme.labelLarge),
              SizedBox(height: AppTheme.space(1)),
              Wrap(spacing: 8, children: [
                for (final f in RecurringFrequency.values)
                  ChoiceChip(label: Text(f.name), selected: _frequency == f, onSelected: (_) => setState(() => _frequency = f)),
              ]),
              SizedBox(height: AppTheme.space(2)),
              Text('Start Date', style: theme.textTheme.labelLarge),
              SizedBox(height: AppTheme.space(1)),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2015), lastDate: DateTime.now().add(const Duration(days: 730)));
                  if (picked != null) setState(() => _startDate = picked);
                },
                child: InputDecorator(decoration: const InputDecoration(), child: Text(DateFormatter.monthDayYear(_startDate))),
              ),
              SizedBox(height: AppTheme.space(3)),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.existing != null ? 'Save Changes' : 'Add Recurring'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
