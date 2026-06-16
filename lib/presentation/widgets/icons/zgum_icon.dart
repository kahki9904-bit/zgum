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
      child: CustomPaint(painter: ZGumIconPainter(color: color)),
    );
  }
}

class ZGumIconPainter extends CustomPainter {
  final Color color;
  const ZGumIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.050
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 위치 핀 윤곽 (82% 크기로 축소, 중앙 정렬)
    final pinPath = Path()
      ..moveTo(w * 0.500, h * 0.172)
      ..cubicTo(w * 0.320, h * 0.172, w * 0.205, h * 0.303, w * 0.205, h * 0.451)
      ..cubicTo(w * 0.205, h * 0.615, w * 0.500, h * 0.844, w * 0.500, h * 0.844)
      ..cubicTo(w * 0.500, h * 0.844, w * 0.795, h * 0.615, w * 0.795, h * 0.451)
      ..cubicTo(w * 0.795, h * 0.303, w * 0.680, h * 0.172, w * 0.500, h * 0.172)
      ..close();
    canvas.drawPath(pinPath, paint);

    // 사람 머리
    canvas.drawCircle(
      Offset(w * 0.492, h * 0.385),
      w * 0.071,
      paint,
    );

    // 사람 어깨선
    final shoulderPath = Path()
      ..moveTo(w * 0.369, h * 0.557)
      ..quadraticBezierTo(w * 0.492, h * 0.500, w * 0.615, h * 0.566);
    canvas.drawPath(shoulderPath, paint);
  }

  @override
  bool shouldRepaint(ZGumIconPainter old) => old.color != color;
}
