
import 'dart:async';
import 'dart:convert' as convert;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:ox_discovery/page/discovery_page.dart';
import 'package:ox_module_service/ox_module_service.dart';
import 'package:ox_common/navigator/navigator.dart';

class OXDiscovery  extends OXFlutterModule {

  @override
  Future<void> setup() async {
    // TODO: implement setup
    super.setup();
    OXModuleService.registerFlutterModule(moduleName, this);
    // ChatBinding.instance.setup();
  }

  @override
  // TODO: implement moduleName
  String get moduleName => 'ox_discovery';

  @override
  Map<String, Function> get interfaces => {
    'discoveryPageWidget': discoveryPageWidget,
  };

  @override
  navigateToPage(BuildContext context, String pageName, Map<String, dynamic>? params) {
    switch (pageName) {
      case 'UserCenterPage':
        return OXNavigator.pushPage(
          context,
              (context) => const DiscoveryPage(),
        );
    }
    return null;
  }

  Widget discoveryPageWidget(BuildContext context) {
    return const DiscoveryPage();
  }
}
