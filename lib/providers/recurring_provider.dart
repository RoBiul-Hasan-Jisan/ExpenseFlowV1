import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recurring_transaction_model.dart';
import '../repositories/recurring_repository.dart';
import 'auth_provider.dart';
import 'transaction_provider.dart';

final recurringRepositoryProvider = Provider((ref) {
  return RecurringRepository(ref.watch(firestoreServiceProvider), ref.watch(localStorageServiceProvider));
});

final recurringProvider = StreamProvider<List<RecurringTransactionModel>>((ref) {
  final session = ref.watch(sessionProvider);
  final repo = ref.watch(recurringRepositoryProvider);
  return repo.watch(isDemo: session.isDemo, uid: session.uid);
});

/// Recurring items due within the next 14 days, soonest first.
final upcomingRecurringProvider = Provider<List<RecurringTransactionModel>>((ref) {
  final async = ref.watch(recurringProvider);
  final list = async.maybeWhen(data: (r) => r, orElse: () => <RecurringTransactionModel>[]);
  final upcoming = list.where((r) => r.isActive && r.daysUntilNext <= 14 && r.daysUntilNext >= 0).toList();
  upcoming.sort((a, b) => a.nextDate.compareTo(b.nextDate));
  return upcoming;
});

class RecurringActions {
  final Ref ref;
  RecurringActions(this.ref);

  Future<void> add(RecurringTransactionModel item) async {
    final session = ref.read(sessionProvider);
    await ref.read(recurringRepositoryProvider).add(isDemo: session.isDemo, uid: session.uid, item: item);
    ref.invalidate(recurringProvider);
  }

  Future<void> update(RecurringTransactionModel item) async {
    final session = ref.read(sessionProvider);
    await ref.read(recurringRepositoryProvider).update(isDemo: session.isDemo, uid: session.uid, item: item);
    ref.invalidate(recurringProvider);
  }

  Future<void> delete(String id) async {
    final session = ref.read(sessionProvider);
    await ref.read(recurringRepositoryProvider).delete(isDemo: session.isDemo, uid: session.uid, id: id);
    ref.invalidate(recurringProvider);
  }
}

final recurringActionsProvider = Provider((ref) => RecurringActions(ref));
