import 'package:uuid/uuid.dart';
import '../models/recurring_transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

class RecurringRepository {
  final FirestoreService _firestore;
  final LocalStorageService _localStorage;
  static const _uuid = Uuid();

  RecurringRepository(this._firestore, this._localStorage);

  Stream<List<RecurringTransactionModel>> watch({required bool isDemo, String? uid}) {
    if (isDemo || uid == null) {
      return Stream.fromFuture(_localStorage.loadRecurring()).asBroadcastStream();
    }
    return _firestore.watchRecurring(uid);
  }

  Future<List<RecurringTransactionModel>> loadOnce({required bool isDemo, String? uid}) async {
    if (isDemo || uid == null) return _localStorage.loadRecurring();
    return _firestore.watchRecurring(uid).first;
  }

  Future<void> add({required bool isDemo, String? uid, required RecurringTransactionModel item}) async {
    final withId = item.id.isEmpty ? item.copyWith(id: _uuid.v4()) : item;
    if (isDemo || uid == null) {
      final current = await _localStorage.loadRecurring();
      current.add(withId);
      await _localStorage.saveRecurring(current);
    } else {
      await _firestore.upsertRecurring(uid, withId);
    }
  }

  Future<void> update({required bool isDemo, String? uid, required RecurringTransactionModel item}) async {
    if (isDemo || uid == null) {
      final current = await _localStorage.loadRecurring();
      final idx = current.indexWhere((r) => r.id == item.id);
      if (idx != -1) current[idx] = item;
      await _localStorage.saveRecurring(current);
    } else {
      await _firestore.upsertRecurring(uid, item);
    }
  }

  Future<void> delete({required bool isDemo, String? uid, required String id}) async {
    if (isDemo || uid == null) {
      final current = await _localStorage.loadRecurring();
      current.removeWhere((r) => r.id == id);
      await _localStorage.saveRecurring(current);
    } else {
      await _firestore.deleteRecurring(uid, id);
    }
  }
}
