import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../repositories/budget_repository.dart';
import 'auth_provider.dart';
import 'transaction_provider.dart';

final budgetRepositoryProvider = Provider((ref) {
  return BudgetRepository(ref.watch(firestoreServiceProvider), ref.watch(localStorageServiceProvider));
});

final budgetsProvider = StreamProvider<List<BudgetModel>>((ref) {
  final session = ref.watch(sessionProvider);
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.watch(isDemo: session.isDemo, uid: session.uid);
});

/// Computes live BudgetProgress (spent so far this month) for every
/// budget, derived purely from actual transactions — never hardcoded.
final budgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  final budgetsAsync = ref.watch(budgetsProvider);
  final txnsAsync = ref.watch(transactionsProvider);

  final budgets = budgetsAsync.maybeWhen(data: (b) => b, orElse: () => <BudgetModel>[]);
  final txns = txnsAsync.maybeWhen(data: (t) => t, orElse: () => <TransactionModel>[]);

  final now = DateTime.now();
  return budgets.where((b) => b.month == now.month && b.year == now.year).map((b) {
    final spent = txns.where((t) {
      if (t.type != TransactionType.expense) return false;
      if (t.date.month != b.month || t.date.year != b.year) return false;
      if (b.isOverall) return true;
      return t.categoryId == b.categoryId;
    }).fold(0.0, (sum, t) => sum + t.amount);
    return BudgetProgress(budget: b, spent: spent);
  }).toList();
});

final overallBudgetProgressProvider = Provider<BudgetProgress?>((ref) {
  final all = ref.watch(budgetProgressProvider);
  try {
    return all.firstWhere((b) => b.budget.isOverall);
  } catch (_) {
    return null;
  }
});

final categoryBudgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  final all = ref.watch(budgetProgressProvider);
  return all.where((b) => !b.budget.isOverall).toList();
});

class BudgetActions {
  final Ref ref;
  BudgetActions(this.ref);

  Future<void> add(BudgetModel budget) async {
    final session = ref.read(sessionProvider);
    await ref.read(budgetRepositoryProvider).add(isDemo: session.isDemo, uid: session.uid, budget: budget);
    ref.invalidate(budgetsProvider);
  }

  Future<void> update(BudgetModel budget) async {
    final session = ref.read(sessionProvider);
    await ref.read(budgetRepositoryProvider).update(isDemo: session.isDemo, uid: session.uid, budget: budget);
    ref.invalidate(budgetsProvider);
  }

  Future<void> delete(String id) async {
    final session = ref.read(sessionProvider);
    await ref.read(budgetRepositoryProvider).delete(isDemo: session.isDemo, uid: session.uid, id: id);
    ref.invalidate(budgetsProvider);
  }
}

final budgetActionsProvider = Provider((ref) => BudgetActions(ref));
