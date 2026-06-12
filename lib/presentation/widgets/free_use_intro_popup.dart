import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/free_use_service.dart';

Future<void> showFreeUseIntroPopup(
  BuildContext context, {
  Future<void> Function()? onActivated,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, __, ___) =>
        _IntroPopupContent(onActivated: onActivated),
    transitionBuilder: (_, animation, __, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: child,
      ),
    ),
  );
}

class _IntroPopupContent extends StatelessWidget {
  const _IntroPopupContent({this.onActivated});
  final Future<void> Function()? onActivated;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Z:GUM은 하지 않습니다.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '개인정보 요구, 회원가입 요구.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF555555),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '꼭 필요한 확인은 외부 인증 결과만 사용합니다.\n'
                '광고를 보내지 않습니다.\n'
                '알림은 Z:GUM의 경험을 놓치지 않기 위한 장치입니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 1,
                color: const Color(0xFFF0F0F0),
              ),
              const SizedBox(height: 24),
              const Text(
                '알림 허용 시,',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '최초 1회에 한해 6개월간 파트너 등록을 무료로 이용할 수 있습니다.\n'
                '알림을 끄면 무료이용은 즉시 종료됩니다.\n'
                '알림은 설정에서 언제든 변경할 수 있습니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    await FreeUseService.instance.markIntroShown();
                    await onActivated?.call();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    final status = await Permission.notification.request();
                    if (status.isGranted || status.isLimited) return;
                    await openAppSettings();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '알림 허용',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    await FreeUseService.instance.markIntroShown();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        '나중에',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFAAAAAA),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
