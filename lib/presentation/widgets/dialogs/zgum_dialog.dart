import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/popup_layout.dart';

/// Z:GUM 표준 팝업 컨테이너.
/// child: 스크롤 가능한 내용, actions: 하단 고정 버튼.
class ZGumDialog extends StatelessWidget {
  const ZGumDialog({
    super.key,
    required this.child,
    this.actions,
    this.heightFactor = 0.45,
    this.contentPadding = const EdgeInsets.fromLTRB(24, 28, 24, 0),
    this.actionsPadding = const EdgeInsets.fromLTRB(24, 16, 24, 28),
    this.centerContent = false,
  });

  final Widget child;
  final Widget? actions;
  final double heightFactor;
  final EdgeInsets contentPadding;
  final EdgeInsets actionsPadding;
  final bool centerContent;

  double _resolvedHeight(double screenHeight) {
    final targetHeight = PopupLayoutSpec.current.heightForFactor(heightFactor);
    return targetHeight.clamp(0.0, screenHeight - 80).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Align(
      alignment: Alignment.center,
      // ignore: avoid_unnecessary_containers
      child: Container(
        width: (screenWidth - 40).clamp(0.0, 360.0),
        height: _resolvedHeight(screenHeight),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x38000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: MediaQuery.withNoTextScaling(
          child: Material(
            color: Colors.transparent,
            child: ZGumFaintIconBackground(
              child: Column(
                children: [
                  Expanded(
                    child: centerContent
                        ? Center(
                            child: Padding(
                              padding: contentPadding,
                              child: child,
                            ),
                          )
                        : SingleChildScrollView(
                            padding: contentPadding,
                            child: child,
                          ),
                  ),
                  if (actions != null)
                    Padding(
                      padding: actionsPadding,
                      child: actions!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ZGumFaintIconBackground extends StatelessWidget {
  const ZGumFaintIconBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.026,
              child: ClipOval(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class ZGumDialogTextStyles {
  const ZGumDialogTextStyles._();

  static const title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.actionGoldText,
    height: 1.2,
  );

  static const body = TextStyle(
    fontSize: 14,
    color: Color(0xFF333333),
    height: 1.5,
  );

  static const sectionTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.actionGoldText,
    height: 1.35,
  );

  static const support = TextStyle(
    fontSize: 13,
    color: Color(0xFF777777),
    height: 1.5,
  );

  static const confirmBody = TextStyle(
    fontSize: 14,
    color: Color(0xFF555555),
    height: 1.4,
  );

  static const caption = TextStyle(
    fontSize: 13,
    color: Color(0xFFAAAAAA),
    height: 1.45,
  );
}

/// Z:GUM 표준 확인 버튼.
/// widthFactor = 0.25 → 팝업 가로 1/4, 우측 정렬.
/// widthFactor = 1.0  → 전체 폭.
class ZGumButton extends StatelessWidget {
  const ZGumButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.actionGold,
    this.textColor = Colors.white,
    this.fontWeight = FontWeight.w700,
    this.widthFactor = 0.25,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final FontWeight fontWeight;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ),
    );

    if (widthFactor >= 1.0) {
      return SizedBox(width: double.infinity, child: button);
    }
    return Align(
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(widthFactor: widthFactor, child: button),
    );
  }
}
