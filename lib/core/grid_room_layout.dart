import 'dart:io';
import 'package:flutter/material.dart';

class GridRoomLayoutSpec {
  const GridRoomLayoutSpec({
    required this.topOffset,
    required this.headerPadding,
    required this.orbSize,
    required this.controlHeight,
    required this.controlPadding,
  });

  final double topOffset;
  final EdgeInsets headerPadding;
  final double orbSize;
  final double controlHeight;
  final EdgeInsets controlPadding;

  static const ios = GridRoomLayoutSpec(
    topOffset: 48,
    headerPadding: EdgeInsets.fromLTRB(20, 0, 18, 18),
    orbSize: 82,
    controlHeight: 48,
    controlPadding: EdgeInsets.symmetric(horizontal: 20),
  );

  static const android = GridRoomLayoutSpec(
    topOffset: 48,
    headerPadding: EdgeInsets.fromLTRB(20, 0, 18, 18),
    orbSize: 82,
    controlHeight: 48,
    controlPadding: EdgeInsets.symmetric(horizontal: 20),
  );

  static GridRoomLayoutSpec get current =>
      Platform.isAndroid ? android : ios;
}
