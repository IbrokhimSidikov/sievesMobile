import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// What the device can present to the user.
enum BiometricKind { face, fingerprint, generic }

/// Thin wrapper around `local_auth` so the login page never touches platform
/// specifics.
class BiometricService {
  BiometricService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// True when the device can show a local authentication prompt: an
  /// enrolled biometric, or (because the prompt falls back to it) a passcode.
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      final enrolled = await _auth.getAvailableBiometrics();
      print(
        '🔐 [Biometrics] supported=$supported canCheck=$canCheck enrolled=$enrolled',
      );
      return supported || canCheck || enrolled.isNotEmpty;
    } on PlatformException catch (e) {
      print(
        '🔐 [Biometrics] availability check failed: ${e.code} ${e.message}',
      );
      return false;
    }
  }

  /// Best label for the prompt: Face ID on a Face ID iPhone, fingerprint on
  /// most Android phones.
  Future<BiometricKind> kind() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return BiometricKind.face;
      if (types.contains(BiometricType.fingerprint)) {
        return BiometricKind.fingerprint;
      }
      // Android often reports only `strong` / `weak`; those are fingerprint
      // readers on the overwhelming majority of devices.
      if (types.contains(BiometricType.strong) ||
          types.contains(BiometricType.weak)) {
        return BiometricKind.fingerprint;
      }
      return BiometricKind.generic;
    } on PlatformException {
      return BiometricKind.generic;
    }
  }

  /// Shows the system prompt. Returns false when the user cancels, fails, or
  /// the platform refuses (locked out, no enrollment, …).
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // Fall back to the device passcode after repeated biometric failures
        // instead of dead-ending the user.
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      print('🔐 [Biometrics] authenticate failed: ${e.code} ${e.message}');
      return false;
    }
  }
}
