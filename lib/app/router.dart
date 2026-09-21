import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/add_transaction/add_transaction_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/auth/forgot_password/forgot_password_screen.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/register/register_screen.dart';
import '../features/budgets/budgets_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/recurring/recurring_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/transactions/transactions_screen.dart';
import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import 'main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final loggedInOrDemo = session.isAuthenticated || session.isDemo;
      final loc = state.matchedLocation;
      final onAuthScreen = loc == '/login' || loc == '/register' || loc == '/forgot-password';

      if (session.status == SessionStatus.loading) {
        return loc == '/splash' ? null : '/splash';
      }
      if (loc == '/splash') {
        return loggedInOrDemo ? '/dashboard' : '/login';
      }
      if (!loggedInOrDemo && !onAuthScreen) return '/login';
      if (loggedInOrDemo && onAuthScreen) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/add-transaction',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AddTransactionScreen(existing: state.extra as TransactionModel?),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/recurring',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RecurringScreen(),
      ),
      GoRoute(
        path: '/calendar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReportsScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/transactions', builder: (context, state) => const TransactionsScreen()),
          GoRoute(path: '/analytics', builder: (context, state) => const AnalyticsScreen()),
          GoRoute(path: '/budgets', builder: (context, state) => const BudgetsScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
