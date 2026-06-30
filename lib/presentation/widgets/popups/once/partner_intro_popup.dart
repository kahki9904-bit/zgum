import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/popup_layout.dart';
import '../../dialogs/zgum_dialog.dart';

const _kPartnerIntroShown = 'partner_intro_shown';

Future<bool> isPartnerIntroShown() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kPartnerIntroShown) ?? false;
}

Future<void> markPartnerIntroShown() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kPartnerIntroShown, true);
}

Future<void> showPartnerIntroPopup(BuildContext context) async {
  await markPartnerIntroShown();
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
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '등록',
                  style: ZGumDialogTextStyles.title,
                ),
                SizedBox(height: 8),
                _SingleLineText(
                  '당신의 이벤트를 주변에 알릴 수 있습니다.',
                  style: ZGumDialogTextStyles.body,
                ),
                SizedBox(height: 12),
                _RegisterFlowPreview(),
                SizedBox(height: 10),
                Text(
                  '유료등록 기준이지만 일정기간동안\n'
                  '무료이용 가능합니다.(1일1회)',
                  style: ZGumDialogTextStyles.caption,
                ),
                SizedBox(height: 10),
                _GuideText(
                  title: '노출',
                  text: '주변사람에게 내 이벤트를 알려줍니다.',
                  singleLine: true,
                ),
                SizedBox(height: 8),
                _GuideText(
                  title: '기록',
                  text: '내 이벤트를 기록할 수 있습니다.',
                  singleLine: true,
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

class _SingleLineText extends StatelessWidget {
  const _SingleLineText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: style,
      ),
    );
  }
}

class _RegisterFlowPreview extends StatelessWidget {
  const _RegisterFlowPreview();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _RoundToken(label: '이곳'),
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
        _SquareToken(label: '등록'),
      ],
    );
  }
}

class _RoundToken extends StatelessWidget {
  const _RoundToken({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.actionGoldSoft,
        border: Border.all(color: AppColors.actionGoldBorder, width: 1.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.actionGoldText,
        ),
      ),
    );
  }
}

class _SquareToken extends StatelessWidget {
  const _SquareToken({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.actionGold,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _GuideText extends StatelessWidget {
  const _GuideText({required this.title, required this.text, this.singleLine = false});

  final String title;
  final String text;
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Text(
            title,
            style: ZGumDialogTextStyles.sectionTitle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: singleLine
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    maxLines: 1,
                    softWrap: false,
                    style: ZGumDialogTextStyles.support.copyWith(
                      fontSize: 12.2,
                      height: 1.35,
                    ),
                  ),
                )
              : Text(
                  text,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: ZGumDialogTextStyles.support.copyWith(
                    fontSize: 12.2,
                    height: 1.35,
                  ),
                ),
        ),
      ],
    );
  }
}
