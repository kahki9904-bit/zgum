import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/free_use_status.dart';
import '../../../core/providers/free_use_provider.dart';
import '../../../core/services/free_use_service.dart';
import '../../../presentation/widgets/free_use_intro_popup.dart';
import '../../../core/providers/locale_provider.dart';
import '../../friend/providers/friend_provider.dart';
import 'adult_verification_screen.dart';
import 'notification_setting_screen.dart';
import 'app_info_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final explorationOn = ref.watch(friendExplorationProvider);
    final freeStatus = ref.watch(freeUseProvider);
    final isFreeActive = freeStatus == FreeUseStatus.active;

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
        title: GestureDetector(
          onLongPress: () async {
            await FreeUseService.instance.resetForTesting();
            ref.read(freeUseProvider.notifier).resetState();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('[DEV] 초기화 완료'),
                duration: Duration(seconds: 1),
              ),
            );
            await Future.delayed(const Duration(milliseconds: 600));
            if (!context.mounted) return;
            await showFreeUseIntroPopup(
              context,
              onActivated: () => ref.read(freeUseProvider.notifier).activateFreeUse(),
            );
          },
          child: Text(
            context.l10n.settings,
            style: const TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                    _SettingRow(
                      icon: Icons.verified_user_outlined,
                      label: context.l10n.settingIdentity,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdultVerificationScreen()),
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
                        MaterialPageRoute(builder: (_) => const NotificationSettingScreen()),
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
                        MaterialPageRoute(builder: (_) => const AppInfoScreen()),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 58),
                      child: _Rule(),
                    ),
                    _ToggleRow(
                      icon: Icons.explore_outlined,
                      label: '친구탐험 알림',
                      value: explorationOn,
                      onToggle: () => ref
                          .read(friendExplorationProvider.notifier)
                          .toggle(),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 58),
                      child: _Rule(),
                    ),
                    _SettingRowWithTrail(
                      icon: Icons.language_outlined,
                      label: context.l10n.settingLanguage,
                      trailText: currentLangLabel,
                      onTap: () => _showLanguagePicker(context, ref, currentLocale),
                    ),
                    if (isFreeActive) ...[
                      const Padding(
                        padding: EdgeInsets.only(left: 58),
                        child: _Rule(),
                      ),
                      _ToggleRow(
                        icon: Icons.card_giftcard_outlined,
                        label: '무료이용 알림허용',
                        value: true,
                        onToggle: () => _confirmTurnOffFreeUse(context, ref),
                      ),
                    ],
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

void _confirmTurnOffFreeUse(BuildContext context, WidgetRef ref) {
  showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        '무료이용 알림 끄기',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
      ),
      content: const Text(
        '알림을 끄면 파트너 무료이용이 즉시 종료됩니다.\n계속하시겠습니까?',
        style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소', style: TextStyle(color: Color(0xFFAAAAAA))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('끄기', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  ).then((confirmed) {
    if (confirmed == true) {
      ref.read(freeUseProvider.notifier).endByNotificationOff();
    }
  });
}

void _showLanguagePicker(BuildContext context, WidgetRef ref, Locale currentLocale) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ..._kLanguages.map((lang) {
            final isSelected = currentLocale.languageCode == lang.code;
            return InkWell(
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(Locale(lang.code));
                Navigator.pop(sheetContext);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1A1A2E)
                              : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            lang.code.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFAAAAAA),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          lang.label,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF1A1A2E)
                                : const Color(0xFF333333),
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check,
                            color: Color(0xFF1A1A2E), size: 18),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    ),
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
          height: 52,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
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
                  style: const TextStyle(color: Color(0xFF333333), fontSize: 15),
                ),
              ),
              Text(
                trailText,
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
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
          height: 52,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
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
                  style: const TextStyle(color: Color(0xFF333333), fontSize: 15),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFDDDDDD), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final VoidCallback onToggle;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
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
                style: const TextStyle(color: Color(0xFF333333), fontSize: 15),
              ),
            ),
            Switch(
              value: value,
              onChanged: (_) => onToggle(),
              activeThumbColor: const Color(0xFF16213E),
            ),
          ],
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
