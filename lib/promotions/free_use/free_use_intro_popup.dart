import 'package:flutter/material.dart';
import '../../../presentation/widgets/dialogs/zgum_dialog.dart';
import 'free_use_service.dart';

Future<void> showFreeUseIntroPopup(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogContext, __, ___) => GestureDetector(
      onTap: () async {
        await FreeUseService.instance.markIntroShown();
        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      },
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
                  'Z:GUM을 설치해 주셔서 감사합니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '파트너 무료이용',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '3개월간 이벤트 등록이 무료입니다.\n하루 최대 3회 등록할 수 있습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.75,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  '알림을 허용하면',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '· 주변 친구를 알려줍니다\n· 무료이용 기간이 유지됩니다\n· 주변 이벤트 소식을 실시간으로 받을 수 있습니다\n· 알림은 설정에서 언제든 변경할 수 있습니다',
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
