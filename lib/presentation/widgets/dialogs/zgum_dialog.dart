import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Container(
      width: double.infinity,
      height: screenHeight * heightFactor,
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
      child: Material(
        color: Colors.white,
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
    );
  }
}

/// Z:GUM 표준 확인 버튼.
/// widthFactor = 0.25 → 팝업 가로 1/4, 우측 정렬.
/// widthFactor = 1.0  → 전체 폭.
class ZGumButton extends StatelessWidget {
  const ZGumButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF16213E),
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
