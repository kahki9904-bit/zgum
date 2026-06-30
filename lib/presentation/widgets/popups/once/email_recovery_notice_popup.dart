import 'package:flutter/material.dart';
import '../../../../core/popup_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../dialogs/zgum_dialog.dart';

Future<void> showEmailRecoveryNoticePopup(BuildContext context) {
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
            contentPadding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('데이터 안내', style: ZGumDialogTextStyles.title),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.actionGoldSoft.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.actionGoldBorder.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    '회원가입이 없는 앱 특성상 앱 삭제·기기 변경 시 기존 데이터를 보존할 수 없습니다.\n\n'
                    '사전에 이메일을 등록해두면 언제든 복구할 수 있습니다.',
                    style: ZGumDialogTextStyles.body,
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 14,
                      color: AppColors.actionGoldText,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '설정  →  데이터 복구',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.actionGoldText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '에서 이메일을 등록할 수 있습니다.',
                  style: ZGumDialogTextStyles.caption,
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
