import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/popup_layout.dart';
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
          child: ZGumDialog(
            heightFactor: PopupLayoutSpec.current.introLongFactor,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '등록',
                  style: ZGumDialogTextStyles.title,
                ),
                SizedBox(height: 12),
                Text(
                  '지금 알리고 싶은 어떠한 이벤트로 등록하여\n'
                  '홍보 할 수있습니다.',
                  style: ZGumDialogTextStyles.body,
                ),
                SizedBox(height: 24),
                Text(
                  '이렇게 활용하세요',
                  style: ZGumDialogTextStyles.sectionTitle,
                ),
                SizedBox(height: 10),
                Text(
                  '· 이벤트 제목과 노출시간을 입력해 주세요\n'
                  '· 사진은 최대 3장까지 추가할 수 있습니다\n'
                  '· 등록한 이벤트는 노출시간이 지나면\n'
                  '  자동으로 노출이 종료됩니다',
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
