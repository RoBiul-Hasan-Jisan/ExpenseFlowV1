import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

/// Handles all on-device persistence for Demo Mode and app settings.
/// Demo data NEVER touches Firestore — this is the single source of
/// truth for that separation.
class LocalStorageService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> setDemoMode(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(AppConstants.demoModeKey, value);
  }

  Future<bool> isDemoMode() async {
    final prefs = await _instance;
    return prefs.getBool(AppConstants.demoModeKey) ?? false;
  }

  Future<void> saveTransactions(List<TransactionModel> txns) async {
    final prefs = await _instance;
    final raw = jsonEncode(txns.map((t) => t.toJson()).toList());
    await prefs.setString(AppConstants.demoTransactionsKey, raw);
  }

  Future<List<TransactionModel>> loadTransactions() async {
    final prefs = await _instance;
    final raw = prefs.getString(AppConstants.demoTransactionsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveBudgets(List<BudgetModel> budgets) async {
    final prefs = await _instance;
    final raw = jsonEncode(budgets.map((b) => b.toJson()).toList());
    await prefs.setString(AppConstants.demoBudgetsKey, raw);
  }

  Future<List<BudgetModel>> loadBudgets() async {
    final prefs = await _instance;
    final raw = prefs.getString(AppConstants.demoBudgetsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => BudgetModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveRecurring(List<RecurringTransactionModel> items) async {
    final prefs = await _instance;
    final raw = jsonEncode(items.map((r) => r.toJson()).toList());
    await prefs.setString(AppConstants.demoRecurringKey, raw);
  }

  Future<List<RecurringTransactionModel>> loadRecurring() async {
    final prefs = await _instance;
    final raw = prefs.getString(AppConstants.demoRecurringKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => RecurringTransactionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveCategories(List<CategoryModel> categories) async {
    final prefs = await _instance;
    final raw = jsonEncode(categories.map((c) => c.toJson()).toList());
    await prefs.setString(AppConstants.demoCategoriesKey, raw);
  }

  Future<List<CategoryModel>> loadCategories() async {
    final prefs = await _instance;
    final raw = prefs.getString(AppConstants.demoCategoriesKey);
    if (raw == null) return CategoryModel.defaults();
    final list = jsonDecode(raw) as List;
    return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveDemoUser(UserModel user) async {
    final prefs = await _instance;
    await prefs.setString(AppConstants.demoUserKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> loadDemoUser() async {
    final prefs = await _instance;
    final raw = prefs.getString(AppConstants.demoUserKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await _instance;
    await prefs.setString(AppConstants.settingsKey, jsonEncode(settings));
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await _instance;
    final raw = prefs.getString(AppConstants.settingsKey);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Wipes all locally-stored demo data (transactions, budgets, recurring,
  /// categories, demo user) but leaves app-level settings (theme, etc.) intact.
  Future<void> clearDemoData() async {
    final prefs = await _instance;
    await prefs.remove(AppConstants.demoTransactionsKey);
    await prefs.remove(AppConstants.demoBudgetsKey);
    await prefs.remove(AppConstants.demoRecurringKey);
    await prefs.remove(AppConstants.demoCategoriesKey);
    await prefs.remove(AppConstants.demoUserKey);
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await _instance;
    return prefs.getBool(AppConstants.onboardingSeenKey) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await _instance;
    await prefs.setBool(AppConstants.onboardingSeenKey, true);
  }
}
