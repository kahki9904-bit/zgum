import 'package:flutter/material.dart';

/// Z:GUM 앱 아이콘 — 위치 핀 + 사람 형상 결합
/// 얇은 선 단색, 비대칭 배치로 자연스러운 고급감
class ZGumIcon extends StatelessWidget {
  final double size;
  final Color color;

  const ZGumIcon({
    super.key,
    this.size = 48,
    this.color = const Color(0xFF1A1A2E),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ZGumIconPainter(color: color)),
    );
  }
}

class _ZGumIconPainter extends CustomPainter {
  final Color color;
  const _ZGumIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.032
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 위치 핀 윤곽
    final pinPath = Path()
      ..moveTo(w * 0.50, h * 0.10)
      ..cubicTo(w * 0.28, h * 0.10, w * 0.14, h * 0.26, w * 0.14, h * 0.44)
      ..cubicTo(w * 0.14, h * 0.64, w * 0.50, h * 0.92, w * 0.50, h * 0.92)
      ..cubicTo(w * 0.50, h * 0.92, w * 0.86, h * 0.64, w * 0.86, h * 0.44)
      ..cubicTo(w * 0.86, h * 0.26, w * 0.72, h * 0.10, w * 0.50, h * 0.10)
      ..close();
    canvas.drawPath(pinPath, paint);

    // 사람 머리 (핀 중심보다 미세하게 좌측 배치)
    canvas.drawCircle(
      Offset(w * 0.49, h * 0.36),
      w * 0.087,
      paint,
    );

    // 사람 어깨선 (자연스러운 곡선)
    final shoulderPath = Path()
      ..moveTo(w * 0.34, h * 0.57)
      ..quadraticBezierTo(w * 0.49, h * 0.50, w * 0.64, h * 0.58);
    canvas.drawPath(shoulderPath, paint);
  }

  @override
  bool shouldRepaint(_ZGumIconPainter old) => old.color != color;
}
