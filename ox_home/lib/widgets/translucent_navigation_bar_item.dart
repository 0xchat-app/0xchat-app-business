import 'package:flutter/animation.dart';
import 'package:rive/rive.dart';

/// A tab to display in a [DotNavigationBar]
class TranslucentNavigationBarItem {
  /// An icon to display.
  int unreadMsgCount;
  final StateMachineController? animationController;
  final Artboard? artboard;
  final String? title;


  TranslucentNavigationBarItem({
    required this.unreadMsgCount,
    required this.animationController,
    required this.artboard,
    this.title,
  });
}
