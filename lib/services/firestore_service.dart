import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';

/// All Firestore reads/writes for authenticated users live here.
/// Every query is scoped under users/{uid}/... so one user can never
/// read another user's financial records (also enforced server-side —
/// see firestore.rules).
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _transactions(String uid) =>
      _db.collection('users').doc(uid).collection('transactions');

  CollectionReference<Map<String, dynamic>> _budgets(String uid) =>
      _db.collection('users').doc(uid).collection('budgets');

  CollectionReference<Map<String, dynamic>> _recurring(String uid) =>
      _db.collection('users').doc(uid).collection('recurring');

  CollectionReference<Map<String, dynamic>> _categories(String uid) =>
      _db.collection('users').doc(uid).collection('categories');

  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      _db.collection('users').doc(uid).collection('profile').doc('data');

  DocumentReference<Map<String, dynamic>> _settings(String uid) =>
      _db.collection('users').doc(uid).collection('settings').doc('data');

  // ---- Transactions ----
  Stream<List<TransactionModel>> watchTransactions(String uid) {
    return _transactions(uid).orderBy('date', descending: true).snapshots().map(
          (s) => s.docs.map((d) => TransactionModel.fromJson(d.data())).toList(),
        );
  }

  Future<void> upsertTransaction(String uid, TransactionModel txn) =>
      _transactions(uid).doc(txn.id).set(txn.toJson());

  Future<void> deleteTransaction(String uid, String id) => _transactions(uid).doc(id).delete();

  // ---- Budgets ----
  Stream<List<BudgetModel>> watchBudgets(String uid) {
    return _budgets(uid).snapshots().map(
          (s) => s.docs.map((d) => BudgetModel.fromJson(d.data())).toList(),
        );
  }

  Future<void> upsertBudget(String uid, BudgetModel budget) => _budgets(uid).doc(budget.id).set(budget.toJson());

  Future<void> deleteBudget(String uid, String id) => _budgets(uid).doc(id).delete();

  // ---- Recurring ----
  Stream<List<RecurringTransactionModel>> watchRecurring(String uid) {
    return _recurring(uid).snapshots().map(
          (s) => s.docs.map((d) => RecurringTransactionModel.fromJson(d.data())).toList(),
        );
  }

  Future<void> upsertRecurring(String uid, RecurringTransactionModel item) =>
      _recurring(uid).doc(item.id).set(item.toJson());

  Future<void> deleteRecurring(String uid, String id) => _recurring(uid).doc(id).delete();

  // ---- Categories ----
  Stream<List<CategoryModel>> watchCategories(String uid) {
    return _categories(uid).snapshots().map(
          (s) => s.docs.map((d) => CategoryModel.fromJson(d.data())).toList(),
        );
  }

  Future<void> upsertCategory(String uid, CategoryModel category) =>
      _categories(uid).doc(category.id).set(category.toJson());

  Future<void> deleteCategory(String uid, String id) => _categories(uid).doc(id).delete();

  // ---- Settings / profile ----
  Future<void> saveSettings(String uid, Map<String, dynamic> settings) => _settings(uid).set(settings);

  Future<Map<String, dynamic>?> loadSettings(String uid) async {
    final doc = await _settings(uid).get();
    return doc.data();
  }

  Future<void> saveProfile(String uid, Map<String, dynamic> profile) => _profile(uid).set(profile, SetOptions(merge: true));
}
