/// App-wide constants. No magic numbers/strings scattered through the codebase.
class AppConstants {
  AppConstants._();

  static const String appName = 'ExpenseFlow';
  static const String tagline = 'Manage your money. Understand your spending.';

  /// Base URL of the ExpenseFlow Node.js/MongoDB backend (see
  /// expenseflow-backend/). No trailing slash.
  ///
  /// - Android emulator          -> http://10.0.2.2:5000
  /// - iOS simulator / desktop   -> http://localhost:5000
  /// - Physical device           -> http://<your-computer-LAN-IP>:5000
  /// - Production                -> https://api.yourapp.com
  ///
  /// Override at build/run time with:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://expenseflowv1-b.onrender.com',
  );

  // Local storage keys
  static const String demoModeKey = 'expenseflow_demo_mode';
  static const String demoTransactionsKey = 'expenseflow_demo_transactions';
  static const String demoBudgetsKey = 'expenseflow_demo_budgets';
  static const String demoRecurringKey = 'expenseflow_demo_recurring';
  static const String demoCategoriesKey = 'expenseflow_demo_categories';
  static const String demoUserKey = 'expenseflow_demo_user';
  static const String settingsKey = 'expenseflow_settings';
  static const String onboardingSeenKey = 'expenseflow_onboarding_seen';

  // Budget thresholds (fraction of budget consumed)
  static const double budgetWarningThreshold = 0.70;
  static const double budgetCriticalThreshold = 0.90;

  // Financial health score weights (must sum to 100)
  static const int weightSavingsRate = 30;
  static const int weightBudgetUsage = 25;
  static const int weightExpenseRatio = 20;
  static const int weightRecurringBurden = 15;
  static const int weightSpendingTrend = 10;

  static const List<String> supportedCurrencies = ['BDT', 'USD', 'EUR', 'GBP', 'INR'];

  static const List<String> defaultExpenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Healthcare',
    'Education',
    'Entertainment',
    'Travel',
    'Housing',
    'Subscriptions',
    'Other',
  ];

  static const List<String> defaultIncomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Other',
  ];
}
