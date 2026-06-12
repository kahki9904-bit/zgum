import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class DeviceAuthService {
  final _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Z:GUM에 접근하려면 인증이 필요합니다',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      // 기기 잠금 미설정 → 통과
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.passcodeNotSet ||
          e.code == auth_error.notEnrolled) {
        return true;
      }
      return false;
    } catch (_) {
      return true;
    }
  }
}
