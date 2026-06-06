import 'package:flutter/material.dart';

class AdultVerificationScreen extends StatelessWidget {
  const AdultVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '성인인증',
          style: TextStyle(color: Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: const Center(
        child: Text(
          '성인인증 내용이 들어갈 자리입니다.',
          style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
        ),
      ),
    );
  }
}
