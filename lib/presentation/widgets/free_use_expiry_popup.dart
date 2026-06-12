import 'package:flutter/material.dart';
import '../../core/services/free_use_service.dart';

Future<void> showFreeUseExpiryPopup(BuildContext context) async {
  final days = FreeUseService.instance.daysUntilExpiry;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, __, ___) => _ExpiryPopupContent(daysLeft: days),
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
  await FreeUseService.instance.markExpiryWarningShown();
}

class _ExpiryPopupContent extends StatelessWidget {
  const _ExpiryPopupContent({required this.daysLeft});
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final expiryLabel = daysLeft == 0
        ? '오늘 만료됩니다.'
        : '$daysLeft일 후 만료됩니다.';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
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
                '파트너 무료이용 기간',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                expiryLabel,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16213E),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '무료이용이 끝나면 파트너 등록은 유료로 전환됩니다.\n알림을 유지하면 남은 기간을 모두 사용할 수 있습니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF777777),
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '확인',
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
            ],
          ),
        ),
      ),
    );
  }
}
