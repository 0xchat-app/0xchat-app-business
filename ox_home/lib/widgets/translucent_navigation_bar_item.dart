import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A tab to display in a [DotNavigationBar]
class TranslucentNavigationBarItem {
  /// An icon to display.
  int unreadMsgCount;
  final AnimationController? animationController;
  final LottieBuilder? lottieBuilder;
  String Function()? title;


  TranslucentNavigationBarItem({
    required this.unreadMsgCount,
    required this.animationController,
    required this.lottieBuilder,
    this.title,
  });
}
