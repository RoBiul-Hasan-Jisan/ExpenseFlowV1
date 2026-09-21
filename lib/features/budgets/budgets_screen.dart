import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/budget_card.dart';
import '../../widgets/empty_state.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overall = ref.watch(overallBudgetProgressProvider);
    final categoryBudgets = ref.watch(categoryBudgetProgressProvider);
    final categoryMap = ref.watch(categoryMapProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetForm(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Budget'),
      ),
      body: (overall == null && categoryBudgets.isEmpty)
          ? EmptyState(
              icon: Icons.savings_outlined,
              title: 'No budgets set',
              message: 'Create a monthly budget to start tracking your spending limits.',
              actionLabel: 'Create Budget',
              onAction: () => _showBudgetForm(context, ref),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(AppTheme.space(2), AppTheme.space(2), AppTheme.space(2), AppTheme.space(10)),
              children: [
                if (overall != null) ...[
                  Text('Overall', style: theme.textTheme.titleSmall),
                  SizedBox(height: AppTheme.space(1)),
                  BudgetCard(
                    progress: overall,
                    currency: settings.currency,
                    onTap: () => _showBudgetForm(context, ref, existing: overall.budget),
                  ),
                  SizedBox(height: AppTheme.space(2.5.round())),
                ],
                if (categoryBudgets.isNotEmpty) ...[
                  Text('By Category', style: theme.textTheme.titleSmall),
                  SizedBox(height: AppTheme.space(1)),
                  for (final b in categoryBudgets)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppTheme.space(1.5.round())),
                      child: BudgetCard(
                        progress: b,
                        category: categoryMap[b.budget.categoryId],
                        currency: settings.currency,
                        onTap: () => _showBudgetForm(context, ref, existing: b.budget),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  void _showBudgetForm(BuildContext context, WidgetRef ref, {BudgetModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BudgetFormSheet(existing: existing),
    );
  }
}

class _BudgetFormSheet extends ConsumerStatefulWidget {
  final BudgetModel? existing;
  const _BudgetFormSheet({this.existing});

  @override
  ConsumerState<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<_BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  bool _overall = true;
  String? _categoryId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _overall = e.isOverall;
      _categoryId = e.categoryId;
      _limitController.text = e.limit.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_overall && _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a category')));
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final budget = BudgetModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      categoryId: _overall ? null : _categoryId,
      limit: double.parse(_limitController.text.trim()),
      month: now.month,
      year: now.year,
      createdAt: widget.existing?.createdAt ?? now,
    );
    if (widget.existing != null) {
      await ref.read(budgetActionsProvider).update(budget);
    } else {
      await ref.read(budgetActionsProvider).add(budget);
    }
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    await ref.read(budgetActionsProvider).delete(widget.existing!.id);
    if (mounted) Navigator.pop(context);
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing != null ? 'Edit Budget' : 'New Budget', style: theme.textTheme.titleLarge),
            SizedBox(height: AppTheme.space(2)),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Overall Budget'),
                    selected: _overall,
                    onSelected: (_) => setState(() => _overall = true),
                  ),
                ),
                SizedBox(width: AppTheme.space(1)),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Category Budget'),
                    selected: !_overall,
                    onSelected: (_) => setState(() => _overall = false),
                  ),
                ),
              ],
            ),
            if (!_overall) ...[
              SizedBox(height: AppTheme.space(2)),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (categories) {
                  final expenseCats = categories.where((c) => c.type == TransactionType.expense).toList();
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in expenseCats)
                        ChoiceChip(
                          label: Text(c.name),
                          selected: _categoryId == c.id,
                          onSelected: (_) => setState(() => _categoryId = c.id),
                        ),
                    ],
                  );
                },
              ),
            ],
            SizedBox(height: AppTheme.space(2)),
            Text('Monthly Limit', style: theme.textTheme.labelLarge),
            SizedBox(height: AppTheme.space(1)),
            TextFormField(
              controller: _limitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0.00'),
              validator: (v) {
                final val = double.tryParse((v ?? '').trim());
                if (val == null || val <= 0) return 'Enter a valid limit';
                return null;
              },
            ),
            SizedBox(height: AppTheme.space(3)),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.existing != null ? 'Save Changes' : 'Create Budget'),
            ),
            if (widget.existing != null) ...[
              SizedBox(height: AppTheme.space(1)),
              OutlinedButton(onPressed: _delete, child: const Text('Delete Budget')),
            ],
          ],
        ),
      ),
    );
  }
}
