import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/auth_repository.dart';
import '../services/device_id_service.dart';

class MockAuthRepository implements AuthRepository {
  static const _verifiedKey = 'zgum_mock_identity_verified';

  @override
  Future<String> getCurrentUserId() => DeviceIdService.getId();

  @override
  Future<bool> isIdentityVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_verifiedKey) ?? false;
  }

  @override
  Future<void> signInAnonymously() async {
    await DeviceIdService.getId();
  }

  @override
  Future<void> refreshToken() async {}

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_verifiedKey);
  }
}
