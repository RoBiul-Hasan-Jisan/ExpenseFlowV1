import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

/// Reads/writes transactions, routed to Firestore or local storage
/// depending on whether the current session is demo or authenticated.
/// This keeps that branch out of every provider/widget.
class TransactionRepository {
  final FirestoreService _firestore;
  final LocalStorageService _localStorage;
  static const _uuid = Uuid();

  TransactionRepository(this._firestore, this._localStorage);

  Stream<List<TransactionModel>> watch({required bool isDemo, String? uid}) {
    if (isDemo || uid == null) {
      return Stream.fromFuture(_localStorage.loadTransactions()).asBroadcastStream();
    }
    return _firestore.watchTransactions(uid);
  }

  Future<List<TransactionModel>> loadOnce({required bool isDemo, String? uid}) async {
    if (isDemo || uid == null) return _localStorage.loadTransactions();
    final list = await _firestore.watchTransactions(uid).first;
    return list;
  }

  Future<void> add({
    required bool isDemo,
    String? uid,
    required TransactionModel transaction,
  }) async {
    final withId = transaction.id.isEmpty ? transaction.copyWith(id: _uuid.v4()) : transaction;
    if (isDemo || uid == null) {
      final current = await _localStorage.loadTransactions();
      current.insert(0, withId);
      await _localStorage.saveTransactions(current);
    } else {
      await _firestore.upsertTransaction(uid, withId);
    }
  }

  Future<void> update({required bool isDemo, String? uid, required TransactionModel transaction}) async {
    if (isDemo || uid == null) {
      final current = await _localStorage.loadTransactions();
      final idx = current.indexWhere((t) => t.id == transaction.id);
      if (idx != -1) current[idx] = transaction;
      await _localStorage.saveTransactions(current);
    } else {
      await _firestore.upsertTransaction(uid, transaction);
    }
  }

  Future<void> delete({required bool isDemo, String? uid, required String id}) async {
    if (isDemo || uid == null) {
      final current = await _localStorage.loadTransactions();
      current.removeWhere((t) => t.id == id);
      await _localStorage.saveTransactions(current);
    } else {
      await _firestore.deleteTransaction(uid, id);
    }
  }

  Future<void> duplicate({required bool isDemo, String? uid, required TransactionModel transaction}) async {
    final now = DateTime.now();
    final copy = transaction.copyWith(
      id: _uuid.v4(),
      title: '${transaction.title} (copy)',
      date: now,
      createdAt: now,
      updatedAt: now,
    );
    await add(isDemo: isDemo, uid: uid, transaction: copy);
  }
}
