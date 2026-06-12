abstract class AuthRepository {
  Future<String> getCurrentUserId();
  Future<bool> isIdentityVerified();
  Future<void> signInAnonymously();
  Future<void> refreshToken();
  Future<void> signOut();
}
