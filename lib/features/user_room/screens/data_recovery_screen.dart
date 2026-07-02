import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/email_recovery_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/deep_link_notifier.dart';
import '../../../presentation/widgets/dialogs/zgum_dialog.dart';
import '../providers/check_in_provider.dart';

class DataRecoveryScreen extends ConsumerStatefulWidget {
  const DataRecoveryScreen({super.key});

  @override
  ConsumerState<DataRecoveryScreen> createState() => _DataRecoveryScreenState();
}

class _DataRecoveryScreenState extends ConsumerState<DataRecoveryScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  StreamSubscription<void>? _authSub;
  StreamSubscription<String>? _authErrSub;
  StreamSubscription<String>? _recoveryConfirmSub;

  // 보존 탭 상태
  final _registerEmailCtrl = TextEditingController();
  String? _registerError;
  bool _registerResending = false;
  bool _registerDuplicate = false;         // 이 기기에 등록된 이메일
  bool _alreadyRegisteredElsewhere = false; // 다른 기기에 등록된 이메일
  String? _registerCompletedEmail;          // 등록 완료 메시지용
  String? _storedEmail;                     // 현재 등록된 이메일 (힌트용)

  // 복구 탭 상태
  final _recoveryEmailCtrl = TextEditingController();
  String? _recoveryError;
  bool _recoveryPending = false;
  bool _recoverySending = false;
  bool _recoveryResending = false;
  bool _recoveryDuplicate = false;         // 이 기기에 등록된 이메일
  bool _recoveryNoData = false;            // 등록된 적 없는 이메일
  String? _recoveryConfirmationEmail;      // 다른 기기 복구 확인 대기
  String? _recoveryCompletedEmail;         // 복구 완료 메시지용

  @override
  void initState() {
    super.initState();

    // 보존 등록 완료 신호
    _authSub = emailAuthCompletedController.stream.listen((_) async {
      if (!mounted) return;
      final email = await ref
          .read(emailRecoveryStatusProvider.notifier)
          .getStoredEmail();
      if (!mounted) return;
      ref.invalidate(emailRecoveryStatusProvider);
      setState(() {
        _registerCompletedEmail = email;
        _storedEmail = email;
      });
    });

    // 오류 신호 (다른 기기 등록 이메일, 복구 데이터 없음)
    _authErrSub = emailAuthErrorController.stream.listen((code) {
      if (!mounted) return;
      if (code == 'already-registered') {
        setState(() {
          _alreadyRegisteredElsewhere = true;
          _registerResending = false;
        });
        ref.invalidate(emailRecoveryStatusProvider);
      } else if (code == 'recovery-no-data') {
        setState(() {
          _recoveryNoData = true;
          _recoveryConfirmationEmail = null;
        });
      }
    });

    // 복구 링크 수신 — 사용자 확인 대기
    _recoveryConfirmSub =
        emailRecoveryConfirmationController.stream.listen((email) {
      if (!mounted) return;
      setState(() {
        _recoveryConfirmationEmail = email;
        _recoveryPending = false;
      });
    });

    _restorePendingRecovery();
    _loadStoredEmail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(emailRecoveryStatusProvider);
    });
  }

  Future<void> _loadStoredEmail() async {
    final email = await ref
        .read(emailRecoveryStatusProvider.notifier)
        .getStoredEmail();
    if (mounted) setState(() => _storedEmail = email);
  }

  Future<void> _restorePendingRecovery() async {
    final email = await ref
        .read(emailRecoveryStatusProvider.notifier)
        .getPendingRecoveryEmail();
    if (email == null || !mounted) return;

    final hasLink = await ref
        .read(emailRecoveryStatusProvider.notifier)
        .hasPendingRecoveryLink();
    if (!mounted) return;

    if (hasLink) {
      setState(() => _recoveryConfirmationEmail = email);
    } else {
      _recoveryEmailCtrl.text = email;
      setState(() => _recoveryPending = true);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _authErrSub?.cancel();
    _recoveryConfirmSub?.cancel();
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

    // 이 기기에 이미 등록된 이메일 확인
    final stored = await ref
        .read(emailRecoveryStatusProvider.notifier)
        .getStoredEmail();
    if (stored != null && stored == email) {
      setState(() => _registerDuplicate = true);
      return;
    }

    setState(() {
      _registerError = null;
      _registerDuplicate = false;
      _alreadyRegisteredElsewhere = false;
    });
    await ref
        .read(emailRecoveryStatusProvider.notifier)
        .sendVerificationLink(email);
  }

  Future<void> _onResend() async {
    final email = await ref
        .read(emailRecoveryStatusProvider.notifier)
        .getPendingRegisterEmail();
    if (email == null || !mounted) return;
    setState(() => _registerResending = true);
    await ref
        .read(emailRecoveryStatusProvider.notifier)
        .sendVerificationLink(email);
    if (mounted) setState(() => _registerResending = false);
  }

  Future<void> _onRecover() async {
    final email = _recoveryEmailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _recoveryError = '올바른 이메일 주소를 입력해 주세요.');
      return;
    }

    // 이 기기에 이미 등록된 이메일 확인
    final stored = await ref
        .read(emailRecoveryStatusProvider.notifier)
        .getStoredEmail();
    if (stored != null && stored == email) {
      setState(() {
        _recoveryDuplicate = true;
        _recoverySending = false;
      });
      return;
    }

    setState(() {
      _recoveryError = null;
      _recoveryDuplicate = false;
      _recoveryNoData = false;
      _recoverySending = true;
    });
    try {
      await ref
          .read(emailRecoveryStatusProvider.notifier)
          .sendRecoveryLink(email);
      if (mounted) {
        setState(() {
          _recoveryPending = true;
          _recoverySending = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _recoverySending = false);
    }
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

  Future<void> _onConfirmRecovery() async {
    try {
      final email = await ref
          .read(emailRecoveryStatusProvider.notifier)
          .confirmRecovery();
      if (!mounted) return;
      ref.invalidate(checkInProvider);
      setState(() {
        _recoveryCompletedEmail = email;
        _recoveryConfirmationEmail = null;
      });
    } on RecoveryNoDataException {
      if (!mounted) return;
      setState(() {
        _recoveryNoData = true;
        _recoveryConfirmationEmail = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recoveryNoData = true;
        _recoveryConfirmationEmail = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(emailRecoveryStatusProvider);
    final isLoading = status.isLoading;
    final isPending =
        status.valueOrNull == EmailRecoveryState.pendingVerification;

    // 다른 기기가 가져간 경우 힌트 텍스트 초기화
    ref.listen(emailRecoveryStatusProvider, (_, next) {
      if (next.valueOrNull == EmailRecoveryState.notRegistered && _storedEmail != null) {
        setState(() => _storedEmail = null);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.actionGoldText),
        title: const Text(
          '데이터 관리',
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
                  _buildPreservePage(isLoading, isPending),
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

  Widget _buildPreservePage(bool isLoading, bool isPending) {
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
          if (_registerCompletedEmail != null) ...[
            _StatusBox(
              icon: Icons.check_circle_outline,
              color: AppColors.actionGold,
              text: '$_registerCompletedEmail 으로 등록되었습니다.',
            ),
          ] else if (isPending) ...[
            FutureBuilder<String?>(
              future: ref
                  .read(emailRecoveryStatusProvider.notifier)
                  .getPendingRegisterEmail(),
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
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              onChanged: (_) {
                if (_registerDuplicate || _alreadyRegisteredElsewhere) {
                  setState(() {
                    _registerDuplicate = false;
                    _alreadyRegisteredElsewhere = false;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: _storedEmail != null
                    ? '✓ $_storedEmail'
                    : '이메일 주소를 입력해 주세요.',
                hintStyle:
                    const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
                errorText: _registerError,
                filled: true,
                fillColor: const Color(0xFFF7F7F8),
                contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_alreadyRegisteredElsewhere) ...[
              const _StatusBox(
                icon: Icons.info_outline,
                color: Color(0xFFB87A00),
                text: '이미 다른 기기에 등록된 이메일입니다.\n복구 탭에서 이메일을 입력해 주세요.',
              ),
            ] else if (_registerDuplicate) ...[
              const _StatusBox(
                icon: Icons.info_outline,
                color: Color(0xFFAAAAAA),
                text: '이미 이 기기에 등록된 이메일입니다.',
              ),
            ] else ...[
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
          if (_recoveryCompletedEmail != null) ...[
            _StatusBox(
              icon: Icons.check_circle_outline,
              color: AppColors.actionGold,
              text: '$_recoveryCompletedEmail 으로 복구되었습니다.',
            ),
          ] else if (_recoveryConfirmationEmail != null) ...[
            _StatusBox(
              icon: Icons.info_outline,
              color: const Color(0xFFB87A00),
              text: '$_recoveryConfirmationEmail\n다른 기기에 이미 등록되어 있습니다.',
            ),
            const SizedBox(height: 16),
            ZGumButton(
              label: '복구하기',
              onTap: _onConfirmRecovery,
              widthFactor: 1,
            ),
          ] else if (_recoveryPending) ...[
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
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              onChanged: (_) {
                if (_recoveryDuplicate || _recoveryNoData) {
                  setState(() {
                    _recoveryDuplicate = false;
                    _recoveryNoData = false;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: '이메일 주소를 입력해 주세요.',
                hintStyle:
                    const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
                errorText: _recoveryError,
                filled: true,
                fillColor: const Color(0xFFF7F7F8),
                contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_recoveryDuplicate) ...[
              const _StatusBox(
                icon: Icons.info_outline,
                color: Color(0xFFAAAAAA),
                text: '이미 이 기기에 등록된 이메일입니다.',
              ),
            ] else if (_recoveryNoData) ...[
              const _StatusBox(
                icon: Icons.info_outline,
                color: Color(0xFFAAAAAA),
                text: '이 이메일로 복구할 데이터가 없습니다.\n이메일을 다시 확인해 주세요.',
              ),
            ] else ...[
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
                label: _recoverySending ? '전송 중...' : '이 기기로 가져오기',
                onTap: _recoverySending ? () {} : _onRecover,
                widthFactor: 1,
              ),
            ],
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
