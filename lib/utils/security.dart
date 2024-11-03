import 'package:bluecherry_client/utils/logging.dart';
import 'package:flutter/material.dart';
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

      return availableBiometrics.contains(BiometricType.weak) ||
          availableBiometrics.contains(BiometricType.strong);
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

  /// Asks for device authnetication.
  ///
  /// If the feature is not supported, it will fallback to true. It returns
  /// true because we don't want to block the user from using the app.
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
    return true;
  }

  static void showAccessDeniedMessage(BuildContext context) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Access denied',
          style: TextStyle(
            color: theme.colorScheme.onErrorContainer,
          ),
        ),
        width: 350,
        backgroundColor: theme.colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
