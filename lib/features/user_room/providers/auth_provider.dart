import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum IdentityVerificationStatus {
  notVerified,
  adminVerified, // 관리자 수동 인증 (SDK 연동 전 임시)
  sdkVerified,   // 외부 SDK 인증 (추후 연동)
}

class AuthState {
  final IdentityVerificationStatus identityStatus;

  const AuthState({
    this.identityStatus = IdentityVerificationStatus.notVerified,
  });

  bool get isIdentityVerified =>
      identityStatus != IdentityVerificationStatus.notVerified;
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  static const _key = 'zgum_identity_status';

  AuthStateNotifier() : super(const AuthState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == IdentityVerificationStatus.adminVerified.name) {
      state = const AuthState(identityStatus: IdentityVerificationStatus.adminVerified);
    } else if (saved == IdentityVerificationStatus.sdkVerified.name) {
      state = const AuthState(identityStatus: IdentityVerificationStatus.sdkVerified);
    }
  }

  // 관리자 수동 인증 — 외부 SDK 연동 전까지 사용
  Future<void> adminVerify() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, IdentityVerificationStatus.adminVerified.name);
    state = const AuthState(identityStatus: IdentityVerificationStatus.adminVerified);
  }

  // 외부 SDK 인증 완료 시 호출
  Future<void> sdkVerify() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, IdentityVerificationStatus.sdkVerified.name);
    state = const AuthState(identityStatus: IdentityVerificationStatus.sdkVerified);
  }

  // 인증 초기화 (설정에서 직접 리셋할 경우 사용)
  Future<void> resetVerification() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = const AuthState();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>(
  (ref) => AuthStateNotifier(),
);
