
import 'package:flutter/material.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/date_utils.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/widgets/avatar.dart';
import 'package:ox_common/widgets/common_appbar.dart';
import 'package:ox_common/widgets/common_hint_dialog.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/widgets/common_network_image.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';

import '../../../utils/widget_tool.dart';

enum ERequestsOption { accept, ignore }

class UserRequestInfo {
  final MessageDB messageDB;
  final String createTime;
  final String userName;
  final String groupId;
  final String groupName;
  final String content;
  final String userPic;
  bool isShowMore;
  UserRequestInfo({
    required this.messageDB,
    required this.userName,
    required this.groupId,
    required this.content,
    required this.groupName,
    required this.createTime,
    required this.userPic,
    required this.isShowMore,
  });
}

class GroupJoinRequests extends StatefulWidget {
  final String? groupId;

  GroupJoinRequests({required this.groupId});
  @override
  _GroupJoinRequestsState createState() => new _GroupJoinRequestsState();
}

class _GroupJoinRequestsState extends State<GroupJoinRequests> {
  List<UserRequestInfo> requestUserList = [];

  @override
  void initState() {
    super.initState();
    _getRequestList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _getRequestList() async {
    List<MessageDB> requestJoinList =
        await Groups.sharedInstance.getRequestList(groupId: widget.groupId);
    List<UserRequestInfo> requestList = [];
    if (requestJoinList.length > 0) {
      await Future.forEach(requestJoinList, (msgDB) async {
        GroupDB? groupDB = Groups.sharedInstance.groups[msgDB.groupId];
        UserDB? userDB = await Account.sharedInstance.getUserInfo(msgDB.sender);

        String time = OXDateUtils.convertTimeFormatString2(
            msgDB.createTime * 1000,
            pattern: 'MM-dd');
        requestList.add(new UserRequestInfo(
          messageDB: msgDB,
          userName: userDB?.name ?? '--',
          createTime: time,
          groupName: groupDB?.name ?? '--',
          userPic: userDB?.picture ?? '--',
          groupId: msgDB.groupId,
          content: msgDB.decryptContent,
          isShowMore: false,
        ));
      });
    }
    requestUserList = requestList;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.color190,
      appBar: CommonAppBar(
        useLargeTitle: false,
        centerTitle: true,
        title: Localized.text('ox_chat.join_request'),
        backgroundColor: ThemeColor.color190,
      ),
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                UserRequestInfo userModel = requestUserList.elementAt(index);
                return _userRequestItem(userModel);
              },
              childCount: requestUserList.length,
            ),
          ),
        ],
      ),
    );
  }


  Widget _userRequestItem(UserRequestInfo userInfo) {
    Widget placeholderImage = CommonImage(
      iconName: 'user_image.png',
      width: Adapt.px(76),
      height: Adapt.px(76),
    );
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: Adapt.px(12),
        horizontal: Adapt.px(24),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: OXCachedNetworkImage(
              errorWidget: (context, url, error) => placeholderImage,
              placeholder: (context, url) => placeholderImage,
              fit: BoxFit.fill,
              imageUrl: userInfo.userPic,
              width: Adapt.px(60),
              height: Adapt.px(60),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(
                left: Adapt.px(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Localized.text('ox_chat.request_join_item_text').replaceAll(r'${name}', '${userInfo.userName}'),
                    style: TextStyle(
                      color: ThemeColor.color0,
                      fontSize: Adapt.px(16),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Container(
                      padding: EdgeInsets.symmetric(
                        vertical: Adapt.px(4),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            userInfo.groupName,
                            style: TextStyle(
                              color: ThemeColor.color0,
                              fontSize: Adapt.px(16),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            userInfo.createTime,
                            style: TextStyle(
                              color: ThemeColor.color120,
                              fontSize: Adapt.px(14),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      )),
                  _userRequestInfoWidget(userInfo),
                  _optionBtnWidget(userInfo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userRequestInfoWidget(UserRequestInfo userInfo) {
    return Container(
      padding: EdgeInsets.only(
        bottom: Adapt.px(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: userInfo.isShowMore ? Adapt.px(250) : Adapt.px(180),
            child: Text(
              userInfo.content,
              softWrap: userInfo.isShowMore,
              overflow: userInfo.isShowMore ? null : TextOverflow.ellipsis,
              style: TextStyle(
                color: ThemeColor.color120,
                fontSize: Adapt.px(14),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          _showMoreBtnWidget(userInfo),
        ],
      ),
    );
  }

  Widget _showMoreBtnWidget(UserRequestInfo userInfo){
    if(userInfo.isShowMore) return Container();
      return GestureDetector(
        onTap: (){
          requestUserList.forEach((UserRequestInfo modelInfo) {
            if(modelInfo.messageDB == userInfo.messageDB){
              modelInfo.isShowMore = true;
            }
          });

          setState(() {});
        },
        child: Container(
          child: Text(
            Localized.text('ox_chat.request_join_show_more'),
            style: TextStyle(
              color: ThemeColor.purple2,
              fontSize: Adapt.px(14),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
  }

  Widget _emptyWidget() {
    return Container(
      alignment: Alignment.topCenter,
      margin: EdgeInsets.only(top: 87.0),
      child: Column(
        children: <Widget>[
          CommonImage(
            iconName: 'icon_no_login.png',
            width: Adapt.px(90),
            height: Adapt.px(90),
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: MyText(
              Localized.text('ox_chat.request_join_no_data'),
              14,
              ThemeColor.gray02,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionBtnWidget(UserRequestInfo userInfo) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _userRequestDialog(
                Localized.text('ox_chat.request_join_ignore_member'),
                () => _requestJoinOption(
                    userInfo.messageDB, ERequestsOption.ignore),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeColor.color180,
                  borderRadius: BorderRadius.all(
                    Radius.circular(
                      Adapt.px(24),
                    ),
                  ),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  vertical: Adapt.px(5),
                ),
                child: Text(
                  Localized.text('ox_chat.ignore_text'),
                ),
              ),
            ),
          ),
          SizedBox(
            width: Adapt.px(24),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _userRequestDialog(
                Localized.text('ox_chat.request_join_accept_member'),
                () => _requestJoinOption(
                    userInfo.messageDB, ERequestsOption.accept),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      ThemeColor.gradientMainEnd.withOpacity(0.24),
                      ThemeColor.gradientMainStart.withOpacity(0.24),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  vertical: Adapt.px(5),
                ),
                child: Text(
                  Localized.text('ox_chat.accept_text'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _userRequestDialog(String content, Function callback) async {
    OXCommonHintDialog.show(
      context,
      title: '',
      content: content,
      actionList: [
        OXCommonHintAction.cancel(onTap: () {
          OXNavigator.pop(context);
        }),
        OXCommonHintAction.sure(text: Localized.text('ox_common.confirm'), onTap: callback),
      ],
      isRowAction: true,
    );
  }

  void _requestJoinOption(MessageDB messageDB, ERequestsOption type) async {
    if (ERequestsOption.accept == type) {
      await Groups.sharedInstance.acceptRequest(messageDB, '');
    }

    if (ERequestsOption.ignore == type) {
      await Groups.sharedInstance.ignoreRequest(messageDB);
    }
    //
    List<UserRequestInfo> draftList = requestUserList;

    draftList.removeWhere((userInfo) => userInfo.messageDB == messageDB);
    requestUserList = draftList;

    CommonToast.instance.show(context, Localized.text('ox_chat.group_mute_operate_success_toast'));
    OXNavigator.pop(context);
    setState(() {});
  }
}
