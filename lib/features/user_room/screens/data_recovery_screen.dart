import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/email_recovery_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/deep_link_notifier.dart';
import '../../../presentation/widgets/dialogs/zgum_dialog.dart';

class DataRecoveryScreen extends ConsumerStatefulWidget {
  const DataRecoveryScreen({super.key});

  @override
  ConsumerState<DataRecoveryScreen> createState() => _DataRecoveryScreenState();
}

class _DataRecoveryScreenState extends ConsumerState<DataRecoveryScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  StreamSubscription<void>? _authSub;

  // 데이터 보존
  final _registerEmailCtrl = TextEditingController();
  String? _registerError;
  bool _registerResending = false;

  // 데이터 복구
  final _recoveryEmailCtrl = TextEditingController();
  String? _recoveryError;
  bool _recoveryPending = false;
  bool _recoverySending = false;
  bool _recoveryResending = false;

  @override
  void initState() {
    super.initState();
    _authSub = emailAuthCompletedController.stream.listen((_) {
      if (mounted) ref.invalidate(emailRecoveryStatusProvider);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _pageCtrl.dispose();
    _registerEmailCtrl.dispose();
    _recoveryEmailCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$').hasMatch(email);

  Future<void> _onRegister() async {
    final email = _registerEmailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _registerError = '올바른 이메일 주소를 입력해 주세요.');
      return;
    }
    setState(() => _registerError = null);
    await ref
        .read(emailRecoveryStatusProvider.notifier)
        .sendVerificationLink(email);
  }

  Future<void> _onResend() async {
    final email = await ref
        .read(emailRecoveryStatusProvider.notifier)
        .getStoredEmail();
    if (email == null || !mounted) return;
    setState(() => _registerResending = true);
    await ref
        .read(emailRecoveryStatusProvider.notifier)
        .sendVerificationLink(email);
    if (mounted) setState(() => _registerResending = false);
  }

  Future<void> _onRecoveryResend() async {
    final email = _recoveryEmailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _recoveryResending = true);
    try {
      await ref
          .read(emailRecoveryStatusProvider.notifier)
          .sendRecoveryLink(email);
    } catch (_) {}
    if (mounted) setState(() => _recoveryResending = false);
  }

  Future<void> _onRecover() async {
    final email = _recoveryEmailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _recoveryError = '올바른 이메일 주소를 입력해 주세요.');
      return;
    }
    setState(() {
      _recoveryError = null;
      _recoverySending = true;
    });
    try {
      await ref
          .read(emailRecoveryStatusProvider.notifier)
          .sendRecoveryLink(email);
      if (mounted) setState(() { _recoveryPending = true; _recoverySending = false; });
    } catch (_) {
      if (mounted) setState(() => _recoverySending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(emailRecoveryStatusProvider);
    final isLoading = status.isLoading;
    final isRegistered = status.valueOrNull == EmailRecoveryState.registered;
    final isPending =
        status.valueOrNull == EmailRecoveryState.pendingVerification;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.actionGoldText),
        title: const Text(
          '데이터 복구',
          style: TextStyle(
            color: AppColors.actionGoldText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _buildPreservePage(isLoading, isRegistered, isPending),
                  _buildRecoveryPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  2,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AppColors.actionGoldBright
                          : const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreservePage(
      bool isLoading, bool isRegistered, bool isPending) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '데이터 보존',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.actionGoldText,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '사전에 이메일을 등록해두면 기기 변경 시 데이터를 복구할 수 있습니다.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF888888),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          if (isRegistered) ...[
            const _StatusBox(
              icon: Icons.check_circle_outline,
              color: AppColors.actionGold,
              text: '이메일이 등록되었습니다.',
            ),
            const SizedBox(height: 12),
            FutureBuilder<String?>(
              future: ref
                  .read(emailRecoveryStatusProvider.notifier)
                  .getStoredEmail(),
              builder: (_, snap) {
                final email = snap.data ?? '';
                return Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.actionGoldText,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => ref
                  .read(emailRecoveryStatusProvider.notifier)
                  .clearRegistration(),
              child: const Text(
                '등록 해제',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFAAAAAA),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ] else if (isPending) ...[
            FutureBuilder<String?>(
              future: ref
                  .read(emailRecoveryStatusProvider.notifier)
                  .getStoredEmail(),
              builder: (_, snap) {
                final email = snap.data;
                return _StatusBox(
                  icon: Icons.mark_email_unread_outlined,
                  color: const Color(0xFFAAAAAA),
                  text: email != null && email.isNotEmpty
                      ? '$email 으로 이메일을 보냈습니다.\n링크를 탭하면 등록이 완료됩니다.'
                      : '이메일을 확인해 주세요. 링크를 탭하면 등록이 완료됩니다.',
                );
              },
            ),
            const SizedBox(height: 16),
            ZGumButton(
              label: _registerResending ? '전송 중...' : '링크 재발송',
              onTap: _registerResending ? () {} : _onResend,
              widthFactor: 1,
            ),
          ] else ...[
            TextField(
              controller: _registerEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF333333)),
              decoration: InputDecoration(
                hintText: '이메일 주소를 입력해 주세요.',
                hintStyle: const TextStyle(
                    color: Color(0xFFBBBBBB), fontSize: 13),
                errorText: _registerError,
                filled: true,
                fillColor: const Color(0xFFF7F7F8),
                contentPadding:
                    const EdgeInsets.fromLTRB(14, 12, 14, 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '등록 후 이메일로 링크가 발송됩니다. 링크를 한 번 탭하면 등록이 완료됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),
            ZGumButton(
              label: isLoading ? '전송 중...' : '이메일 등록',
              onTap: isLoading ? () {} : _onRegister,
              widthFactor: 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecoveryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '데이터 복구',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.actionGoldText,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '이전 기기에서 등록한 이메일로 데이터를 복구합니다.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF888888),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          if (_recoveryPending) ...[
            _StatusBox(
              icon: Icons.mark_email_unread_outlined,
              color: const Color(0xFFAAAAAA),
              text: _recoveryEmailCtrl.text.isNotEmpty
                  ? '${_recoveryEmailCtrl.text} 으로 이메일을 보냈습니다.\n링크를 탭하면 복구가 완료됩니다.'
                  : '이메일을 확인해 주세요. 링크를 탭하면 복구가 완료됩니다.',
            ),
            const SizedBox(height: 16),
            ZGumButton(
              label: _recoveryResending ? '전송 중...' : '링크 재발송',
              onTap: _recoveryResending ? () {} : _onRecoveryResend,
              widthFactor: 1,
            ),
          ] else ...[
            TextField(
              controller: _recoveryEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF333333)),
              decoration: InputDecoration(
                hintText: '이메일 주소를 입력해 주세요.',
                hintStyle: const TextStyle(
                    color: Color(0xFFBBBBBB), fontSize: 13),
                errorText: _recoveryError,
                filled: true,
                fillColor: const Color(0xFFF7F7F8),
                contentPadding:
                    const EdgeInsets.fromLTRB(14, 12, 14, 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '이메일로 복구 링크가 발송됩니다. 링크를 한 번 탭하면 복구가 완료됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),
            ZGumButton(
              label: _recoverySending ? '전송 중...' : '이메일로 복구하기',
              onTap: _recoverySending ? () {} : _onRecover,
              widthFactor: 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _StatusBox(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
