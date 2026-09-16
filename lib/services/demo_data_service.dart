import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';

/// Generates realistic, seeded demo data so Demo Mode feels like a real
/// account from the first tap — multiple months of income/expenses,
/// budgets, and recurring bills. Seeded RNG keeps output reproducible
/// across app launches (not "random noise" every time).
class DemoDataService {
  static const _uuid = Uuid();
  static final _rand = Random(42);

  static List<CategoryModel> categories() => CategoryModel.defaults();

  static String _catId(String name, TransactionType type) =>
      type == TransactionType.income ? 'inc_${name.toLowerCase()}' : 'exp_${name.toLowerCase()}';

  /// Builds ~4 months of transactions ending today.
  static List<TransactionModel> transactions() {
    final txns = <TransactionModel>[];
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 3, 1);

    final expenseWeights = <String, double>{
      'Food': 1.0,
      'Transport': 0.5,
      'Shopping': 0.7,
      'Bills': 0.6,
      'Healthcare': 0.2,
      'Education': 0.15,
      'Entertainment': 0.4,
      'Travel': 0.15,
      'Housing': 0.3,
      'Subscriptions': 0.35,
      'Other': 0.25,
    };
    final expenseTitles = <String, List<String>>{
      'Food': ['Grocery shopping', 'Lunch with friends', 'Coffee run', 'Dinner out', 'Supermarket run'],
      'Transport': ['Ride share', 'Fuel top-up', 'Bus pass', 'Parking fee'],
      'Shopping': ['Clothing', 'Electronics', 'Home goods', 'Online order'],
      'Bills': ['Electricity bill', 'Water bill', 'Gas bill', 'Phone bill'],
      'Healthcare': ['Pharmacy', 'Doctor visit', 'Gym membership'],
      'Education': ['Online course', 'Textbook', 'Workshop fee'],
      'Entertainment': ['Movie night', 'Concert ticket', 'Streaming rental'],
      'Travel': ['Flight booking', 'Hotel stay', 'Weekend trip'],
      'Housing': ['Rent', 'Maintenance fee', 'Furniture'],
      'Subscriptions': ['Netflix', 'Spotify', 'Cloud storage', 'Gym app'],
      'Other': ['Miscellaneous', 'Gift', 'Donation'],
    };

    var day = start;
    while (day.isBefore(now) || day.isAtSameMomentAs(now)) {
      // salary on the 1st
      if (day.day == 1) {
        txns.add(_txn(
          type: TransactionType.income,
          category: 'Salary',
          title: 'Monthly salary',
          amount: 3200 + _rand.nextInt(300).toDouble(),
          date: day,
        ));
        if (_rand.nextDouble() < 0.4) {
          txns.add(_txn(
            type: TransactionType.income,
            category: 'Freelance',
            title: 'Freelance project',
            amount: 150 + _rand.nextInt(450).toDouble(),
            date: day.add(Duration(days: _rand.nextInt(10))),
          ));
        }
      }
      // rent on the 3rd
      if (day.day == 3) {
        txns.add(_txn(
          type: TransactionType.expense,
          category: 'Housing',
          title: 'Rent',
          amount: 900,
          date: day,
        ));
      }
      // daily-ish random expenses
      for (final entry in expenseWeights.entries) {
        if (_rand.nextDouble() < entry.value * 0.12) {
          final titles = expenseTitles[entry.key]!;
          txns.add(_txn(
            type: TransactionType.expense,
            category: entry.key,
            title: titles[_rand.nextInt(titles.length)],
            amount: _amountFor(entry.key),
            date: day,
          ));
        }
      }
      day = day.add(const Duration(days: 1));
    }

