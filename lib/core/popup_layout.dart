import 'dart:io';
import 'package:flutter/material.dart';

class PopupLayoutSpec {
  const PopupLayoutSpec({
    required this.confirmHeight,
    required this.inputHeight,
    required this.mediumHeight,
    required this.standardHeight,
    required this.longHeight,
    required this.introShortFactor,
    required this.introLongFactor,
    required this.eventDetailFactor,
    required this.registerFormFactor,
    required this.registerFormMargin,
    required this.registerFormRadius,
    required this.compactForm,
    required this.registerFormTopPadding,
    required this.removeViewInsetsOnDialog,
  });

  final double confirmHeight;
  final double inputHeight;
  final double mediumHeight;
  final double standardHeight;
  final double longHeight;
  final double introShortFactor;
  final double introLongFactor;
  final double eventDetailFactor;
  final double registerFormFactor;
  final EdgeInsets registerFormMargin;
  final double registerFormRadius;
  final bool compactForm;
  final double registerFormTopPadding;
  final bool removeViewInsetsOnDialog;

  double heightForFactor(double heightFactor) {
    if (heightFactor <= 0.24) return confirmHeight;
    if (heightFactor <= 0.32) return inputHeight;
    if (heightFactor <= 0.42) return mediumHeight;
    if (heightFactor <= 0.50) return standardHeight;
    return longHeight;
  }

  static const ios = PopupLayoutSpec(
    confirmHeight: 188,
    inputHeight: 260,
    mediumHeight: 300,
    standardHeight: 340,
    longHeight: 430,
    introShortFactor: 0.48,
    introLongFactor: 0.60,
    eventDetailFactor: 0.68,
    registerFormFactor: 0.52,
    registerFormMargin: EdgeInsets.symmetric(horizontal: 20),
    registerFormRadius: 24,
    compactForm: true,
    registerFormTopPadding: 40.0,
    removeViewInsetsOnDialog: true,
  );

  static const android = PopupLayoutSpec(
    confirmHeight: 188,
    inputHeight: 260,
    mediumHeight: 300,
    standardHeight: 340,
    longHeight: 430,
    introShortFactor: 0.38,
    introLongFactor: 0.60,
    eventDetailFactor: 0.62,
    registerFormFactor: 0.62,
    registerFormMargin: EdgeInsets.symmetric(horizontal: 20),
    registerFormRadius: 24,
    compactForm: false,
    registerFormTopPadding: 44.0,
    removeViewInsetsOnDialog: false,
  );

  static PopupLayoutSpec get current => Platform.isAndroid ? android : ios;
}
