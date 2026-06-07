import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shell_screen.dart';
import 'consent_guard.dart';

class BrandingScreen extends StatelessWidget {
  const BrandingScreen({super.key});

  void _proceed(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            const ConsentGuard(child: ShellScreen()),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _proceed(context),
          child: const Center(
            child: _BrandBlock(),
          ),
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
    fontSize: 60,
    fontWeight: FontWeight.w900,
    color: Color(0xFF1E90FF),
    letterSpacing: 1,
    height: 1.0,
  );

  static const _subtitleBase = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w300,
    color: Colors.black,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(_titleText, style: _titleStyle),
        const SizedBox(height: 16),
        Text(
          _subtitleText,
          style: _subtitleBase.copyWith(
            letterSpacing: spacing.clamp(0.0, 30.0),
          ),
        ),
      ],
    );
  }
}
