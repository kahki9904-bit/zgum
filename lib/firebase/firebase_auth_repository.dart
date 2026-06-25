import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Future<String> getCurrentUserId() async {
    final user = _auth.currentUser;
    if (user != null) return user.uid;
    final result = await _auth.signInAnonymously();
    return result.user!.uid;
  }

  @override
  Future<bool> isIdentityVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return !user.isAnonymous;
  }

  @override
  Future<void> signInAnonymously() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  @override
  Future<void> refreshToken() async {
    await _auth.currentUser?.getIdToken(true);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
