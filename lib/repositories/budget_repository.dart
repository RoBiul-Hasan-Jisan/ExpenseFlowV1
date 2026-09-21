import 'package:uuid/uuid.dart';
import '../models/budget_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

class BudgetRepository {
  final FirestoreService _firestore;
  final LocalStorageService _localStorage;
  static const _uuid = Uuid();

  BudgetRepository(this._firestore, this._localStorage);

  Stream<List<BudgetModel>> watch({required bool isDemo, String? uid}) {
    if (isDemo || uid == null) {
      return Stream.fromFuture(_localStorage.loadBudgets()).asBroadcastStream();
    }
    return _firestore.watchBudgets(uid);
  }

  Future<List<BudgetModel>> loadOnce({required bool isDemo, String? uid}) async {
    if (isDemo || uid == null) return _localStorage.loadBudgets();
    return _firestore.watchBudgets(uid).first;
  }

  Future<void> add({required bool isDemo, String? uid, required BudgetModel budget}) async {
    final withId = budget.id.isEmpty ? budget.copyWith(id: _uuid.v4()) : budget;
    if (isDemo || uid == null) {
      final current = await _localStorage.loadBudgets();
      current.add(withId);
      await _localStorage.saveBudgets(current);
    } else {
      await _firestore.upsertBudget(uid, withId);
    }
  }

  Future<void> update({required bool isDemo, String? uid, required BudgetModel budget}) async {
    if (isDemo || uid == null) {
      final current = await _localStorage.loadBudgets();
      final idx = current.indexWhere((b) => b.id == budget.id);
      if (idx != -1) current[idx] = budget;
      await _localStorage.saveBudgets(current);
    } else {
      await _firestore.upsertBudget(uid, budget);
    }
  }

  Future<void> delete({required bool isDemo, String? uid, required String id}) async {
    if (isDemo || uid == null) {
      final current = await _localStorage.loadBudgets();
      current.removeWhere((b) => b.id == id);
      await _localStorage.saveBudgets(current);
    } else {
      await _firestore.deleteBudget(uid, id);
    }
  }
}
