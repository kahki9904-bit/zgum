import 'dart:io';

class ShakePanelLayoutSpec {
  const ShakePanelLayoutSpec({
    required this.stageWidth,
    required this.stageHeight,
    required this.stageOffsetY,
    required this.phoneWidth,
    required this.phoneHeight,
    required this.phonePadding,
    required this.phoneRadius,
    required this.innerRadius,
    required this.waveWidth,
    required this.waveHeight,
    required this.centerGlowSize,
    required this.notchTop,
    required this.notchWidth,
    required this.notchHeight,
    required this.shadowBlur,
    required this.shadowOffsetY,
  });

  final double stageWidth;
  final double stageHeight;
  final double stageOffsetY;
  final double phoneWidth;
  final double phoneHeight;
  final double phonePadding;
  final double phoneRadius;
  final double innerRadius;
  final double waveWidth;
  final double waveHeight;
  final double centerGlowSize;
  final double notchTop;
  final double notchWidth;
  final double notchHeight;
  final double shadowBlur;
  final double shadowOffsetY;

  static const ios = ShakePanelLayoutSpec(
    stageWidth: 150,
    stageHeight: 220,
    stageOffsetY: -42,
    phoneWidth: 88,
    phoneHeight: 178,
    phonePadding: 6,
    phoneRadius: 24,
    innerRadius: 19,
    waveWidth: 26,
    waveHeight: 78,
    centerGlowSize: 46,
    notchTop: 14,
    notchWidth: 26,
    notchHeight: 4,
    shadowBlur: 22,
    shadowOffsetY: 10,
  );

  static const android = ShakePanelLayoutSpec(
    stageWidth: 178,
    stageHeight: 260,
    stageOffsetY: -18,
    phoneWidth: 118,
    phoneHeight: 238,
    phonePadding: 8,
    phoneRadius: 28,
    innerRadius: 22,
    waveWidth: 34,
    waveHeight: 92,
    centerGlowSize: 62,
    notchTop: 18,
    notchWidth: 34,
    notchHeight: 5,
    shadowBlur: 36,
    shadowOffsetY: 18,
  );

  static ShakePanelLayoutSpec get current => Platform.isAndroid ? android : ios;
}
