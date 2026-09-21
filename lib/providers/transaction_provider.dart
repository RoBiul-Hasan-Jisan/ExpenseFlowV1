import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final transactionRepositoryProvider = Provider((ref) {
  return TransactionRepository(ref.watch(firestoreServiceProvider), ref.watch(localStorageServiceProvider));
});

/// Live list of all transactions for the current session (demo or auth).
final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final session = ref.watch(sessionProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watch(isDemo: session.isDemo, uid: session.uid);
});

/// Live categories (defaults + any custom ones a user has added).
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final storage = ref.watch(localStorageServiceProvider);
  return storage.loadCategories();
});

/// Simple lookup map: categoryId -> CategoryModel.
final categoryMapProvider = Provider<Map<String, CategoryModel>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  return categoriesAsync.maybeWhen(
    data: (list) => {for (final c in list) c.id: c},
    orElse: () => {},
  );
});

class TransactionFilter {
  final TransactionType? type;
  final String? categoryId;
  final TxnDateRange? dateRange;
  final String searchQuery;
  final TransactionSort sort;

  const TransactionFilter({
    this.type,
    this.categoryId,
    this.dateRange,
    this.searchQuery = '',
    this.sort = TransactionSort.dateDesc,
  });

  TransactionFilter copyWith({
    TransactionType? type,
    bool clearType = false,
    String? categoryId,
    bool clearCategory = false,
    TxnDateRange? dateRange,
    bool clearDateRange = false,
    String? searchQuery,
    TransactionSort? sort,
  }) {
    return TransactionFilter(
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      searchQuery: searchQuery ?? this.searchQuery,
      sort: sort ?? this.sort,
    );
  }
}

enum TransactionSort { dateDesc, dateAsc, amountDesc, amountAsc }

class TxnDateRange {
  final DateTime start;
  final DateTime end;
  const TxnDateRange({required this.start, required this.end});
}

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) => const TransactionFilter());

final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final txnsAsync = ref.watch(transactionsProvider);
  final filter = ref.watch(transactionFilterProvider);

  return txnsAsync.maybeWhen(
    data: (txns) {
      var result = txns.where((t) {
        if (filter.type != null && t.type != filter.type) return false;
        if (filter.categoryId != null && t.categoryId != filter.categoryId) return false;
        if (filter.dateRange != null) {
          if (t.date.isBefore(filter.dateRange!.start) || t.date.isAfter(filter.dateRange!.end)) return false;
        }
        if (filter.searchQuery.isNotEmpty) {
          final q = filter.searchQuery.toLowerCase();
          if (!t.title.toLowerCase().contains(q) && !(t.description?.toLowerCase().contains(q) ?? false)) {
            return false;
          }
        }
        return true;
      }).toList();

      switch (filter.sort) {
        case TransactionSort.dateDesc:
          result.sort((a, b) => b.date.compareTo(a.date));
          break;
        case TransactionSort.dateAsc:
          result.sort((a, b) => a.date.compareTo(b.date));
          break;
        case TransactionSort.amountDesc:
          result.sort((a, b) => b.amount.compareTo(a.amount));
          break;
        case TransactionSort.amountAsc:
          result.sort((a, b) => a.amount.compareTo(b.amount));
          break;
      }
      return result;
    },
    orElse: () => <TransactionModel>[],
  );
});

class TransactionActions {
  final Ref ref;
  TransactionActions(this.ref);

  Future<void> add(TransactionModel txn) async {
    final session = ref.read(sessionProvider);
    await ref.read(transactionRepositoryProvider).add(isDemo: session.isDemo, uid: session.uid, transaction: txn);
    ref.invalidate(transactionsProvider);
  }

  Future<void> update(TransactionModel txn) async {
    final session = ref.read(sessionProvider);
    await ref.read(transactionRepositoryProvider).update(isDemo: session.isDemo, uid: session.uid, transaction: txn);
    ref.invalidate(transactionsProvider);
  }

  Future<void> delete(String id) async {
    final session = ref.read(sessionProvider);
    await ref.read(transactionRepositoryProvider).delete(isDemo: session.isDemo, uid: session.uid, id: id);
    ref.invalidate(transactionsProvider);
  }

  Future<void> duplicate(TransactionModel txn) async {
    final session = ref.read(sessionProvider);
    await ref.read(transactionRepositoryProvider).duplicate(isDemo: session.isDemo, uid: session.uid, transaction: txn);
    ref.invalidate(transactionsProvider);
  }
}

final transactionActionsProvider = Provider((ref) => TransactionActions(ref));
