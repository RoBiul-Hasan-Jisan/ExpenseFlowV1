import '../../models/budget_model.dart';
import '../../models/financial_health_model.dart';
import '../../models/recurring_transaction_model.dart';
import '../../models/transaction_model.dart';
import '../constants/app_constants.dart';

/// Deterministic, rule-based financial health scoring.
///
/// This is NOT an AI/ML feature — every input maps to an explicit,
/// reproducible calculation so the score can always be explained to the
/// user. Weights are defined in [AppConstants] and sum to 100.
class FinancialHealthCalculator {
  FinancialHealthCalculator._();

  static FinancialHealthResult calculate({
    required List<TransactionModel> currentMonthTransactions,
    required List<TransactionModel> previousMonthTransactions,
    required List<BudgetProgress> budgetProgress,
    required List<RecurringTransactionModel> recurring,
  }) {
    if (currentMonthTransactions.isEmpty) return FinancialHealthResult.empty();

    final income = _sum(currentMonthTransactions, TransactionType.income);
    final expenses = _sum(currentMonthTransactions, TransactionType.expense);
    final prevExpenses = _sum(previousMonthTransactions, TransactionType.expense);

    // 1. Savings rate: (income - expenses) / income, clamped to [-1, 1]
    final savingsRate = income <= 0 ? 0.0 : ((income - expenses) / income).clamp(-1.0, 1.0);
    final savingsScore = _scoreSavingsRate(savingsRate);

    // 2. Budget usage: average fraction used across all active budgets
    final budgetUsageFraction = budgetProgress.isEmpty
        ? 0.5 // neutral default when no budgets are set
        : budgetProgress.map((b) => b.fraction.clamp(0, 1.5)).reduce((a, b) => a + b) / budgetProgress.length;
    final budgetScore = _scoreBudgetUsage(budgetUsageFraction, hasBudgets: budgetProgress.isNotEmpty);

    // 3. Expense-to-income ratio
    final expenseRatio = income <= 0 ? 1.0 : (expenses / income);
    final expenseRatioScore = _scoreExpenseRatio(expenseRatio);

    // 4. Recurring payment burden: recurring monthly cost / income
    final monthlyRecurringCost = recurring
        .where((r) => r.isActive && r.type == TransactionType.expense)
        .fold<double>(0, (sum, r) => sum + _monthlyEquivalent(r));
    final recurringBurden = income <= 0 ? 0.0 : (monthlyRecurringCost / income).clamp(0.0, 2.0);
    final recurringScore = _scoreRecurringBurden(recurringBurden);

    // 5. Spending trend: month-over-month change in expenses
    final trendChange = prevExpenses <= 0 ? 0.0 : ((expenses - prevExpenses) / prevExpenses);
    final trendScore = _scoreTrend(trendChange);

    final total = (savingsScore * AppConstants.weightSavingsRate +
            budgetScore * AppConstants.weightBudgetUsage +
            expenseRatioScore * AppConstants.weightExpenseRatio +
            recurringScore * AppConstants.weightRecurringBurden +
            trendScore * AppConstants.weightSpendingTrend)
        .round();

    final score = total.clamp(0, 100);

    final strengths = <String>[];
    final improvements = <String>[];

    if (savingsRate >= 0.20) {
      strengths.add('Healthy savings rate of ${(savingsRate * 100).toStringAsFixed(0)}%');
    } else if (savingsRate < 0.05) {
      improvements.add('Savings rate is low — try to save at least 20% of income');
    }

    if (budgetProgress.isNotEmpty && budgetProgress.every((b) => b.status == BudgetStatus.onTrack)) {
      strengths.add('Spending within budget');
    } else if (budgetProgress.any((b) => b.status == BudgetStatus.exceeded)) {
      final over = budgetProgress.where((b) => b.status == BudgetStatus.exceeded).length;
      improvements.add('$over budget${over > 1 ? 's' : ''} exceeded this month');
    }

    if (expenseRatio < 0.7) {
      strengths.add('Bills under control relative to income');
    } else if (expenseRatio > 0.9) {
      improvements.add('Expenses are consuming most of your income');
    }

    if (recurringBurden < 0.3) {
      strengths.add('Recurring payments are a manageable share of income');
    } else if (recurringBurden > 0.5) {
      improvements.add('Recurring payments take up a large share of income');
    }

    if (trendChange > 0.15) {
      improvements.add('Spending increased ${(trendChange * 100).toStringAsFixed(0)}% vs last month');
    } else if (trendChange < -0.10) {
      strengths.add('Spending decreased vs last month');
    }

    if (strengths.isEmpty) strengths.add('Keep tracking to build a financial history');
    if (improvements.isEmpty) improvements.add('No major concerns detected this month');

    return FinancialHealthResult(
      score: score,
      rating: _ratingForScore(score),
      strengths: strengths,
      improvements: improvements,
      savingsRate: savingsRate,
      budgetUsageFraction: budgetUsageFraction,
      expenseToIncomeRatio: expenseRatio,
      recurringBurdenFraction: recurringBurden,
    );
  }

  static double _sum(List<TransactionModel> txns, TransactionType type) {
    return txns.where((t) => t.type == type).fold(0.0, (sum, t) => sum + t.amount);
  }

  static double _monthlyEquivalent(RecurringTransactionModel r) {
    switch (r.frequency) {
      case RecurringFrequency.daily:
        return r.amount * 30;
      case RecurringFrequency.weekly:
        return r.amount * 4.33;
      case RecurringFrequency.monthly:
        return r.amount;
      case RecurringFrequency.yearly:
        return r.amount / 12;
    }
  }

  // Each _score* function returns a value in [0, 1] representing how well
  // that dimension performed, which is then multiplied by its weight.
  static double _scoreSavingsRate(double rate) {
    if (rate >= 0.30) return 1.0;
    if (rate >= 0.20) return 0.85;
    if (rate >= 0.10) return 0.65;
    if (rate >= 0.0) return 0.4;
    return 0.1;
  }

  static double _scoreBudgetUsage(double fraction, {required bool hasBudgets}) {
    if (!hasBudgets) return 0.6; // neutral — encourage setting a budget
    if (fraction <= 0.70) return 1.0;
    if (fraction <= 0.90) return 0.7;
    if (fraction <= 1.0) return 0.4;
    return 0.15;
  }

  static double _scoreExpenseRatio(double ratio) {
    if (ratio <= 0.5) return 1.0;
    if (ratio <= 0.7) return 0.8;
    if (ratio <= 0.9) return 0.5;
    if (ratio <= 1.0) return 0.25;
    return 0.05;
  }

  static double _scoreRecurringBurden(double burden) {
    if (burden <= 0.25) return 1.0;
    if (burden <= 0.4) return 0.75;
    if (burden <= 0.6) return 0.45;
    return 0.2;
  }

  static double _scoreTrend(double change) {
    if (change <= -0.05) return 1.0;
    if (change <= 0.05) return 0.8;
    if (change <= 0.15) return 0.55;
    if (change <= 0.30) return 0.3;
    return 0.1;
  }

  static FinancialHealthRating _ratingForScore(int score) {
    if (score >= 80) return FinancialHealthRating.excellent;
    if (score >= 60) return FinancialHealthRating.good;
    if (score >= 40) return FinancialHealthRating.fair;
    return FinancialHealthRating.poor;
  }
}
