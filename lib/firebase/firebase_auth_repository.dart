// Firestore 연동 포인트: Firebase Auth (firebase_auth 패키지)
// 전환 시: server_transition_providers.dart 에서 MockAuthRepository → FirebaseAuthRepository 교체
import '../data/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  @override
  Future<String> getCurrentUserId() =>
      throw UnimplementedError('Firebase Auth 연동 후 구현');

  @override
  Future<bool> isIdentityVerified() =>
      throw UnimplementedError('Firebase Auth 연동 후 구현');

  @override
  Future<void> signInAnonymously() =>
      throw UnimplementedError('Firebase Auth 연동 후 구현');

  @override
  Future<void> refreshToken() =>
      throw UnimplementedError('Firebase Auth 연동 후 구현');

  @override
  Future<void> signOut() =>
      throw UnimplementedError('Firebase Auth 연동 후 구현');
}
