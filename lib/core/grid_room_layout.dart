import 'dart:io';
import 'package:flutter/material.dart';

class GridRoomLayoutSpec {
  const GridRoomLayoutSpec({
    required this.topOffset,
    required this.headerPadding,
    required this.headerMinHeight,
    required this.orbSize,
    required this.controlHeight,
    required this.controlPadding,
    required this.tileAspectRatio,
    required this.singleColumnTileAspectRatio,
  });

  final double topOffset;
  final EdgeInsets headerPadding;
  final double headerMinHeight;
  final double orbSize;
  final double controlHeight;
  final EdgeInsets controlPadding;
  final double tileAspectRatio;
  final double singleColumnTileAspectRatio;

  static const ios = GridRoomLayoutSpec(
    topOffset: 18,
    headerPadding: EdgeInsets.fromLTRB(20, 0, 18, 18),
    headerMinHeight: 82,
    orbSize: 82,
    controlHeight: 48,
    controlPadding: EdgeInsets.symmetric(horizontal: 20),
    tileAspectRatio: 0.84,
    singleColumnTileAspectRatio: 0.72,
  );

  static const android = GridRoomLayoutSpec(
    topOffset: 48,
    headerPadding: EdgeInsets.fromLTRB(20, 0, 18, 18),
    headerMinHeight: 100,
    orbSize: 82,
    controlHeight: 64,
    controlPadding: EdgeInsets.symmetric(horizontal: 20),
    tileAspectRatio: 0.84,
    singleColumnTileAspectRatio: 0.72,
  );

  static GridRoomLayoutSpec get current =>
      Platform.isAndroid ? android : ios;
}