    txns.sort((a, b) => b.date.compareTo(a.date));
    return txns;
  }

  static double _amountFor(String category) {
    switch (category) {
      case 'Food':
        return 8 + _rand.nextInt(35).toDouble();
      case 'Transport':
        return 5 + _rand.nextInt(20).toDouble();
      case 'Shopping':
        return 20 + _rand.nextInt(120).toDouble();
      case 'Bills':
        return 30 + _rand.nextInt(80).toDouble();
      case 'Healthcare':
        return 15 + _rand.nextInt(60).toDouble();
      case 'Education':
        return 20 + _rand.nextInt(100).toDouble();
      case 'Entertainment':
        return 10 + _rand.nextInt(50).toDouble();
      case 'Travel':
        return 80 + _rand.nextInt(300).toDouble();
      case 'Housing':
        return 40 + _rand.nextInt(100).toDouble();
      case 'Subscriptions':
        return 6 + _rand.nextInt(15).toDouble();
      default:
        return 10 + _rand.nextInt(40).toDouble();
    }
  }

  static TransactionModel _txn({
    required TransactionType type,
    required String category,
    required String title,
    required double amount,
    required DateTime date,
  }) {
    final now = DateTime.now();
    return TransactionModel(
      id: _uuid.v4(),
      type: type,
      amount: double.parse(amount.toStringAsFixed(2)),
      categoryId: _catId(category, type),
      title: title,
      date: date,
      createdAt: date,
      updatedAt: now,
    );
  }

  static List<BudgetModel> budgets() {
    final now = DateTime.now();
    return [
      BudgetModel(id: _uuid.v4(), categoryId: null, limit: 1500, month: now.month, year: now.year, createdAt: now),
      BudgetModel(id: _uuid.v4(), categoryId: 'exp_food', limit: 600, month: now.month, year: now.year, createdAt: now),
      BudgetModel(id: _uuid.v4(), categoryId: 'exp_shopping', limit: 350, month: now.month, year: now.year, createdAt: now),
      BudgetModel(id: _uuid.v4(), categoryId: 'exp_entertainment', limit: 150, month: now.month, year: now.year, createdAt: now),
      BudgetModel(id: _uuid.v4(), categoryId: 'exp_transport', limit: 200, month: now.month, year: now.year, createdAt: now),
    ];
  }

  static List<RecurringTransactionModel> recurring() {
    final now = DateTime.now();
    DateTime nextOf(int day) {
      var next = DateTime(now.year, now.month, day);
      if (next.isBefore(now)) next = DateTime(now.year, now.month + 1, day);
      return next;
    }

    return [
      RecurringTransactionModel(
        id: _uuid.v4(),
        name: 'Monthly Salary',
        amount: 3300,
        categoryId: 'inc_salary',
        type: TransactionType.income,
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(now.year, now.month - 6, 1),
        nextDate: nextOf(1),
      ),
      RecurringTransactionModel(
        id: _uuid.v4(),
        name: 'Rent',
        amount: 900,
        categoryId: 'exp_housing',
        type: TransactionType.expense,
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(now.year, now.month - 6, 3),
        nextDate: nextOf(3),
      ),
      RecurringTransactionModel(
        id: _uuid.v4(),
        name: 'Netflix',
        amount: 15.99,
        categoryId: 'exp_subscriptions',
        type: TransactionType.expense,
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(now.year, now.month - 6, 12),
        nextDate: nextOf(12),
      ),
      RecurringTransactionModel(
        id: _uuid.v4(),
        name: 'Internet',
        amount: 55,
        categoryId: 'exp_bills',
        type: TransactionType.expense,
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(now.year, now.month - 6, 18),
        nextDate: nextOf(18),
      ),
      RecurringTransactionModel(
        id: _uuid.v4(),
        name: 'Electricity',
        amount: 70,
        categoryId: 'exp_bills',
        type: TransactionType.expense,
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(now.year, now.month - 6, 20),
        nextDate: nextOf(20),
      ),
      RecurringTransactionModel(
        id: _uuid.v4(),
        name: 'Car Insurance',
        amount: 480,
        categoryId: 'exp_bills',
        type: TransactionType.expense,
        frequency: RecurringFrequency.yearly,
        startDate: DateTime(now.year - 1, now.month, 25),
        nextDate: DateTime(now.year + (now.month >= 6 ? 1 : 0), 6, 25),
      ),
    ];
  }
}
