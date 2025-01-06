import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ox_common/utils/storage_key_tool.dart';
import 'package:ox_common/utils/user_config_tool.dart';
import 'package:ox_module_service/ox_module_service.dart';
import 'package:ox_theme/ox_theme.dart';
import 'package:ox_home/page/home_tabbar.dart';

class LaunchPageView extends StatefulWidget {
  const LaunchPageView({super.key});

  @override
  State<StatefulWidget> createState() {
    return LaunchPageViewState();
  }
}

class LaunchPageViewState extends State<LaunchPageView> {
  final riveFileNames = 'Launcher';
  final stateMachineNames = 'Button';
  final riveInputs = 'Press';


  String _localPasscode = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _localPasscode = UserConfigTool.getSetting(StorageSettingKey.KEY_PASSCODE.name, defaultValue: '');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Lottie.asset(
          "packages/ox_home/assets/${ThemeManager.images("launch_view_anim.json")}",
          fit: BoxFit.fitWidth,
          width: double.infinity,
          height: double.infinity,
          onLoaded: (composition) {
            _onLoaded();
          },
        ),
      ),
    );
  }

  void _onLoaded() {
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (_localPasscode.isNotEmpty) {
        OXModuleService.pushPage(context, 'ox_usercenter', 'VerifyPasscodePage', {});
      } else {
        Navigator.of(context).pushReplacement(CustomRouteFadeIn(const HomeTabBarPage()));
      }
    });
  }
}

class CustomRouteFadeIn<T> extends PageRouteBuilder<T> {
  final Widget widget;
  CustomRouteFadeIn(this.widget)
      : super(
          transitionDuration: const Duration(seconds: 1),
          pageBuilder: (
            BuildContext context,
            Animation<double> animation1,
            Animation<double> animation2,
          ) =>
              widget,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation1,
            Animation<double> animation2,
            Widget child,
          ) {
            return FadeTransition(
              opacity: Tween(begin: 0.0, end: 2.0).animate(
                CurvedAnimation(
                  parent: animation1,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
              child: child,
            );
          },
        );
}
