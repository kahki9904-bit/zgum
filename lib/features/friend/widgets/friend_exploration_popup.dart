import 'package:flutter/material.dart';
import '../../../presentation/widgets/dialogs/zgum_dialog.dart';

Future<void> showFriendExplorationPopup(BuildContext context) {
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
            heightFactor: 0.48,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '친구탐험',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '내 위치가 친구들에게 대략적으로 공유됩니다.\n정확한 위치는 알 수 없으며, 근처에 있다는 정도만 전달됩니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.75,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  '언제든 이 설정에서 끌 수 있습니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFAAAAAA),
                    height: 1.6,
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
