import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kEmailRecoveryPopupShown = 'email_recovery_popup_shown';
const _kEmailRecoveryAddress = 'email_recovery_address';
const _kEmailPendingVerification = 'email_recovery_pending';
const _kRecoveryPendingAddress = 'email_recovery_recovery_address';

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
    final pending = prefs.getBool(_kEmailPendingVerification) ?? false;
    if (email != null && !pending) return EmailRecoveryState.registered;
    if (pending) return EmailRecoveryState.pendingVerification;
    return EmailRecoveryState.notRegistered;
  }

  String? get registeredEmail {
    final prefs = state.valueOrNull;
    return prefs == EmailRecoveryState.registered ? _cachedEmail : null;
  }

  String? _cachedEmail;

  Future<String?> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kEmailRecoveryAddress);
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
      await prefs.setString(_kEmailRecoveryAddress, email);
      await prefs.setBool(_kEmailPendingVerification, true);
      _cachedEmail = email;
      state = const AsyncData(EmailRecoveryState.pendingVerification);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> completeVerification(String email, String emailLink) async {
    state = const AsyncLoading();
    try {
      final credential = EmailAuthProvider.credentialWithLink(
        email: email,
        emailLink: emailLink,
      );
      await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kEmailRecoveryAddress, email);
      await prefs.setBool(_kEmailPendingVerification, false);
      _cachedEmail = email;
      state = const AsyncData(EmailRecoveryState.registered);
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
    await prefs.remove(_kEmailPendingVerification);
    _cachedEmail = null;
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

  Future<void> completeRecovery(String email, String emailLink) async {
    state = const AsyncLoading();
    try {
      final credential = EmailAuthProvider.credentialWithLink(
        email: email,
        emailLink: emailLink,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kEmailRecoveryAddress, email);
      await prefs.setBool(_kEmailPendingVerification, false);
      await prefs.remove(_kRecoveryPendingAddress);
      _cachedEmail = email;
      state = const AsyncData(EmailRecoveryState.registered);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
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
