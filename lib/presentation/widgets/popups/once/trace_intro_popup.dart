import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/popup_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../dialogs/zgum_dialog.dart';

const _kTraceIntroShown = 'trace_intro_shown';

Future<bool> isTraceIntroShown() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kTraceIntroShown) ?? false;
}

Future<void> markTraceIntroShown() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kTraceIntroShown, true);
}

Future<void> showTraceIntroPopup(BuildContext context) async {
  await markTraceIntroShown();
  if (!context.mounted) return;

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogContext, __, ___) => GestureDetector(
      onTap: () => Navigator.of(dialogContext).pop(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: ZGumDialog(
            heightFactor: PopupLayoutSpec.current.introShortFactor,
            contentPadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('지금', style: ZGumDialogTextStyles.title),
                SizedBox(height: 8),
                Text(
                  '이벤트에 참여한 순간을\n'
                  '나만의 흔적으로 남길 수 있습니다.',
                  style: ZGumDialogTextStyles.body,
                ),
                SizedBox(height: 12),
                _TraceFlowPreview(),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TraceGuideTile(
                        title: '남기기',
                        text: '정해진 시간 안에만 가능합니다.',
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _TraceGuideTile(
                        title: '확인',
                        text: '왼쪽 슬라이드 화면에 기록됩니다.',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _TraceGuideTile(
                        title: '저장',
                        text: '사진을 다시 보고 내려받을 수 있습니다.',
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _TraceGuideTile(
                        title: '비공개',
                        text: '다른 사람에게 보이지 않습니다.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _TraceFlowPreview extends StatelessWidget {
  const _TraceFlowPreview();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _LeftSlidePreview(),
        Expanded(
          child: Center(
            child: Text(
              '←',
              style: TextStyle(
                color: AppColors.actionGoldText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        _NowButtonPreview(),
      ],
    );
  }
}

class _LeftSlidePreview extends StatelessWidget {
  const _LeftSlidePreview();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 48,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 5,
            bottom: 5,
            child: Container(
              width: 16,
              decoration: BoxDecoration(
                color: AppColors.actionGoldSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.actionGoldBorder),
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.actionGoldBorder),
              ),
              child: const Center(
                child: Text(
                  '기록',
                  style: TextStyle(
                    color: AppColors.actionGoldText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NowButtonPreview extends StatelessWidget {
  const _NowButtonPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.actionGold,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        '지금',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TraceGuideTile extends StatelessWidget {
  const _TraceGuideTile({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: ZGumDialogTextStyles.sectionTitle),
          const SizedBox(height: 2),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF777777),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
