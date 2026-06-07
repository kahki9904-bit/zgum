import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/context_extensions.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
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
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  context.l10n.settingLanguage,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _kLanguages.map((lang) {
                    final isSelected = currentLocale.languageCode == lang.code;
                    return _LanguageRow(
                      lang: lang,
                      isSelected: isSelected,
                      onTap: () => ref.read(localeProvider.notifier).setLocale(Locale(lang.code)),
                      isLast: lang == _kLanguages.last,
                    );
                  }).toList(),
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
  _LangOption(code: 'ko', label: '한국어', nativeLabel: '한국어'),
  _LangOption(code: 'en', label: 'English', nativeLabel: 'English'),
  _LangOption(code: 'ja', label: '日本語', nativeLabel: '日本語'),
  _LangOption(code: 'zh', label: '中文', nativeLabel: '中文（简体）'),
];

class _LangOption {
  final String code;
  final String label;
  final String nativeLabel;
  const _LangOption({required this.code, required this.label, required this.nativeLabel});
}

class _LanguageRow extends StatelessWidget {
  final _LangOption lang;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLast;

  const _LanguageRow({
    required this.lang,
    required this.isSelected,
    required this.onTap,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
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
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFFAAAAAA),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.label,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF1A1A2E)
                                : const Color(0xFF333333),
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        if (lang.nativeLabel != lang.label)
                          Text(
                            lang.nativeLabel,
                            style: const TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check, color: Color(0xFF1A1A2E), size: 18)
                  else
                    const SizedBox(width: 18),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(left: 58),
            child: _Rule(),
          ),
      ],
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
                style: const TextStyle(
                    color: Color(0xFF333333), fontSize: 15),
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
