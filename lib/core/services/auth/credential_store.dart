import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Username and password the user chose to keep on this device so the next
/// sign-in can go through Face ID / fingerprint instead of the keyboard.
///
/// Stored in the platform keychain / keystore via [FlutterSecureStorage].
/// Nothing here leaves the device; the biometric prompt only gates *reading*
/// the pair back, the actual authentication still happens against Auth0.
class CredentialStore {
  CredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _usernameKey = 'saved_login_username';
  static const _passwordKey = 'saved_login_password';
  static const _biometricKey = 'saved_login_biometric_enabled';

  Future<bool> get hasSavedCredentials async {
    final enabled = await _storage.read(key: _biometricKey);
    if (enabled != 'true') return false;
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);
    return username != null &&
        username.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  /// Username shown pre-filled on the login form, whether or not biometric
  /// sign-in is enabled.
  Future<String?> get savedUsername => _storage.read(key: _usernameKey);

  Future<SavedCredentials?> read() async {
    if (!await hasSavedCredentials) return null;
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);
    if (username == null || password == null) return null;
    return SavedCredentials(username: username, password: password);
  }

  Future<void> save({
    required String username,
    required String password,
  }) async {
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _passwordKey, value: password);
    await _storage.write(key: _biometricKey, value: 'true');
  }

  /// Keep the username for pre-fill but drop the password and the biometric
  /// opt-in. Used when the saved password stops working.
  Future<void> forgetPassword() async {
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _biometricKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _biometricKey);
  }
}

class SavedCredentials {
  const SavedCredentials({required this.username, required this.password});

  final String username;
  final String password;
}
