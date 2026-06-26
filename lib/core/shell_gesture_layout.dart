import 'dart:io';

class ShellGestureLayoutSpec {
  const ShellGestureLayoutSpec({
    required this.pageSwipeDistance,
    required this.pageSwipeAxisRatio,
    required this.mapEdgeSwipeWidthFactor,
    required this.mapEdgeSwipeVelocity,
    required this.androidBackExclusionWidth,
    required this.bottomPaddingMin,
    required this.useTranslucentHitTest,
  });

  final double pageSwipeDistance;
  final double pageSwipeAxisRatio;
  final double mapEdgeSwipeWidthFactor;
  final double mapEdgeSwipeVelocity;
  final double androidBackExclusionWidth;
  final double bottomPaddingMin;
  final bool useTranslucentHitTest;

  static const ios = ShellGestureLayoutSpec(
    pageSwipeDistance: 95,
    pageSwipeAxisRatio: 1.5,
    mapEdgeSwipeWidthFactor: 0.12,
    mapEdgeSwipeVelocity: 650,
    androidBackExclusionWidth: 0,
    bottomPaddingMin: 0.0,
    useTranslucentHitTest: true,
  );

  static const android = ShellGestureLayoutSpec(
    pageSwipeDistance: 60,
    pageSwipeAxisRatio: 1.2,
    mapEdgeSwipeWidthFactor: 0.15,
    mapEdgeSwipeVelocity: 400,
    androidBackExclusionWidth: 40,
    bottomPaddingMin: 16.0,
    useTranslucentHitTest: false,
  );

  static ShellGestureLayoutSpec get current =>
      Platform.isAndroid ? android : ios;
}
