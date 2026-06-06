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

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Z:GUM',
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E90FF),
            letterSpacing: 1,
            height: 1.0,
          ),
        ),
        SizedBox(height: 16),
        Text(
          '탐험을  시작합니다',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            color: Color(0x994682B4),
            letterSpacing: 3,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
