import 'dart:io';

class ShellGestureLayoutSpec {
  const ShellGestureLayoutSpec({
    required this.pageSwipeDistance,
    required this.pageSwipeAxisRatio,
    required this.mapEdgeSwipeWidthFactor,
    required this.mapEdgeSwipeVelocity,
    required this.androidBackExclusionWidth,
  });

  final double pageSwipeDistance;
  final double pageSwipeAxisRatio;
  final double mapEdgeSwipeWidthFactor;
  final double mapEdgeSwipeVelocity;
  final double androidBackExclusionWidth;

  static const ios = ShellGestureLayoutSpec(
    pageSwipeDistance: 95,
    pageSwipeAxisRatio: 1.5,
    mapEdgeSwipeWidthFactor: 0.12,
    mapEdgeSwipeVelocity: 650,
    androidBackExclusionWidth: 0,
  );

  static const android = ShellGestureLayoutSpec(
    pageSwipeDistance: 60,
    pageSwipeAxisRatio: 1.2,
    mapEdgeSwipeWidthFactor: 0.15,
    mapEdgeSwipeVelocity: 400,
    androidBackExclusionWidth: 40,
  );

  static ShellGestureLayoutSpec get current =>
      Platform.isAndroid ? android : ios;
}
