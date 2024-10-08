import 'dart:math';
import 'dart:ui';

import 'package:chatcore/chat-core.dart';
import 'package:flutter/material.dart';
import 'package:ox_common/business_interface/ox_chat/interface.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_discovery/enum/group_type.dart';
import 'package:ox_discovery/page/moments/groups_page.dart';
import 'package:ox_discovery/page/widgets/group_selector_dialog.dart';
import 'package:ox_discovery/utils/discovery_utils.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:ox_common/log_util.dart';
import 'package:ox_common/mixin/common_state_view_mixin.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/utils/ox_userinfo_manager.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_module_service/ox_module_service.dart';
import '../enum/moment_enum.dart';
import '../model/moment_extension_model.dart';
import '../utils/album_utils.dart';
import 'moments/channel_page.dart';
import 'moments/create_moments_page.dart';
import 'moments/group_moments_page.dart';
import 'moments/public_moments_page.dart';
import 'package:ox_common/business_interface/ox_discovery/ox_discovery_model.dart';
import 'package:flutter/cupertino.dart';

enum EDiscoveryPageType{
  moment,
  channel
}


class DiscoveryPage extends StatefulWidget {

  const DiscoveryPage({Key? key}): super(key: key);

  @override
  State<DiscoveryPage> createState() => DiscoveryPageState();
}

