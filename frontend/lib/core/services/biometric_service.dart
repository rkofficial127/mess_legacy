import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

const _storage = FlutterSecureStorage();
const _key = 'biometric_enabled';

class BiometricService {
  final _auth = LocalAuthentication();

  /// Check if device supports biometrics
  Future<bool> get isAvailable async {
    // Not available on web
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Get available biometric types (fingerprint, face, etc.)
  Future<List<BiometricType>> get availableTypes async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Check if user has enabled biometric lock
  Future<bool> get isEnabled async {
    final val = await _storage.read(key: _key);
    return val == 'true';
  }

  /// Enable/disable biometric lock
  Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _key, value: enabled ? 'true' : 'false');
  }

  /// Prompt for biometric authentication
  Future<bool> authenticate({String reason = 'Unlock Mess 101'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern fallback
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>((_) {
  return BiometricService();
});
