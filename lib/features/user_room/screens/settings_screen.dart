import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/popup_layout.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/email_recovery_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/dialogs/zgum_dialog.dart';
import '../../../promotions/free_use/free_use_settings_tile.dart';
// ignore: unused_import
import 'adult_verification_screen.dart';
import 'notification_setting_screen.dart';
import 'app_info_screen.dart';
import 'language_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final currentLangLabel = _kLanguages
        .firstWhere(
          (l) => l.code == currentLocale.languageCode,
          orElse: () => _kLanguages.first,
        )
        .label;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          context.l10n.settings,
          style: const TextStyle(
            color: AppColors.actionGoldText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // [본인인증 — 비활성화]
                    // 국내 결제·과금 연동 시 NICE/PASS 외부 본인인증으로 채울 자리.
                    // 그 전까지 UI 숨김. adult_verification_screen.dart는 그대로 유지.
                    // 과금 연동 후 이 주석 블록을 제거하면 즉시 복원됨.

                    _SettingRow(
                      icon: Icons.notifications_outlined,
                      label: context.l10n.settingNotifications,
                      onTap: () {
                        Navigator.push(
                          context,
                          Platform.isAndroid
                              ? CupertinoPageRoute(builder: (_) => const NotificationSettingScreen())
                              : MaterialPageRoute(builder: (_) => const NotificationSettingScreen()),
                        );
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 58),
                      child: _Rule(),
                    ),
                    _SettingRowWithTrail(
                      icon: Icons.language_outlined,
                      label: context.l10n.settingLanguage,
                      trailText: currentLangLabel,
                      onTap: () => Navigator.push(
                        context,
                        Platform.isAndroid
                            ? CupertinoPageRoute(builder: (_) => const LanguageScreen())
                            : MaterialPageRoute(builder: (_) => const LanguageScreen()),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 58),
                      child: _Rule(),
                    ),
                    _SettingRow(
                      icon: Icons.info_outline,
                      label: context.l10n.settingAppInfo,
                      onTap: () => Navigator.push(
                        context,
                        Platform.isAndroid
                            ? CupertinoPageRoute(builder: (_) => const AppInfoScreen())
                            : MaterialPageRoute(builder: (_) => const AppInfoScreen()),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 58),
                      child: _Rule(),
                    ),
                    _DataRecoverySettingRow(onTap: () => _showDataRecoveryDialog(context, ref)),
                    const Padding(
                      padding: EdgeInsets.only(left: 58),
                      child: _Rule(),
                    ),
                    _SettingRow(
                      icon: Icons.edit_note_outlined,
                      label: '문의 및 의견',
                      onTap: () => _showContactOpinionDialog(context),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 58),
                      child: _Rule(),
                    ),
                    const FreeUseSettingsTile(),
                    const Padding(
                      padding: EdgeInsets.only(left: 58),
                      child: _Rule(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showContactOpinionDialog(BuildContext context) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, _, __) {
      return GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: const _ContactOpinionDialog(),
          ),
        ),
      );
    },
  );
}

const _kLanguages = [
  _LangOption(code: 'ko', label: '한국어'),
  _LangOption(code: 'en', label: 'English'),
  _LangOption(code: 'ja', label: '日本語'),
  _LangOption(code: 'zh', label: '中文'),
];

class _LangOption {
  final String code;
  final String label;
  const _LangOption({required this.code, required this.label});
}

