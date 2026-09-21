import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';

final authServiceProvider = Provider((ref) => AuthService());
final localStorageServiceProvider = Provider((ref) => LocalStorageService());

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(ref.watch(authServiceProvider), ref.watch(localStorageServiceProvider));
});

/// Overall session mode: signed out, demo, or authenticated.
enum SessionStatus { loading, unauthenticated, demo, authenticated }

class SessionState {
  final SessionStatus status;
  final UserModel? user;
  final String? errorMessage;

  const SessionState({required this.status, this.user, this.errorMessage});

  const SessionState.loading() : this(status: SessionStatus.loading);
  const SessionState.unauthenticated() : this(status: SessionStatus.unauthenticated);

  bool get isDemo => status == SessionStatus.demo;
  bool get isAuthenticated => status == SessionStatus.authenticated;
  String? get uid => isAuthenticated ? user?.uid : null;
}

class SessionNotifier extends StateNotifier<SessionState> {
  final AuthRepository _repo;

  SessionNotifier(this._repo) : super(const SessionState.loading()) {
    _init();
  }

  Future<void> _init() async {
    final demoActive = await _repo.isDemoMode();
    if (_repo.isAuthenticated) {
      state = SessionState(status: SessionStatus.authenticated, user: null);
    } else if (demoActive) {
      final demoUser = await _repo.enterDemoMode();
      state = SessionState(status: SessionStatus.demo, user: demoUser);
    } else {
      state = const SessionState.unauthenticated();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      final user = await _repo.signIn(email: email, password: password);
      await _repo.exitDemoMode();
      state = SessionState(status: SessionStatus.authenticated, user: user);
    } catch (e) {
      state = SessionState(status: state.status, user: state.user, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> register({required String name, required String email, required String password}) async {
    try {
      final user = await _repo.register(name: name, email: email, password: password);
      await _repo.exitDemoMode();
      state = SessionState(status: SessionStatus.authenticated, user: user);
    } catch (e) {
      state = SessionState(status: state.status, user: state.user, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> enterDemoMode() async {
    final user = await _repo.enterDemoMode();
    state = SessionState(status: SessionStatus.demo, user: user);
  }

  Future<void> resetDemoData() async {
    final user = await _repo.resetDemoData();
    state = SessionState(status: SessionStatus.demo, user: user);
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const SessionState.unauthenticated();
  }

  Future<void> sendPasswordReset(String email) => _repo.sendPasswordReset(email);
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref.watch(authRepositoryProvider));
});
