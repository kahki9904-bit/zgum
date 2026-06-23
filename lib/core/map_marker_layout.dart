import 'dart:io';

class MapMarkerLayoutSpec {
  const MapMarkerLayoutSpec({
    required this.bitmapSize,
    required this.pinSize,
    required this.highlightedPinSize,
    required this.centerSize,
    required this.highlightedCenterSize,
    required this.borderWidth,
    required this.highlightedBorderWidth,
    required this.shadowBlur,
    required this.highlightedShadowBlur,
    required this.shadowOffsetY,
    required this.tailRadius,
  });

  final double bitmapSize;
  final double pinSize;
  final double highlightedPinSize;
  final double centerSize;
  final double highlightedCenterSize;
  final double borderWidth;
  final double highlightedBorderWidth;
  final double shadowBlur;
  final double highlightedShadowBlur;
  final double shadowOffsetY;
  final double tailRadius;

  static const ios = MapMarkerLayoutSpec(
    bitmapSize: 22,
    pinSize: 16,
    highlightedPinSize: 21,
    centerSize: 6,
    highlightedCenterSize: 7.5,
    borderWidth: 1.3,
    highlightedBorderWidth: 1.5,
    shadowBlur: 0,
    highlightedShadowBlur: 0,
    shadowOffsetY: 0,
    tailRadius: 4.5,
  );

  static const android = MapMarkerLayoutSpec(
    bitmapSize: 34,
    pinSize: 30,
    highlightedPinSize: 34,
    centerSize: 9,
    highlightedCenterSize: 11,
    borderWidth: 2,
    highlightedBorderWidth: 2.4,
    shadowBlur: 0,
    highlightedShadowBlur: 0,
    shadowOffsetY: 0,
    tailRadius: 10,
  );

  static MapMarkerLayoutSpec get current => Platform.isAndroid ? android : ios;
}