class _SettingRowWithTrail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String trailText;
  final VoidCallback onTap;

  const _SettingRowWithTrail({
    required this.icon,
    required this.label,
    required this.trailText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: const Color(0xFFAAAAAA)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                trailText,
                style: const TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: Color(0xFFDDDDDD), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: const Color(0xFFAAAAAA)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Color(0xFFDDDDDD), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactOpinionDialog extends StatefulWidget {
  const _ContactOpinionDialog();

  @override
  State<_ContactOpinionDialog> createState() => _ContactOpinionDialogState();
}

class _ContactOpinionDialogState extends State<_ContactOpinionDialog> {
  static const _items = [
    '서비스 이용 문의',
    '이벤트 등록 문의',
    '이벤트 삭제 요청',
    '오류 제보',
  ];

  final TextEditingController _controller = TextEditingController();
  int _selectedIndex = 0;
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await FirebaseFirestore.instance.collection('contact_opinions').add({
        'category': _items[_selectedIndex],
        'content': content,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() { _sending = false; _sent = true; });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZGumDialog(
      heightFactor: PopupLayoutSpec.current.introLongFactor,
      contentPadding: const EdgeInsets.fromLTRB(26, 30, 26, 0),
      actionsPadding: const EdgeInsets.fromLTRB(26, 14, 26, 26),
      actions: Row(
        children: [
          Expanded(
            child: ZGumButton(
              label: '닫기',
              onTap: () => Navigator.of(context).pop(),
              color: const Color(0xFFF1F1F2),
              textColor: const Color(0xFF777777),
              widthFactor: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ZGumButton(
              label: _sent ? '전송됨' : (_sending ? '전송 중...' : '보내기'),
              onTap: (_sending || _sent) ? () {} : _onSend,
              widthFactor: 1,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('문의 및 의견', style: ZGumDialogTextStyles.title),
          const SizedBox(height: 6),
          const Text(
            '확인이 필요한 내용을 운영자에게 보낼 수 있습니다.',
            style: ZGumDialogTextStyles.caption,
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 36,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              return _ContactChoiceChip(
                label: _items[index],
                selected: _selectedIndex == index,
                onTap: () => setState(() => _selectedIndex = index),
              );
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLength: 200,
            maxLines: 6,
            minLines: 6,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
            decoration: InputDecoration(
              hintText: '내용을 적어 주세요.',
              hintStyle: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 13,
              ),
              counterStyle: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
              filled: true,
              fillColor: const Color(0xFFF7F7F8),
              contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '서비스 확인과 개선을 위해 관련 앱 기록을 함께 확인할 수 있습니다.',
            style: ZGumDialogTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _ContactChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ContactChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.actionGoldSoft : const Color(0xFFF6F6F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.actionGoldBorder : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color:
                selected ? AppColors.actionGoldText : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: const Color(0xFFF0F0F0));
  }
}

// ── 데이터 복구 ────────────────────────────────────────────────────────────────

void _showDataRecoveryDialog(BuildContext context, WidgetRef ref) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, _, __) {
      return GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: const _DataRecoveryDialog(),
          ),
        ),
      );
    },
  );
}

class _DataRecoverySettingRow extends ConsumerWidget {
  final VoidCallback onTap;
  const _DataRecoverySettingRow({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(emailRecoveryStatusProvider);
    final isRegistered = status.valueOrNull == EmailRecoveryState.registered;
    final isPending = status.valueOrNull == EmailRecoveryState.pendingVerification;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_outlined, size: 17, color: Color(0xFFAAAAAA)),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  '데이터 복구',
                  style: TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isRegistered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.actionGoldSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.actionGoldBorder),
                  ),
                  child: const Text('등록됨', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.actionGoldText)),
                )
              else if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('인증 대기', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFAAAAAA))),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Color(0xFFDDDDDD), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataRecoveryDialog extends ConsumerStatefulWidget {
  const _DataRecoveryDialog();

  @override
  ConsumerState<_DataRecoveryDialog> createState() => _DataRecoveryDialogState();
}

class _DataRecoveryDialogState extends ConsumerState<_DataRecoveryDialog> {
  final _emailCtrl = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$').hasMatch(email);
  }

  Future<void> _onSend() async {
    final email = _emailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _errorText = '올바른 이메일 주소를 입력해 주세요.');
      return;
    }
    setState(() => _errorText = null);
    await ref.read(emailRecoveryStatusProvider.notifier).sendVerificationLink(email);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(emailRecoveryStatusProvider);
    final isLoading = status.isLoading;
    final isRegistered = status.valueOrNull == EmailRecoveryState.registered;
    final isPending = status.valueOrNull == EmailRecoveryState.pendingVerification;

    return ZGumDialog(
      heightFactor: PopupLayoutSpec.current.introLongFactor,
      contentPadding: const EdgeInsets.fromLTRB(26, 28, 26, 0),
      actionsPadding: const EdgeInsets.fromLTRB(26, 12, 26, 26),
      actions: Row(
        children: [
          Expanded(
            child: ZGumButton(
              label: '닫기',
              onTap: () => Navigator.of(context).pop(),
              color: const Color(0xFFF1F1F2),
              textColor: const Color(0xFF777777),
              widthFactor: 1,
            ),
          ),
          if (!isRegistered && !isPending) ...[
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ZGumButton(
                label: isLoading ? '전송 중...' : '이메일 등록',
                onTap: isLoading ? () {} : _onSend,
                widthFactor: 1,
              ),
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('데이터 복구', style: ZGumDialogTextStyles.title),
          const SizedBox(height: 8),
          const Text(
            '회원가입이 없는 앱 특성상 앱 삭제·기기 변경 시 기존 데이터를 보존할 수 없습니다. 사전에 이메일을 등록해두면 언제든 복구할 수 있습니다.',
            style: ZGumDialogTextStyles.caption,
          ),
          const SizedBox(height: 16),
          if (isRegistered) ...[
            const _StatusBox(
              icon: Icons.check_circle_outline,
              color: AppColors.actionGold,
              text: '이메일이 등록되었습니다.',
            ),
            const SizedBox(height: 10),
            FutureBuilder<String?>(
              future: ref.read(emailRecoveryStatusProvider.notifier).getStoredEmail(),
              builder: (_, snap) {
                final email = snap.data ?? '';
                return Text(email, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.actionGoldText));
              },
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => ref.read(emailRecoveryStatusProvider.notifier).clearRegistration(),
              child: const Text('등록 해제', style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA), decoration: TextDecoration.underline)),
            ),
          ] else if (isPending) ...[
            const _StatusBox(
              icon: Icons.mark_email_unread_outlined,
              color: Color(0xFFAAAAAA),
              text: '이메일을 확인해 주세요. 링크를 탭하면 등록이 완료됩니다.',
            ),
          ] else ...[
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              decoration: InputDecoration(
                hintText: '이메일 주소를 입력해 주세요.',
                hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
                errorText: _errorText,
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
            const Text(
              '등록 후 이메일로 링크가 발송됩니다. 링크를 한 번 탭하면 등록이 완료됩니다.',
              style: ZGumDialogTextStyles.caption,
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

  const _StatusBox({required this.icon, required this.color, required this.text});

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
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
