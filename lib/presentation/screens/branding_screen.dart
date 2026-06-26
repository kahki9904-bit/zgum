import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shell/shell_screen.dart';

class BrandingScreen extends StatefulWidget {
  const BrandingScreen({super.key});

  @override
  State<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends State<BrandingScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2500), _proceed);
  }

  void _proceed() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ShellScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Color(0xFF17130F),
        body: Center(
          child: _BrandBlock(),
        ),
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  static const _titleText = 'Z:GUM';
  static const _subtitleText = '지금 시작하세요';

  static const _titleStyle = TextStyle(
    fontSize: 58,
    fontWeight: FontWeight.w900,
    color: Color(0xFFF2DFB0),
    letterSpacing: 1,
    height: 1.0,
  );

  static const _subtitleBase = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w300,
    color: Color(0xA0F4EBD7),
    height: 1.0,
  );

  // Z:GUM 렌더 폭 측정
  double _titleWidth() {
    final painter = TextPainter(
      text: const TextSpan(text: _titleText, style: _titleStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  // 자막을 titleWidth에 맞추는 letterSpacing 계산
  double _subtitleSpacing(double targetWidth) {
    final painter = TextPainter(
      text: const TextSpan(text: _subtitleText, style: _subtitleBase),
      textDirection: TextDirection.ltr,
    )..layout();
    final naturalWidth = painter.width;
    painter.dispose();
    final charCount = _subtitleText.characters.length;
    if (charCount == 0) return 0;
    return (targetWidth - naturalWidth) / charCount;
  }

  @override
  Widget build(BuildContext context) {
    final tw = _titleWidth();
    final spacing = _subtitleSpacing(tw);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 280,
          height: 280,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Color(0x29C9A45A),
                Color(0x0017130F),
              ],
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(_titleText, style: _titleStyle),
            const SizedBox(height: 16),
            SizedBox(
              width: tw,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _subtitleText,
                  style: _subtitleBase.copyWith(
                    letterSpacing: spacing.clamp(0.0, 30.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const _MovingGoldLine(),
          ],
        ),
      ],
    );
  }
}

class _MovingGoldLine extends StatefulWidget {
  const _MovingGoldLine();

  @override
  State<_MovingGoldLine> createState() => _MovingGoldLineState();
}

class _MovingGoldLineState extends State<_MovingGoldLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const lineWidth = 96.0;
    const glowWidth = 38.0;

    return SizedBox(
      width: lineWidth,
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x00D9BD7A),
                    Color(0x88D9BD7A),
                    Color(0x00D9BD7A),
                  ],
                ),
              ),
              child: SizedBox.expand(),
            ),
            AnimatedBuilder(
              animation: _glow,
              builder: (context, child) {
                return Positioned(
                  left: -glowWidth + ((lineWidth + glowWidth) * _glow.value),
                  top: 0,
                  bottom: 0,
                  width: glowWidth,
                  child: child!,
                );
              },
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x00F8E7B9),
                      Color(0xFFF8E7B9),
                      Color(0x00F8E7B9),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
