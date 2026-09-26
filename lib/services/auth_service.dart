import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user_model.dart';
import 'api_client.dart';

/// Identity (sign-up/sign-in/password reset/email verification) is
/// handled entirely by Firebase Auth. Everything else about the user
/// (display name, currency, avatar, settings) lives in the Node/MongoDB
/// backend, keyed by the Firebase uid — see FirestoreService and
/// expenseflow-backend/. This class is the seam between the two: it
/// drives FirebaseAuth for sign-in/out, and syncs the resulting profile
/// from the backend (creating it there on first sign-in) so the rest of
/// the app has a UserModel to work with, same as before.
class AuthService {
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final ApiClient _api = ApiClient.instance;

  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;

  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();

  fb.User? get currentUser => _auth.currentUser;

  Future<UserModel> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    return _syncProfile(credential.user!);
  }

  Future<UserModel> register({required String name, required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = credential.user!;
    await user.updateDisplayName(name.trim());

    // The backend creates its MongoDB profile document from the ID token
    // claims on first authenticated call (see expenseflow-backend
    // middleware/auth.js) — those claims may still reflect the
    // pre-updateDisplayName state on this very first token, so explicitly
    // push the chosen name too, to guarantee it's right immediately.
    await _syncProfile(user);
    await _api.patch('/api/users/me', {'name': name.trim()});
    _currentUserModel = _currentUserModel!.copyWith(name: name.trim());
    return _currentUserModel!;
  }

  Future<void> sendPasswordResetEmail(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Requires the user to have signed in recently; Firebase throws
  /// `requires-recent-login` otherwise — surface that to the UI so it can
  /// prompt a re-authentication if you wire that flow in later.
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUserModel = null;
  }

  /// Fetches (and, on first sign-in, creates) this user's MongoDB profile
  /// document from the backend. Call after any Firebase auth state change
  /// that should refresh app data — sign-in, register, and app startup.
  Future<UserModel> _syncProfile(fb.User firebaseUser) async {
    final data = await _api.get('/api/auth/me');
    final model = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    _currentUserModel = model;
    return model;
  }

  /// Call once at app startup (before or after runApp — Firebase restores
  /// its own session automatically). If a session is already active,
  /// syncs the MongoDB profile so it's ready before the first frame that
  /// needs it.
  Future<void> init() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _syncProfile(user);
    } catch (_) {
      // Backend unreachable or token invalid — leave _currentUserModel
      // null; screens that need it will retry the fetch themselves.
    }
  }
}
