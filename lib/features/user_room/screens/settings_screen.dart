import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../promotions/free_use/free_use_settings_tile.dart';
import '../../../promotions/free_use/free_use_notification_prompt.dart';
import 'adult_verification_screen.dart';
import 'notification_setting_screen.dart';
import 'app_info_screen.dart';

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
            color: Color(0xFF1A1A2E),
            fontSize: 16,
            fontWeight: FontWeight.w700,
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
                      onTap: () async {
                        await showFreeUseNotificationPrompt(context);
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationSettingScreen()),
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
                      onTap: () => _showLanguagePicker(context, ref, currentLocale),
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


class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: const Color(0xFFF0F0F0));
  }
}
