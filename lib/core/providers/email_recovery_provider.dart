import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kEmailRecoveryPopupShown = 'email_recovery_popup_shown';
const _kEmailRecoveryAddress = 'email_recovery_address';          // 완료된 이메일만 저장
const _kRegisterPendingAddress = 'email_recovery_register_pending'; // 보존 임시 키
const _kEmailPendingVerification = 'email_recovery_pending';       // 보존 대기 플래그
const _kRecoveryPendingAddress = 'email_recovery_recovery_address'; // 복구 임시 키
const _kRecoveryPendingLink = 'email_recovery_recovery_link';      // 복구 링크 임시 키

// 등록된 적 없는 이메일로 복구 시도 시 발생
class RecoveryNoDataException implements Exception {
  const RecoveryNoDataException();
}

// 나의 방에서 팝업 표시 트리거
final emailRecoveryPromptProvider = StateProvider<bool>((ref) => false);

// 이메일 복구 등록 상태
final emailRecoveryStatusProvider =
    AsyncNotifierProvider<EmailRecoveryNotifier, EmailRecoveryState>(
  EmailRecoveryNotifier.new,
);

enum EmailRecoveryState {
  notRegistered,
  pendingVerification,
  registered,
}

class EmailRecoveryNotifier extends AsyncNotifier<EmailRecoveryState> {
  @override
  Future<EmailRecoveryState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kEmailRecoveryAddress);
    final pendingRegister = prefs.getString(_kRegisterPendingAddress);
    final isPending = prefs.getBool(_kEmailPendingVerification) ?? false;
    if (email != null) return EmailRecoveryState.registered;
    if (pendingRegister != null && isPending) return EmailRecoveryState.pendingVerification;
    return EmailRecoveryState.notRegistered;
  }

  // 완료된 이메일 반환
  Future<String?> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kEmailRecoveryAddress);
  }

  // 보존 대기 중인 이메일 반환
  Future<String?> getPendingRegisterEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRegisterPendingAddress);
  }

  // 복구 링크가 저장되어 있는지 확인
  Future<bool> hasPendingRecoveryLink() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRecoveryPendingLink) != null;
  }

  Future<void> sendVerificationLink(String email) async {
    state = const AsyncLoading();
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://zgum-6cc66.web.app/email-recovery',
        handleCodeInApp: true,
        androidPackageName: 'com.zgum.app',
        androidMinimumVersion: '21',
        iOSBundleId: 'com.zgum.app',
      );
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRegisterPendingAddress, email); // 임시 키에만 저장
      await prefs.setBool(_kEmailPendingVerification, true);
      state = const AsyncData(EmailRecoveryState.pendingVerification);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> clearRegistration() async {
    try {
      await FirebaseAuth.instance.currentUser?.unlink(EmailAuthProvider.PROVIDER_ID);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmailRecoveryAddress);
    await prefs.remove(_kRegisterPendingAddress);
    await prefs.remove(_kEmailPendingVerification);
    state = const AsyncData(EmailRecoveryState.notRegistered);
  }

  Future<void> sendRecoveryLink(String email) async {
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://zgum-6cc66.web.app/email-recovery',
      handleCodeInApp: true,
      androidPackageName: 'com.zgum.app',
      androidMinimumVersion: '21',
      iOSBundleId: 'com.zgum.app',
    );
    await FirebaseAuth.instance.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRecoveryPendingAddress, email);
  }

  Future<String?> getPendingRecoveryEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRecoveryPendingAddress);
  }

  // 사용자가 "복구하기" 버튼을 누른 후 실제 복구 처리
  Future<String> confirmRecovery() async {
    state = const AsyncLoading();
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kRecoveryPendingAddress);
    final link = prefs.getString(_kRecoveryPendingLink);

    if (email == null || link == null) {
      state = const AsyncData(EmailRecoveryState.notRegistered);
      throw const RecoveryNoDataException();
    }

    try {
      final credential = EmailAuthProvider.credentialWithLink(
        email: email,
        emailLink: link,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(credential);

      if (result.additionalUserInfo?.isNewUser == true) {
        // 등록된 적 없는 이메일 — 새 계정 삭제 후 익명 복귀
        try { await FirebaseAuth.instance.currentUser?.delete(); } catch (_) {}
        await FirebaseAuth.instance.signInAnonymously();
        await prefs.remove(_kRecoveryPendingAddress);
        await prefs.remove(_kRecoveryPendingLink);
        state = const AsyncData(EmailRecoveryState.notRegistered);
        throw const RecoveryNoDataException();
      }

      // 정상 복구 완료 — 확인된 이메일만 저장
      await prefs.setString(_kEmailRecoveryAddress, email);
      await prefs.setBool(_kEmailPendingVerification, false);
      await prefs.remove(_kRecoveryPendingAddress);
      await prefs.remove(_kRecoveryPendingLink);
      state = const AsyncData(EmailRecoveryState.registered);
      return email;
    } on RecoveryNoDataException {
      rethrow;
    } catch (e) {
      // 링크 만료 등 기타 오류 — 임시 키 정리
      await prefs.remove(_kRecoveryPendingAddress);
      await prefs.remove(_kRecoveryPendingLink);
      state = const AsyncData(EmailRecoveryState.notRegistered);
      throw const RecoveryNoDataException();
    }
  }
}

// 팝업 표시 여부 확인/설정
Future<bool> isEmailRecoveryPopupShown() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kEmailRecoveryPopupShown) ?? false;
}

Future<void> markEmailRecoveryPopupShown() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kEmailRecoveryPopupShown, true);
}
