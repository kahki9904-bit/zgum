import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/popup_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../dialogs/zgum_dialog.dart';

const _kMapMarkerIntroShown = 'map_marker_intro_shown';

Future<bool> isMapMarkerIntroShown() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kMapMarkerIntroShown) ?? false;
}

Future<void> markMapMarkerIntroShown() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kMapMarkerIntroShown, true);
}

Future<void> showMapMarkerIntroPopup(BuildContext context) async {
  await markMapMarkerIntroShown();
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
            heightFactor: PopupLayoutSpec.current.introLongFactor,
            contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('지도 마커', style: ZGumDialogTextStyles.title),
                SizedBox(height: 8),
                _SingleLineText(
                  '지도 표시를 간단히 구분할 수 있습니다.',
                  style: ZGumDialogTextStyles.body,
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MarkerTile(
                        title: '내 위치',
                        marker: _MiniCircleMarker(filled: true),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _MarkerTile(
                        title: '내 이벤트',
                        marker: _MiniSquareMarker(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MarkerTile(
                        title: '등록 이벤트',
                        marker: _MiniCircleMarker(),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _MarkerTile(
                        title: '검색 마커',
                        marker: _MiniSearchMarker(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _GuideCard(
                        sample: _SearchBarSample(),
                        title: '상단 검색',
                        text: '2글자 이상\n입력',
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _GuideCard(
                        sample: _PanelSample(),
                        title: '하단 패널',
                        text: '이벤트\n목록',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  '선택한 마커는 더 크게 표시됩니다.',
                  style: ZGumDialogTextStyles.caption,
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

class _MarkerTile extends StatelessWidget {
  const _MarkerTile({
    required this.title,
    required this.marker,
  });

  final String title;
  final Widget marker;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          marker,
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: ZGumDialogTextStyles.sectionTitle.copyWith(
                fontSize: 13.5,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.sample,
    required this.title,
    required this.text,
  });

  final Widget sample;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.actionGoldSoft.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.actionGoldBorder.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 52, child: sample),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    style: ZGumDialogTextStyles.sectionTitle.copyWith(
                      fontSize: 12.5,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  style: ZGumDialogTextStyles.support.copyWith(
                    fontSize: 10.2,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBarSample extends StatelessWidget {
  const _SearchBarSample();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 34,
        height: 9,
        decoration: BoxDecoration(
          color: AppColors.actionGold,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelSample extends StatelessWidget {
  const _PanelSample();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 50,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.actionGold,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.keyboard_arrow_up_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MiniCircleMarker extends StatelessWidget {
  const _MiniCircleMarker({this.filled = false});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.actionGoldBright : Colors.white,
        border: Border.all(
          color: filled ? AppColors.actionGoldBright : AppColors.actionGold,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? Colors.white : AppColors.actionGold,
          ),
        ),
      ),
    );
  }
}

class _MiniSquareMarker extends StatelessWidget {
  const _MiniSquareMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.actionGoldSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.actionGoldBorder, width: 2),
      ),
      child: Center(
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: AppColors.actionGold,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _MiniSearchMarker extends StatelessWidget {
  const _MiniSearchMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.actionGoldText, width: 2.5),
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: AppColors.actionGoldText,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
