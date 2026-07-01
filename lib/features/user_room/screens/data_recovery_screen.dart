import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/email_recovery_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/dialogs/zgum_dialog.dart';

class DataRecoveryScreen extends ConsumerStatefulWidget {
  const DataRecoveryScreen({super.key});

  @override
  ConsumerState<DataRecoveryScreen> createState() => _DataRecoveryScreenState();
}

class _DataRecoveryScreenState extends ConsumerState<DataRecoveryScreen> {
  final _emailCtrl = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$').hasMatch(email);

  Future<void> _onSend() async {
    final email = _emailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _errorText = '올바른 이메일 주소를 입력해 주세요.');
      return;
    }
    setState(() => _errorText = null);
    await ref
        .read(emailRecoveryStatusProvider.notifier)
        .sendVerificationLink(email);
    if (!mounted) return;
    Navigator.of(context).pop();
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '회원가입이 없는 앱 특성상 앱 삭제·기기 변경 시 기존 데이터를 보존할 수 없습니다. 사전에 이메일을 등록해두면 언제든 복구할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isRegistered) ...[
                      _StatusBox(
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
                      _StatusBox(
                        icon: Icons.mark_email_unread_outlined,
                        color: const Color(0xFFAAAAAA),
                        text: '이메일을 확인해 주세요. 링크를 탭하면 등록이 완료됩니다.',
                      ),
                    ] else ...[
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF333333)),
                        decoration: InputDecoration(
                          hintText: '이메일 주소를 입력해 주세요.',
                          hintStyle: const TextStyle(
                              color: Color(0xFFBBBBBB), fontSize: 13),
                          errorText: _errorText,
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
                    ],
                  ],
                ),
              ),
            ),
            if (!isRegistered && !isPending)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: ZGumButton(
                  label: isLoading ? '전송 중...' : '이메일 등록',
                  onTap: isLoading ? () {} : _onSend,
                  widthFactor: 1,
                ),
              ),
          ],
        ),
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
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
