import 'dart:async';
import 'package:chatcore/chat-core.dart';
import 'package:flutter/cupertino.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_discovery/page/discovery_page.dart';
import 'package:ox_discovery/page/moments/group_moments_page.dart';
import 'package:ox_discovery/page/moments/moments_page.dart';
import 'package:ox_discovery/page/moments/personal_moments_page.dart';
import 'package:ox_module_service/ox_module_service.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/ox_moment_manager.dart';

import 'model/moment_extension_model.dart';
import 'model/moment_ui_model.dart';

class OXDiscovery  extends OXFlutterModule {

  @override
  Future<void> setup() async {
    await super.setup();
    OXMomentManager.sharedInstance.init();
    // ChatBinding.instance.setup();
  }

  @override
  // TODO: implement moduleName
  String get moduleName => 'ox_discovery';

  @override
  Map<String, Function> get interfaces => {
    'discoveryPageWidget': discoveryPageWidget,
    'momentPage': jumpMomentPage,
  };

  @override
  Future<T?>? navigateToPage<T>(BuildContext context, String pageName, Map<String, dynamic>? params) {
    switch (pageName) {
      case 'PersonMomentsPage':
        return OXNavigator.pushPage(
            context, (context) => PersonMomentsPage(userDB: params?['userDB']));
      case 'GroupMomentsPage':
        return OXNavigator.pushPage(
            context, (context) => GroupMomentsPage(groupId: params?['groupId']));
    }
    return null;
  }

  Widget discoveryPageWidget(BuildContext context,{required GlobalKey discoveryGlobalKey}) {
    return DiscoveryPage(key: discoveryGlobalKey);
  }

  void jumpMomentPage(BuildContext? context,{required String noteId}) async {
    final notedUIModelCache = OXMomentCacheManager.sharedInstance.notedUIModelCache;

    NotedUIModel? notedUIModel = notedUIModelCache[noteId];
    if(notedUIModel == null){
      NoteDB? note = await Moment.sharedInstance.loadNoteWithNoteId(noteId);
      if(note == null) return CommonToast.instance.show(context, 'Note not found !');
      notedUIModelCache[noteId] = NotedUIModel(noteDB:note);
      notedUIModel = notedUIModelCache[noteId];
    }
    OXNavigator.pushPage(context!, (context) => MomentsPage(isShowReply:false,notedUIModel: ValueNotifier(notedUIModel!)));
  }
}