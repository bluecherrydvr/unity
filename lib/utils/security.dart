import 'package:bluecherry_client/utils/logging.dart';
import 'package:local_auth/local_auth.dart';

class UnityAuth {
  const UnityAuth._();

  static final auth = LocalAuthentication();

  static Future<bool> canAuthenticate() async {
    try {
      final canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      if (!canAuthenticate) return false;

      final availableBiometrics = await auth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return false;
      }

      return availableBiometrics.contains(BiometricType.weak);
    } on UnimplementedError {
      return false;
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace,
        'Error checking biometrics support',
      );
      return false;
    }
  }

  static Future<bool> ask([String? reason]) async {
    if (await canAuthenticate()) {
      try {
        return await auth.authenticate(
          localizedReason: reason ?? 'Please authenticate to continue',
        );
      } catch (error, stackTrace) {
        handleError(
          error,
          stackTrace,
          'Error authenticating with biometrics',
        );
        return false;
      }
    }
    return false;
  }
}
