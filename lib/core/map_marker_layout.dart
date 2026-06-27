import 'dart:io';

class MapMarkerLayoutSpec {
  const MapMarkerLayoutSpec({
    required this.bitmapSize,
    required this.highlightedBitmapSize,
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
  final double highlightedBitmapSize;
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
    highlightedBitmapSize: 38,
    pinSize: 16,
    highlightedPinSize: 30,
    centerSize: 6,
    highlightedCenterSize: 10,
    borderWidth: 1.3,
    highlightedBorderWidth: 2.0,
    shadowBlur: 0,
    highlightedShadowBlur: 0,
    shadowOffsetY: 0,
    tailRadius: 4.5,
  );

  static const android = MapMarkerLayoutSpec(
    bitmapSize: 34,
    highlightedBitmapSize: 56,
    pinSize: 30,
    highlightedPinSize: 48,
    centerSize: 9,
    highlightedCenterSize: 15,
    borderWidth: 2,
    highlightedBorderWidth: 3.0,
    shadowBlur: 0,
    highlightedShadowBlur: 0,
    shadowOffsetY: 0,
    tailRadius: 10,
  );

  static MapMarkerLayoutSpec get current => Platform.isAndroid ? android : ios;
}
