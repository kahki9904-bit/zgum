import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/popup_layout.dart';
import '../../dialogs/zgum_dialog.dart';

const _kIeumIntroShown = 'ieum_intro_shown';

Future<bool> isIeumIntroShown() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kIeumIntroShown) ?? false;
}

Future<void> markIeumIntroShown() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kIeumIntroShown, true);
}

Future<void> showIeumIntroPopup(BuildContext context) async {
  await markIeumIntroShown();
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
          child: ZGumDialog(
            heightFactor: PopupLayoutSpec.current.introShortFactor,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이음',
                  style: ZGumDialogTextStyles.title,
                ),
                SizedBox(height: 12),
                Text(
                  '주변 사람과 연결되는 기능입니다.\n'
                  '이음 요청을 보내면 상대방이 수락할 수 있습니다.',
                  style: ZGumDialogTextStyles.body,
                ),
                SizedBox(height: 24),
                Text(
                  '알림을 허용하면',
                  style: ZGumDialogTextStyles.sectionTitle,
                ),
                SizedBox(height: 10),
                Text(
                  '· 이음 요청을 실시간으로 받을 수 있습니다\n'
                  '· 상대방의 수락 여부를 즉시 알 수 있습니다\n'
                  '· 알림은 설정에서 언제든 변경할 수 있습니다',
                  style: ZGumDialogTextStyles.support,
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
