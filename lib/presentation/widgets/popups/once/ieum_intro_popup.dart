import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/popup_layout.dart';
import '../../dialogs/zgum_dialog.dart';

const _kIeumIntroShown = 'ieum_intro_shown';

Future<bool> isIeumIntroShown() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kIeumIntroShown) ?? false;
}

Future<void> markIeumIntroShown() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kIeumIntroShown, true);
}

Future<void> showIeumIntroPopup(BuildContext context) async {
  await markIeumIntroShown();
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
            contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이음',
                  style: ZGumDialogTextStyles.title,
                ),
                SizedBox(height: 10),
                Text(
                  '지금 곁에 있는 사람과 이어지는 기능입니다.\n'
                  '주변에 친구가 있음을 알려 줍니다.',
                  style: ZGumDialogTextStyles.body,
                ),
                SizedBox(height: 14),
                _IeumFlowPreview(),
                SizedBox(height: 12),
                _GuideText(
                  title: '신청',
                  text: '이음 요청을 보낸 후 상대가 불러주는 코드를 입력하면 완성됩니다.',
                ),
                SizedBox(height: 8),
                _GuideText(
                  title: '수락',
                  text: '앱을 켜고 표시된 코드를 상대에게 알려줍니다.',
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

class _IeumFlowPreview extends StatelessWidget {
  const _IeumFlowPreview();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _RoundToken(label: '이음', filled: true),
        Expanded(
          child: Center(
            child: Text(
              '→',
              style: TextStyle(
                color: AppColors.actionGoldText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        _RoundToken(label: '수락'),
      ],
    );
  }
}

class _RoundToken extends StatelessWidget {
  const _RoundToken({required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.actionGold : AppColors.actionGoldSoft,
        border: Border.all(color: AppColors.actionGoldBorder, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: filled ? Colors.white : AppColors.actionGoldText,
        ),
      ),
    );
  }
}

class _GuideText extends StatelessWidget {
  const _GuideText({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Text(title, style: ZGumDialogTextStyles.sectionTitle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: ZGumDialogTextStyles.support),
        ),
      ],
    );
  }
}
