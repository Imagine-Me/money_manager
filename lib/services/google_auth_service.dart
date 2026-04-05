import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  static const _driveAppdataScope =
      'https://www.googleapis.com/auth/drive.appdata';

  final _client = GoogleSignIn(scopes: [_driveAppdataScope]);

  GoogleSignInAccount? get currentUser => _client.currentUser;

  /// Opens the Google sign-in consent screen.
  Future<GoogleSignInAccount?> signIn() => _client.signIn();

  /// Tries to restore a previous session without showing UI.
  Future<GoogleSignInAccount?> signInSilently() =>
      _client.signInSilently(suppressErrors: true);

  /// Clears the current session.
  Future<void> signOut() => _client.signOut();

  /// Returns auth headers for the current account, or null if not signed in.
  /// Handles token refresh automatically.
  Future<Map<String, String>?> getAuthHeaders() async {
    final account = _client.currentUser;
    if (account == null) return null;
    return account.authHeaders;
  }
}
