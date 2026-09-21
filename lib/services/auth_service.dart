import 'package:firebase_auth/firebase_auth.dart';
import '../core/errors/app_exception.dart';
import '../models/user_model.dart';

/// Thin wrapper over FirebaseAuth. UI and providers never call
/// firebase_auth directly — everything routes through here so the rest
/// of the app is testable and Firebase-agnostic.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return _toUserModel(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw AppException(AuthErrorMapper.friendlyMessage(e.code), code: e.code);
    }
  }

  Future<UserModel> register({required String name, required String email, required String password}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      await cred.user?.updateDisplayName(name);
      await cred.user?.sendEmailVerification();
      return _toUserModel(cred.user!, nameOverride: name);
    } on FirebaseAuthException catch (e) {
      throw AppException(AuthErrorMapper.friendlyMessage(e.code), code: e.code);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AppException(AuthErrorMapper.friendlyMessage(e.code), code: e.code);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AppException(AuthErrorMapper.friendlyMessage(e.code), code: e.code);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AppException(AuthErrorMapper.friendlyMessage(e.code), code: e.code);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  UserModel _toUserModel(User user, {String? nameOverride}) {
    return UserModel(
      uid: user.uid,
      name: nameOverride ?? user.displayName ?? user.email?.split('@').first ?? 'User',
      email: user.email ?? '',
      isDemo: false,
      emailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      avatarUrl: user.photoURL,
    );
  }
}
