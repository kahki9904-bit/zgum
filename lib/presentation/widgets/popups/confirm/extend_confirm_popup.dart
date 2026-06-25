import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../dialogs/zgum_dialog.dart';

Future<bool?> showExtendConfirmPopup(BuildContext context) {
  return showGeneralDialog<bool?>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: const Color(0x66000000),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, __, ___) => GestureDetector(
      onTap: () => Navigator.of(dialogContext).pop(null),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: ZGumDialog(
            heightFactor: 0.22,
            actions: GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(true),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.actionGold,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            child: const Text(
              '1회 1시간 연장가능',
              textAlign: TextAlign.center,
              style: ZGumDialogTextStyles.confirmBody,
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
