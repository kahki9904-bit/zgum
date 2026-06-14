import 'package:flutter/material.dart';
import 'zgum_dialog.dart';

/// 성인 전용 이벤트 진입 전 연령 확인 팝업.
/// [show]가 true를 반환해야 상세 화면으로 진입합니다.
class AdultVerifyDialog extends StatelessWidget {
  const AdultVerifyDialog({super.key});

  /// 팝업을 표시하고 사용자가 동의하면 true를 반환합니다.
  static Future<bool> show(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => const AdultVerifyDialog(),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ZGumDialog(
        actions: ZGumButton(
          label: '만 19세 이상입니다',
          onTap: () => Navigator.pop(context, true),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('성인 인증 확인',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            SizedBox(height: 16),
            Text(
              '본 이벤트는 만 19세 이상만 참여 가능합니다.\n\n'
              '귀하는 대한민국 기준 만 19세 이상입니까?\n\n'
              '허위 확인 시 관련 법령에 따라\n법적 책임이 발생할 수 있습니다.',
              style: TextStyle(height: 1.65, fontSize: 14, color: Color(0xFF555555)),
            ),
          ],
        ),
      ),
    );
  }
}
