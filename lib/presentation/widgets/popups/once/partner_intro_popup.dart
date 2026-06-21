import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dialogs/zgum_dialog.dart';

const _kPartnerIntroShown = 'partner_intro_shown';

Future<bool> isPartnerIntroShown() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kPartnerIntroShown) ?? false;
}

Future<void> markPartnerIntroShown() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kPartnerIntroShown, true);
}

Future<void> showPartnerIntroPopup(BuildContext context) async {
  await markPartnerIntroShown();
  if (!context.mounted) return;

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogContext, __, ___) => GestureDetector(
      onTap: () => Navigator.of(dialogContext).pop(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: const ZGumDialog(
            heightFactor: 0.60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이벤트 등록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '지금 진행 중인 프로모션이나 할인 정보를\n실시간으로 등록하고 주변 사용자에게 알릴 수 있습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.75,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  '이렇게 활용하세요',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '· 이벤트 시작 시간과 종료 시간을 설정하세요\n· 사용자가 지도에서 내 이벤트를 확인합니다\n· 종료 후에는 자동으로 마커가 사라집니다',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                    height: 1.85,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
