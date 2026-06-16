import 'package:flutter/material.dart';
import '../../presentation/widgets/dialogs/zgum_dialog.dart';
import 'free_use_service.dart';

// 설정 > 알림 탭 시 무료이용 크레딧 안내 팝업
// 인트로 확인 후 + 크레딧 미시작 상태일 때만 표시
Future<void> showFreeUseNotificationPrompt(BuildContext context) async {
  final introShown = await FreeUseService.instance.isIntroShown();
  final started = await FreeUseService.instance.isStarted();
  if (!introShown || started) return;
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
                  '파트너 무료이용이 시작됩니다.\n3개월간 하루 최대 3회 이벤트를 무료로 등록할 수 있습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.75,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  '알림은 설정에서 언제든 변경할 수 있습니다.',
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