class DiscoveryPageState extends DiscoveryPageBaseState<DiscoveryPage>
    with
        AutomaticKeepAliveClientMixin,
        OXUserInfoObserver,
        WidgetsBindingObserver,
        CommonStateViewMixin {

  int _channelCurrentIndex = 0;

  GroupType _groupType = GroupType.openGroup;


  EDiscoveryPageType pageType = EDiscoveryPageType.moment;


  GlobalKey<PublicMomentsPageState> publicMomentPageKey = GlobalKey<PublicMomentsPageState>();
  GlobalKey<GroupsPageState> groupsPageState = GlobalKey<GroupsPageState>();

  EPublicMomentsPageType publicMomentsPageType = EPublicMomentsPageType.all;

  bool _isLogin = false;

  @override
  void initState() {
    super.initState();
    OXUserInfoManager.sharedInstance.addObserver(this);
    _isLogin = OXUserInfoManager.sharedInstance.isLogin;
  }

  void _momentPublic(bool isChangeToDiscovery){
    if(publicMomentPageKey.currentState == null) return;
    bool hasNotesList = publicMomentPageKey.currentState!.notesList.isEmpty;
    if(isChangeToDiscovery && hasNotesList){
      publicMomentPageKey.currentState!.refreshController.requestRefresh();
    }

    if(!isChangeToDiscovery){
      publicMomentPageKey.currentState?.momentScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

  }

  @override
  void dispose() {
    OXUserInfoManager.sharedInstance.removeObserver(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  stateViewCallBack(CommonStateView commonStateView) {
    switch (commonStateView) {
      case CommonStateView.CommonStateView_None:
        break;
      case CommonStateView.CommonStateView_NetworkError:
        break;
      case CommonStateView.CommonStateView_NoData:
        break;
      case CommonStateView.CommonStateView_NotLogin:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    double momentMm =  DiscoveryUtils.boundingTextSize(
            Localized.text('ox_discovery.moment'),
            TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Adapt.px(20),
                color: ThemeColor.titleColor))
        .width;
    double discoveryMm = DiscoveryUtils.boundingTextSize(
        Localized.text('ox_discovery.group'),
        TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Adapt.px(20),
            color: ThemeColor.titleColor))
        .width;
    return Scaffold(
      backgroundColor: ThemeColor.color200,
      appBar: AppBar(
        backgroundColor: ThemeColor.color200,
        elevation: 0,
        titleSpacing: 0.0,
        actions: _actionWidget(),
        title: Row(
          children: [
            SizedBox(
              width: Adapt.px(24),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  pageType = EDiscoveryPageType.moment;
                });
              },
              child: Container(
                constraints: BoxConstraints(maxWidth: momentMm),
                child: GradientText(Localized.text('ox_discovery.moment'),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Adapt.px(20),
                        color: ThemeColor.titleColor),
                    colors: [
                     pageType == EDiscoveryPageType.moment ? ThemeColor.gradientMainStart : ThemeColor.color120,
                     pageType == EDiscoveryPageType.moment ? ThemeColor.gradientMainEnd : ThemeColor.color120,
                    ]),
              ),
            ),
            SizedBox(
              width: Adapt.px(24),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  pageType = EDiscoveryPageType.channel;
                });
              },
              child: Container(
                constraints: BoxConstraints(maxWidth: discoveryMm),
                child: GradientText(Localized.text('ox_discovery.group'),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Adapt.px(20),
                        color: ThemeColor.titleColor),
                    colors: [
                      pageType == EDiscoveryPageType.channel ? ThemeColor.gradientMainStart : ThemeColor.color120,
                      pageType == EDiscoveryPageType.channel ? ThemeColor.gradientMainEnd : ThemeColor.color120,
                    ]),
              ),
            ),
            SizedBox(
              width: Adapt.px(24),
            ),
          ],
        ),
      ),
      body: _body(),
    );
  }

  List<Widget> _actionWidget(){
    if(!_isLogin) return [];

    if(pageType == EDiscoveryPageType.moment) {
      return [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: CommonImage(
            iconName: "moment_option.png",
            width: Adapt.px(24),
            height: Adapt.px(24),
            color: ThemeColor.color100,
            package: 'ox_discovery',
          ),
          onTap: () {
            showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => _buildMomentBottomDialog());
          },
        ),
        SizedBox(
          width: Adapt.px(20),
        ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: CommonImage(
            iconName: "moment_add_icon.png",
            width: Adapt.px(24),
            height: Adapt.px(24),
            color: ThemeColor.color100,
            package: 'ox_discovery',
          ),
          onLongPress: (){
            OXNavigator.presentPage(context, (context) => const CreateMomentsPage(type: EMomentType.content));
          },
          onTap: () {
            CreateMomentDraft? createMomentMediaDraft = OXMomentCacheManager.sharedInstance.createMomentMediaDraft;
            if(createMomentMediaDraft!= null){
              final type = createMomentMediaDraft.type;
              final imageList = type == EMomentType.picture ? createMomentMediaDraft.imageList : null;
              final videoPath = type == EMomentType.video ? createMomentMediaDraft.videoPath : null;
              final videoImagePath = type == EMomentType.video ? createMomentMediaDraft.videoImagePath : null;

              OXNavigator.presentPage(
                context,
                  (context) => CreateMomentsPage(
                    type: type,
                    imageList: imageList,
                    videoPath: videoPath,
                    videoImagePath: videoImagePath,
                  ),
              );
              return;
            }
            OXNavigator.presentPage(context, (context) => const CreateMomentsPage(type: null));
          },
        ),
        SizedBox(
          width: Adapt.px(24),
        ),
      ];
    }

    return [
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: CommonImage(
          iconName: "nav_more_new.png",
          width: Adapt.px(24),
          height: Adapt.px(24),
          color: ThemeColor.color100,
        ),
        onTap: () async {
          // showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => _buildChannelBottomDialog());
          await showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (BuildContext context) {
              return GroupSelectorDialog(
                title: Localized.text('ox_discovery.group'),
                onChanged: (type) => _updateGroupType(type),
              );
            },
          );
        },
      ),
      OXChatInterface.showRelayInfoWidget().setPaddingOnly(left: 20.px),
      SizedBox(
        width: Adapt.px(24),
      ),
    ];
  }

  Widget _body(){
    if(pageType == EDiscoveryPageType.moment)  return PublicMomentsPage(key:publicMomentPageKey,publicMomentsPageType: publicMomentsPageType,);
    return GroupsPage(
      key: groupsPageState,
      groupType: _groupType,
    );
  }

  Widget headerViewForIndex(String leftTitle, int index) {
    return SizedBox(
      height: Adapt.px(45),
      child: Row(
        children: [
          SizedBox(
            width: Adapt.px(24),
          ),
          Text(
            leftTitle,
            style: TextStyle(
                color: ThemeColor.titleColor,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // CommonImage(
          //   iconName: "more_icon_z.png",
          //   width: Adapt.px(39),
          //   height: Adapt.px(8),
          // ),
          SizedBox(
            width: Adapt.px(16),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelBottomDialog() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Adapt.px(12)),
        color:  ThemeColor.color160,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            Localized.text('ox_discovery.recommended_item'),
            index: 0,
            onTap: () => _updateChannelCurrentIndex(0),
          ),
          Divider(
            color: ThemeColor.color170,
            height: Adapt.px(0.5),
          ),
          _buildItem(
            Localized.text('ox_discovery.popular_item'),
            index: 1,
            onTap: () => _updateChannelCurrentIndex(1),
          ),
          Divider(
            color: ThemeColor.color170,
            height: Adapt.px(0.5),
          ),
          _buildItem(
            Localized.text('ox_discovery.latest_item'),
            index: 2,
            onTap: () => _updateChannelCurrentIndex(2),
          ),
          Container(
            height: Adapt.px(8),
            color: ThemeColor.color190,
          ),
          _buildItem(Localized.text('ox_common.cancel'), index: 3, onTap: () {
            OXNavigator.pop(context);
          }),
        ],
      ),
    );
  }

  Widget _buildItem(String title, {required int index, GestureTapCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: Adapt.px(56),
        child: Text(
          title,
          style: TextStyle(
            color: ThemeColor.color0,
            fontSize: Adapt.px(16),
            fontWeight: index == _channelCurrentIndex ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildMomentBottomDialog() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Adapt.px(12)),
        color: ThemeColor.color180,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMomentItem(
            isSelect: publicMomentsPageType == EPublicMomentsPageType.all,
            EPublicMomentsPageType.all.text,
            index: 0,
            onTap: () {
              OXNavigator.pop(context);
              if(mounted){
                publicMomentsPageType = EPublicMomentsPageType.all;
              }
            },
          ),
          Divider(
            color: ThemeColor.color170,
            height: Adapt.px(0.5),
          ),
          _buildMomentItem(
            isSelect: publicMomentsPageType == EPublicMomentsPageType.contacts,
            EPublicMomentsPageType.contacts.text,
            index: 1,
            onTap: () {
              OXNavigator.pop(context);
              if(mounted){
                publicMomentsPageType = EPublicMomentsPageType.contacts;
              }
            },
          ),
          Divider(
            color: ThemeColor.color170,
            height: Adapt.px(0.5),
          ),
          _buildMomentItem(
            isSelect: publicMomentsPageType == EPublicMomentsPageType.follows,
            EPublicMomentsPageType.follows.text,
            index: 1,
            onTap: () {
              OXNavigator.pop(context);
              if(mounted){
                publicMomentsPageType = EPublicMomentsPageType.follows;
              }
            },
          ),
          Divider(
            color: ThemeColor.color170,
            height: Adapt.px(0.5),
          ),
          _buildMomentItem(
            isSelect: publicMomentsPageType == EPublicMomentsPageType.reacted,
            EPublicMomentsPageType.reacted.text,
            index: 1,
            onTap: () {
              OXNavigator.pop(context);
              if(mounted){
                publicMomentsPageType = EPublicMomentsPageType.reacted;
              }
            },
          ),
          Divider(
            color: ThemeColor.color170,
            height: Adapt.px(0.5),
          ),
          _buildMomentItem(
            isSelect: publicMomentsPageType == EPublicMomentsPageType.private,
            EPublicMomentsPageType.private.text,
            index: 1,
            onTap: () {
              OXNavigator.pop(context);
              if(mounted){
                publicMomentsPageType = EPublicMomentsPageType.private;
              }
            },
          ),
          Divider(
            color: ThemeColor.color170,
            height: Adapt.px(0.5),
          ),
          Container(
            height: Adapt.px(8),
            color: ThemeColor.color190,
          ),
          _buildMomentItem(Localized.text('ox_common.cancel'), index: 3, onTap: () {
            OXNavigator.pop(context);
          }),
          SizedBox(
            height: Adapt.px(21),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentItem(String title,
      {required int index, GestureTapCallback? onTap,bool isSelect = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: Adapt.px(56),
        child: Text(
          title,
          style: TextStyle(
            color: isSelect ? ThemeColor.purple1 : ThemeColor.color0,
            fontSize: Adapt.px(16),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  void _updateChannelCurrentIndex(int index){
    setState(() {
      _channelCurrentIndex = index;
    });
    OXNavigator.pop(context);
  }

  void _updateGroupType(GroupType groupType) {
    setState(() {
      _groupType = groupType;
    });
  }

  @override
  void didLoginSuccess(UserDBISAR? userInfo) {
    // TODO: implement didLoginSuccess
    _isLogin = true;
    setState(() {});
  }

  @override
  void didLogout() {
    // TODO: implement didLogout
    LogUtil.e("find.didLogout()");
    _isLogin = false;
    setState(() {});
  }

  @override
  void didSwitchUser(UserDBISAR? userInfo) {
    // TODO: implement didSwitchUser
    _isLogin = OXUserInfoManager.sharedInstance.isLogin;
    setState(() {});
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;

  @override
  void didRelayStatusChange(String relay, int status) {
    setState(() {});
  }

  onThemeStyleChange() {
    if (mounted) setState(() {});
  }

  onLocaleChange() {
    if (mounted) setState(() {});
  }

  @override
  void updateClickNum(int num,bool isChangeToDiscovery) {
    if (pageType == EDiscoveryPageType.channel) return _groupPageClickAction(num, isChangeToDiscovery);
    if(num == 1) return _momentPublic(isChangeToDiscovery);
    publicMomentPageKey.currentState?.updateNotesList(true,isWrapRefresh:true);
  }

  void _groupPageClickAction(int num, bool isChangeToDiscovery) {
    if (num == 1 && !isChangeToDiscovery) {
      groupsPageState.currentState?.scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else if (num == 2) {
      groupsPageState.currentState!.refreshController.requestRefresh();
    }
  }
}
