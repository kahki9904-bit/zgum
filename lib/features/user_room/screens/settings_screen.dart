import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/email_recovery_provider.dart';
import '../../../core/theme/app_colors.dart';
// ignore: unused_import
import 'adult_verification_screen.dart';
import 'notification_setting_screen.dart';
import 'app_info_screen.dart';
import 'language_screen.dart';
import 'popup_guide_screen.dart';
import 'data_recovery_screen.dart';
import 'contact_opinion_screen.dart';

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
                      icon: Icons.menu_book_outlined,
                      label: '지금설명서',
                      onTap: () => Navigator.push(
                        context,
                        _NoSwipeRoute(builder: (_) => const PopupGuideScreen()),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 58),
                      child: _Rule(),
                    ),
                    _SettingRow(
                      icon: Icons.notifications_outlined,
                      label: context.l10n.settingNotifications,
                      onTap: () => Navigator.push(
                        context,
                        _NoSwipeRoute(builder: (_) => const NotificationSettingScreen()),
                      ),
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
                        _NoSwipeRoute(builder: (_) => const LanguageScreen()),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 58),
                      child: _Rule(),
                    ),
                    _DataRecoverySettingRow(
                        onTap: () => Navigator.push(
                              context,
                              _NoSwipeRoute(
                                  builder: (_) => const DataRecoveryScreen()),
                            )),
                    const Padding(
                      padding: EdgeInsets.only(left: 58),
                      child: _Rule(),
                    ),
                    _SettingRow(
                      icon: Icons.edit_note_outlined,
                      label: '문의 및 의견',
                      onTap: () => Navigator.push(
                        context,
                        _NoSwipeRoute(
                            builder: (_) => const ContactOpinionScreen()),
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
                        _NoSwipeRoute(builder: (_) => const AppInfoScreen()),
                      ),
                    ),
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

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: const Color(0xFFF0F0F0));
  }
}

class _DataRecoverySettingRow extends ConsumerWidget {
  final VoidCallback onTap;
  const _DataRecoverySettingRow({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(emailRecoveryStatusProvider);
    final isRegistered = status.valueOrNull == EmailRecoveryState.registered;
    final isPending =
        status.valueOrNull == EmailRecoveryState.pendingVerification;

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
                child: const Icon(Icons.shield_outlined,
                    size: 17, color: Color(0xFFAAAAAA)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.actionGoldSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.actionGoldBorder),
                  ),
                  child: const Text('등록됨',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.actionGoldText)),
                )
              else if (isPending)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('인증 대기',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFAAAAAA))),
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

class _NoSwipeRoute<T> extends CupertinoPageRoute<T> {
  _NoSwipeRoute({required super.builder});

  @override
  bool get popGestureEnabled => false;
}
