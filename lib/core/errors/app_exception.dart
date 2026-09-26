/// Uniform exception type surfaced to the UI, so widgets never need to
/// know whether an error came from the backend API or local storage.
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Maps auth error codes to friendly, user-facing copy. The backend
/// already returns a friendly `message` for every error (see
/// ApiClient._handle), so this is mainly kept as a fallback/reference for
/// any locally-thrown AppException that only sets a `code`.
class AuthErrorMapper {
  AuthErrorMapper._();

  static String friendlyMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
