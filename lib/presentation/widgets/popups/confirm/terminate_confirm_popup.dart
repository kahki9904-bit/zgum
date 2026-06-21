import 'package:flutter/material.dart';
import '../../dialogs/zgum_dialog.dart';

Future<bool?> showTerminateConfirmPopup(BuildContext context, String message) {
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
