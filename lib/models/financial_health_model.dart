/// Result of the deterministic financial-health calculation.
/// See FinancialHealthCalculator (core/utils) for the scoring logic itself —
/// this file only defines the result shape, kept separate from UI and logic.
class FinancialHealthResult {
  final int score; // 0-100
  final FinancialHealthRating rating;
  final List<String> strengths;
  final List<String> improvements;
  final double savingsRate;
  final double budgetUsageFraction;
  final double expenseToIncomeRatio;
  final double recurringBurdenFraction;

  const FinancialHealthResult({
    required this.score,
    required this.rating,
    required this.strengths,
    required this.improvements,
    required this.savingsRate,
    required this.budgetUsageFraction,
    required this.expenseToIncomeRatio,
    required this.recurringBurdenFraction,
  });

  static FinancialHealthResult empty() => const FinancialHealthResult(
        score: 0,
        rating: FinancialHealthRating.noData,
        strengths: [],
        improvements: ['Add some transactions to see your financial health score.'],
        savingsRate: 0,
        budgetUsageFraction: 0,
        expenseToIncomeRatio: 0,
        recurringBurdenFraction: 0,
      );
}

enum FinancialHealthRating { excellent, good, fair, poor, noData }

extension FinancialHealthRatingX on FinancialHealthRating {
  String get label {
    switch (this) {
      case FinancialHealthRating.excellent:
        return 'Excellent';
      case FinancialHealthRating.good:
        return 'Good';
      case FinancialHealthRating.fair:
        return 'Fair';
      case FinancialHealthRating.poor:
        return 'Needs attention';
      case FinancialHealthRating.noData:
        return 'No data yet';
    }
  }
}
