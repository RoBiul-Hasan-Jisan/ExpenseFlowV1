import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';
import 'api_client.dart';

/// All reads/writes for authenticated (non-demo) users live here, talking
/// to the ExpenseFlow Node.js/MongoDB backend instead of Firestore. Every
/// request carries the signed-in user's Firebase ID token (see
/// ApiClient), and the server verifies it and scopes every query to that
/// user — so one user can never read another's financial records.
///
/// Kept as `FirestoreService` (rather than renamed) so every repository
/// that already depends on it needs zero changes.
///
/// `uid` parameters are still accepted for interface compatibility with
/// the repositories, but are not needed to build the request — the
/// backend derives the user from the Firebase ID token already attached
/// by ApiClient.
class FirestoreService {
  final ApiClient _api = ApiClient.instance;

  // ---- Transactions ----
  Stream<List<TransactionModel>> watchTransactions(String uid) async* {
    yield await _loadTransactions();
  }

  Future<List<TransactionModel>> _loadTransactions() async {
    final data = await _api.get('/api/transactions');
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    return items.map(TransactionModel.fromJson).toList();
  }

  Future<void> upsertTransaction(String uid, TransactionModel txn) =>
      _api.put('/api/transactions/${txn.id}', txn.toJson());

  Future<void> deleteTransaction(String uid, String id) => _api.delete('/api/transactions/$id');

  // ---- Budgets ----
  Stream<List<BudgetModel>> watchBudgets(String uid) async* {
    yield await _loadBudgets();
  }

  Future<List<BudgetModel>> _loadBudgets() async {
    final data = await _api.get('/api/budgets');
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    return items.map(BudgetModel.fromJson).toList();
  }

  Future<void> upsertBudget(String uid, BudgetModel budget) => _api.put('/api/budgets/${budget.id}', budget.toJson());

  Future<void> deleteBudget(String uid, String id) => _api.delete('/api/budgets/$id');

  // ---- Recurring ----
  Stream<List<RecurringTransactionModel>> watchRecurring(String uid) async* {
    yield await _loadRecurring();
  }

  Future<List<RecurringTransactionModel>> _loadRecurring() async {
    final data = await _api.get('/api/recurring');
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    return items.map(RecurringTransactionModel.fromJson).toList();
  }

  Future<void> upsertRecurring(String uid, RecurringTransactionModel item) =>
      _api.put('/api/recurring/${item.id}', item.toJson());

  Future<void> deleteRecurring(String uid, String id) => _api.delete('/api/recurring/$id');

  // ---- Categories ----
  Stream<List<CategoryModel>> watchCategories(String uid) async* {
    yield await _loadCategories();
  }

  Future<List<CategoryModel>> _loadCategories() async {
    final data = await _api.get('/api/categories');
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    return items.map(CategoryModel.fromJson).toList();
  }

  Future<void> upsertCategory(String uid, CategoryModel category) =>
      _api.put('/api/categories/${category.id}', category.toJson());

  Future<void> deleteCategory(String uid, String id) => _api.delete('/api/categories/$id');

  // ---- Settings / profile ----
  Future<void> saveSettings(String uid, Map<String, dynamic> settings) => _api.put('/api/users/me/settings', settings);

  Future<Map<String, dynamic>?> loadSettings(String uid) async {
    final data = await _api.get('/api/users/me/settings');
    return data['settings'] as Map<String, dynamic>?;
  }

  Future<void> saveProfile(String uid, Map<String, dynamic> profile) => _api.patch('/api/users/me', profile);
}
