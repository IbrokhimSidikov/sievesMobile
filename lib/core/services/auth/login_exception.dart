/// Why a sign-in attempt failed. The UI maps each value to a localized
/// message; services never produce user-facing text.
enum LoginErrorType {
  /// Wrong username / email or password.
  invalidCredentials,

  /// No network, DNS failure, timeout.
  network,

  /// Auth0 rate-limited the account after repeated failures.
  tooManyAttempts,

  /// The account has MFA enrolled; the password grant cannot complete it.
  mfaRequired,

  /// Auth0 accepted the password but the backend has no identity for it.
  identityNotFound,

  /// The Auth0 application does not allow the password grant, or the realm
  /// name is wrong. A configuration problem, not a user problem.
  notConfigured,

  /// The refresh token expired while the app was in use.
  sessionExpired,

  unknown,
}

class LoginException implements Exception {
  const LoginException(this.type, [this.detail]);

  final LoginErrorType type;

  /// Raw provider message, for logs only.
  final String? detail;

  @override
  String toString() =>
      'LoginException(${type.name}${detail == null ? '' : ': $detail'})';
}
