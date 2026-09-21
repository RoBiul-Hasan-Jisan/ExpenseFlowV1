import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/transaction_card.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txnsAsync = ref.watch(transactionsProvider);
    final filtered = ref.watch(filteredTransactionsProvider);
    final categoryMap = ref.watch(categoryMapProvider);
    final settings = ref.watch(settingsProvider);
    final filter = ref.watch(transactionFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () => _openFilterSheet(context)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(AppTheme.space(2), 0, AppTheme.space(2), AppTheme.space(1)),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search transactions',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
              onChanged: (v) => ref.read(transactionFilterProvider.notifier).state = filter.copyWith(searchQuery: v),
            ),
          ),
          if (filter.type != null || filter.categoryId != null)
            Padding(
              padding: EdgeInsets.only(bottom: AppTheme.space(1), left: AppTheme.space(2)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (filter.type != null)
                      Chip(
                        label: Text(filter.type!.name),
                        onDeleted: () => ref.read(transactionFilterProvider.notifier).state = filter.copyWith(clearType: true),
                      ),
                    if (filter.categoryId != null)
                      Chip(
                        label: Text(categoryMap[filter.categoryId]?.name ?? 'Category'),
                        onDeleted: () => ref.read(transactionFilterProvider.notifier).state = filter.copyWith(clearCategory: true),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: txnsAsync.when(
              loading: () => const ListSkeleton(),
              error: (e, _) => ErrorState(message: 'Failed to load transactions.', onRetry: () => ref.invalidate(transactionsProvider)),
              data: (all) {
                if (all.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions yet',
                    message: 'Start tracking your finances today.',
                    actionLabel: 'Add Transaction',
                    onAction: () => context.push('/add-transaction'),
                  );
                }
                if (filtered.isEmpty) {
                  return const EmptyState(icon: Icons.search_off_rounded, title: 'No matches', message: 'Try a different search or filter.');
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(AppTheme.space(2), 0, AppTheme.space(2), AppTheme.space(10)),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => SizedBox(height: AppTheme.space(1)),
                  itemBuilder: (context, index) {
                    final t = filtered[index];
                    return TransactionCard(
                      transaction: t,
                      category: categoryMap[t.categoryId],
                      currency: settings.currency,
                      onTap: () => context.push('/add-transaction', extra: t),
                      onDelete: () => ref.read(transactionActionsProvider).delete(t.id),
                      onDuplicate: () => ref.read(transactionActionsProvider).duplicate(t),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    final categoriesAsync = ref.read(categoriesProvider);
    final filter = ref.read(transactionFilterProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return categoriesAsync.when(
          loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SizedBox(height: 100, child: Center(child: Text('$e'))),
          data: (categories) {
            return Padding(
              padding: EdgeInsets.fromLTRB(AppTheme.space(2.5.round()), AppTheme.space(2), AppTheme.space(2.5.round()), AppTheme.space(4)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter Transactions', style: Theme.of(ctx).textTheme.titleLarge),
                  SizedBox(height: AppTheme.space(2)),
                  Text('Type', style: Theme.of(ctx).textTheme.labelLarge),
                  SizedBox(height: AppTheme.space(1)),
                  Wrap(spacing: 8, children: [
                    for (final type in TransactionType.values)
                      ChoiceChip(
                        label: Text(type.name),
                        selected: filter.type == type,
                        onSelected: (_) => ref.read(transactionFilterProvider.notifier).state = filter.copyWith(type: type),
                      ),
                  ]),
                  SizedBox(height: AppTheme.space(2)),
                  Text('Category', style: Theme.of(ctx).textTheme.labelLarge),
                  SizedBox(height: AppTheme.space(1)),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    for (final c in categories)
                      ChoiceChip(
                        label: Text(c.name),
                        selected: filter.categoryId == c.id,
                        onSelected: (_) => ref.read(transactionFilterProvider.notifier).state = filter.copyWith(categoryId: c.id),
                      ),
                  ]),
                  SizedBox(height: AppTheme.space(2)),
                  Text('Sort by', style: Theme.of(ctx).textTheme.labelLarge),
                  SizedBox(height: AppTheme.space(1)),
                  Wrap(spacing: 8, children: [
                    _sortChip(ctx, ref, filter, TransactionSort.dateDesc, 'Newest'),
                    _sortChip(ctx, ref, filter, TransactionSort.dateAsc, 'Oldest'),
                    _sortChip(ctx, ref, filter, TransactionSort.amountDesc, 'Highest'),
                    _sortChip(ctx, ref, filter, TransactionSort.amountAsc, 'Lowest'),
                  ]),
                  SizedBox(height: AppTheme.space(3)),
                  OutlinedButton(
                    onPressed: () {
                      ref.read(transactionFilterProvider.notifier).state = const TransactionFilter();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sortChip(BuildContext ctx, WidgetRef ref, TransactionFilter filter, TransactionSort sort, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: filter.sort == sort,
      onSelected: (_) => ref.read(transactionFilterProvider.notifier).state = filter.copyWith(sort: sort),
    );
  }
}
