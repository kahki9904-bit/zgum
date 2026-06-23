import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../presentation/widgets/dialogs/zgum_dialog.dart';

const _kShownKey = 'camera_chooser_popup_shown';

Future<bool> isCameraChooserPopupShown() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kShownKey) ?? false;
}

Future<void> showCameraChooserPopup(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kShownKey, true);

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
            heightFactor: 0.38,
            child: Text(
              '기기 설정에서 카메라 기본값을 해제하면\n원하는 앱으로 찍을 수 있습니다.',
              textAlign: TextAlign.center,
              style: ZGumDialogTextStyles.confirmBody,
            ),
          ),
        ),
      ),
    ),
  );
}
