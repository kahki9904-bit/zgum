import 'package:flutter/material.dart';

/// 성인 전용 이벤트 진입 전 연령 확인 팝업.
/// [show]가 true를 반환해야 상세 화면으로 진입합니다.
class AdultVerifyDialog extends StatelessWidget {
  const AdultVerifyDialog({super.key});

  /// 팝업을 표시하고 사용자가 동의하면 true를 반환합니다.
  static Future<bool> show(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AdultVerifyDialog(),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.verified_user_outlined, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('성인 인증 확인'),
        ],
      ),
      content: const Text(
        '본 이벤트는 만 19세 이상만 참여 가능합니다.\n\n'
        '귀하는 대한민국 기준 만 19세 이상입니까?\n\n'
        '허위 확인 시 관련 법령에 따라\n법적 책임이 발생할 수 있습니다.',
        style: TextStyle(height: 1.65, fontSize: 14),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(minimumSize: const Size(140, 40)),
          child: const Text('만 19세 이상입니다'),
        ),
      ],
    );
  }
}
