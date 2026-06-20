import 'package:flutter/material.dart';
import '../../presentation/widgets/dialogs/zgum_dialog.dart';
import 'free_use_service.dart';

// 설정 > 알림 탭 시 표시 — 무료이용 기간(180일) 중에만 노출
Future<void> showFreeUseNotificationPrompt(BuildContext context) async {
  final active = await FreeUseService.instance.isActive();
  if (!active) return;
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
            heightFactor: 0.48,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '알림을 허용하면',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '· 이음 요청을 실시간으로 받을 수 있습니다\n· 상대방의 수락 여부를 즉시 알 수 있습니다\n· 알림은 설정에서 언제든 변경할 수 있습니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF555555),
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
