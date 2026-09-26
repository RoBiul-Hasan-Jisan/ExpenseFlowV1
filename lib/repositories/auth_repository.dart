import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/demo_data_service.dart';

/// Coordinates authentication state and the demo/authenticated mode
/// switch. This is the single place that decides "am I demo or real".
class AuthRepository {
  final AuthService _authService;
  final LocalStorageService _localStorage;

  AuthRepository(this._authService, this._localStorage);

  Stream<bool> get authStateChanges => _authService.authStateChanges.map((u) => u != null);

  bool get isAuthenticated => _authService.currentUser != null;

  /// The MongoDB-backed profile for the currently signed-in Firebase user,
  /// if it's already been fetched (e.g. by AuthService.init() at app
  /// startup, or by a prior signIn/register call this session).
  UserModel? get cachedUser => _authService.currentUserModel;

  Future<UserModel> signIn({required String email, required String password}) =>
      _authService.signIn(email: email, password: password);

  Future<UserModel> register({required String name, required String email, required String password}) =>
      _authService.register(name: name, email: email, password: password);

  Future<void> sendPasswordReset(String email) => _authService.sendPasswordResetEmail(email);

  Future<void> resendVerificationEmail() => _authService.sendEmailVerification();

  Future<void> signOut() async {
    await _authService.signOut();
    await exitDemoMode();
  }

  /// Enters demo mode: seeds local storage with realistic demo data if
  /// this is the first time, then flags demo mode as active.
  Future<UserModel> enterDemoMode() async {
    await _localStorage.setDemoMode(true);
    var user = await _localStorage.loadDemoUser();
    final existingTxns = await _localStorage.loadTransactions();
    if (user == null || existingTxns.isEmpty) {
      user = UserModel.demo();
      await _localStorage.saveDemoUser(user);
      await _localStorage.saveTransactions(DemoDataService.transactions());
      await _localStorage.saveBudgets(DemoDataService.budgets());
      await _localStorage.saveRecurring(DemoDataService.recurring());
      await _localStorage.saveCategories(DemoDataService.categories());
    }
    return user;
  }

  Future<void> exitDemoMode() async {
    await _localStorage.setDemoMode(false);
  }

  /// Clears and re-seeds demo data (used by "Clear Demo Data" in settings).
  Future<UserModel> resetDemoData() async {
    await _localStorage.clearDemoData();
    return enterDemoMode();
  }

  Future<bool> isDemoMode() => _localStorage.isDemoMode();
}
