import 'dart:async';
import 'dart:convert';

import 'package:chatcore/chat-core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:ox_chat/page/contacts/contact_friend_user_info_page.dart';
import 'package:ox_chat/utils/widget_tool.dart';
import 'package:ox_chat/widget/alpha.dart';
import 'package:ox_chat/widget/avatar.dart';
import 'package:ox_common/log_util.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ox_localizable/ox_localizable.dart';

typedef void OnTouchCallback(int index);

const double headerHeight = 30.0;
const double itemHeight = 62.0;

class ContractWidget extends StatefulWidget {
  final List<UserDB> data;
  final bool editable;
  final onSelectChanged;
  String hostName = ''; //The current domain

  ContractWidget({
    Key? key,
    required this.data,
    this.editable = false,
    this.onSelectChanged,
    this.hostName = 'ox.com',
  }) : super(key: key);

  @override
  State createState() {
    return ContractWidgetState();
  }
}

class Note {
  String tag;
  List<UserDB> childList;

  Note(this.tag, this.childList);
}

class ContractWidgetState<T extends ContractWidget> extends State<T> {
  late List<UserDB> _data;
  ScrollController scrollController = ScrollController();
  List<String> indexTagList = [];
  List<UserDB>? userList;
  int defaultIndex = 0;

  List<Note> noteList = [];

  String _tagName = '';
  bool _isTouchTagBar = false;

  List<UserDB> selectedList = [];
  Map<String, List<UserDB>> mapData = Map();
  String mHostName = '';

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _initIndexBarData();
    scrollController.addListener(() {
      double position = scrollController.offset.toDouble();
      int index = _computerIndex(position);
      defaultIndex = index;
    });

    initFromCache();
  }

  void initFromCache() async {}

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void updateContactData(List<UserDB> data) {
    _data = data;
    _initIndexBarData();
  }

  void _initIndexBarData() {
    userList = _data;
    indexTagList.clear();
    mapData.clear();
    noteList.clear();
    if (null == userList || userList?.length == 0) return;

    ALPHAS_INDEX.forEach((v) {
      mapData[v] = [];
    });

    userList!.sort((v1, v2) {
      return PinyinHelper.getFirstWordPinyin((v1.nickName != null && v1.nickName!.isNotEmpty) ? v1.nickName! : v1.name!)
          .compareTo(PinyinHelper.getFirstWordPinyin(v1.nickName != null ? v1.nickName! : v2.name!));
    });

    userList!.forEach((item) {
      if (item.pubKey == '') return;
      if (item.name!.isEmpty) item.name = 'unknown';
      // if (item.userType == systemUserType) {
      //   mapData["☆"]?.insert(0, item);
      //   return;
      // }
      var cTag =
          PinyinHelper.getFirstWordPinyin((item.nickName != null && item.nickName!.isNotEmpty) ? item.nickName! : item.name!).substring(0, 1).toUpperCase();
      // if (EnumTypeUtils.checkShiftOperation(item.userType!, 0)) {
      //   cTag = "☆";
      // } else if (!ALPHAS_INDEX.contains(cTag)){ cTag = '#';}
      if (!ALPHAS_INDEX.contains(cTag)) {
        cTag = '#';
      }
      mapData[cTag]?.add(item);
    });

    mapData.forEach((tag, list) {
      if (list.isNotEmpty) {
        indexTagList.add(tag);
        noteList.add(Note(tag, list));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ThemeColor.color200,
      child: userList == null || userList!.isEmpty
          ? _emptyWidget()
          : Stack(
              alignment: AlignmentDirectional.centerEnd,
              children: <Widget>[
                CustomScrollView(
                  slivers: _buildSlivers(context),
                  physics: AlwaysScrollableScrollPhysics(),
                  controller: scrollController,
                ),
                Container(
                  child: _buildAlphaBar(),
                  width: 30,
                ),
                _isTouchTagBar ? _buildCenterModal() : Container(),
              ],
            ),
    );
  }

  Widget _emptyWidget() {
    return Container(
      alignment: Alignment.topCenter,
      margin: EdgeInsets.only(top: 87.0),
      child: Column(
        children: <Widget>[
          assetIcon(
            'icon_search_user_no.png',
            110.0,
            110.0,
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: MyText(
              Localized.text('ox_chat.no_contacts_added'),
              14,
              ThemeColor.gray02,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  int _computerIndex(double position) {
    for (int i = 0; i < noteList.length; i++) {
      double pre = _computerIndexPosition(i);
      double next = _computerIndexPosition(i + 1);
      if (position > pre && position < next) {
        return i;
      }
    }
    return 0;
  }

  double _computerIndexPosition(int index) {
    int n = 0;
    for (int i = 0; i < index; i++) {
      n += noteList[i].childList.length;
    }
    return n * itemHeight + index * headerHeight;
  }

  /// Used to control the disappearance of letters
  Timer? timer;

  void _onTouchCallback(int index) {
    if (defaultIndex != index) {
      if (null != timer && timer!.isActive) {
        timer!.cancel();
        timer = null;
      }
      var offset = _computerIndexPosition(index).clamp(.0, scrollController.position.maxScrollExtent);
      scrollController.jumpTo(offset.toDouble());
      defaultIndex = index;
    }

    timer = Timer(Duration(milliseconds: 300), () {
      setState(() {
        _isTouchTagBar = false;
      });
    });
  }

  /// Generate a modal with the middle letter prompt
  Widget _buildCenterModal() {
    return Center(
      child: Card(
        elevation: 0,
        color: ThemeColor.gray6,
        child: Container(
          alignment: Alignment.center,
          width: 60.0,
          height: 60.0,
          child: Text(
            _tagName,
            style: TextStyle(
              fontSize: 32.0,
              color: ThemeColor.titleColor,
            ),
          ),
        ),
      ),
    );
  }

  void _onCheckChangedListener(bool checked, UserDB item) {
    if (checked)
      selectedList.add(item);
    else
      selectedList.remove(item);
    widget.onSelectChanged(selectedList);
  }

  List<Widget> _buildSlivers(BuildContext context) {
    List<Widget> slivers = [];

    noteList.forEach((item) {
      slivers.add(
        SliverStickyHeader(
          header: Visibility(
            visible: item.tag != "☆",
            child: HeaderWidget(
              tag: item.tag,
            ),
          ),
          sliver: SliverList(
            delegate: new SliverChildBuilderDelegate(
              (context, i) {
                return ContractListItem(
                  item: item.childList[i],
                  editable: widget.editable,
                  onCheckChanged: _onCheckChangedListener,
                  hostName: widget.hostName,
                );
              },
              childCount: item.childList.length,
            ),
          ),
        ),
      );
    });
    slivers.add(
        SliverStickyHeader(
          header: SizedBox(
            height: Adapt.px(96),
          ),
        ),
    );
    return slivers;
  }

  Widget _buildAlphaBar() {
    return Alpha(
      alphas: indexTagList,
      fontColor: ThemeColor.gray2,
      fontActiveColor: ThemeColor.white02,
      onAlphaChange: (value) {
        setState(() {
          if (!_isTouchTagBar) {
            _isTouchTagBar = true;
          }
          _tagName = value;
        });

        int index = indexTagList.indexOf(value);
        _onTouchCallback(index);
      },
      onTouchEnd: () {
        _onTouchCallback(defaultIndex);
      },
      onTouchStart: () {
        setState(() {
          _isTouchTagBar = true;
        });
        _onTouchCallback(defaultIndex);
      },
    );
  }
}

class HeaderWidget extends StatelessWidget {
  String tag;

  HeaderWidget({Key? key, this.tag = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: headerHeight,
      color: ThemeColor.color200,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(
        left: Adapt.px(24.0),
      ),
      child: MyText(
        tag,
        14,
        ThemeColor.color10,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class ContractListItem extends StatefulWidget {
  late UserDB item;

  final onCheckChanged;
  final bool editable;

  String hostName = ''; //The current domain

  ContractListItem({
    required this.item,
    this.editable = false,
    this.onCheckChanged,
    this.hostName = 'ox.com',
  });

  @override
  State createState() {
    return _ContractListItemState();
  }
}

class _ContractListItemState extends State<ContractListItem> {
  bool isChecked = false;

  void _onCheckChanged() {
    setState(() {
      isChecked = !isChecked;
    });
    widget.onCheckChanged(isChecked, widget.item);
  }

  void _onItemClick() async {
    if (widget.item.pubKey != null && widget.item.pubKey!.isNotEmpty) {
      UserDB? userDB = Friends.sharedInstance.friends[widget.item.pubKey] as UserDB;
      OXNavigator.pushPage(context, (context) => ContactFriendUserInfoPage(userDB: userDB));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget iconAvatar = OXUserAvatar(user: widget.item);
    // if (widget.item.userType == systemUserType) {
    //   iconAvatar =
    //       ClipRRect(borderRadius: BorderRadius.circular(76), child: assetIcon('icon_notice_avatar.png', 76, 76));
    // }
    Image badgePlaceholderImage = Image.asset(
      'assets/images/icon_badge_default.png',
      fit: BoxFit.cover,
      width: Adapt.px(20),
      height: Adapt.px(20),
      package: 'ox_common',
    );
    Widget checkWidget = isChecked
        ? assetIcon(
            'icon_item_selected.png',
            24.0,
            24.0,
            useTheme: false,
          )
        : assetIcon(
            'icon_item_not_selected.png',
            24.0,
            24.0,
            useTheme: true,
          );
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.editable ? _onCheckChanged : _onItemClick,
      child: Container(
        color: ThemeColor.color200,
        width: double.infinity,
        padding: EdgeInsets.only(left: Adapt.px(24.0), top: Adapt.px(10.0), bottom: Adapt.px(10.0)),
        child: Row(
          children: <Widget>[
            widget.editable
                ? Container(
                    margin: EdgeInsets.only(right: Adapt.px(7.0)),
                    child: checkWidget,
                  )
                : Container(),
            Stack(
              children: [
                iconAvatar,
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: FutureBuilder<BadgeDB?>(
                    builder: (context, snapshot) {
                      return (snapshot.data !=null && snapshot.data!.thumb != null) ? CachedNetworkImage(
                        imageUrl: snapshot.data?.thumb ?? '',
                        errorWidget: (context, url, error) => badgePlaceholderImage,
                        width: Adapt.px(20),
                        height: Adapt.px(20),
                        fit: BoxFit.cover,
                      ) : Container();
                    },
                    future: _getUserSelectedBadgeInfo(widget.item),
                  ),
                ),
              ],
            ),
            Container(
              width: Adapt.screenW() - Adapt.px(120),
              margin: EdgeInsets.only(left: Adapt.px(16.0)),
              child: MyText(
                (widget.item.nickName != null && widget.item.nickName!.isNotEmpty) ? widget.item.nickName! : widget.item.name ?? '',
                18,
                ThemeColor.white02,
                fontWeight: FontWeight.bold,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<BadgeDB?> _getUserSelectedBadgeInfo(UserDB friendDB) async {
    UserDB? friendUserDB = Friends.sharedInstance.friends[friendDB.pubKey];
    if (friendUserDB == null) {
      return null;
    }
    String badges = friendUserDB!.badges ?? '';
    if (badges.isNotEmpty) {
      List<dynamic> badgeListDynamic = jsonDecode(badges);
      List<String> badgeList = badgeListDynamic.cast();
      BadgeDB? badgeDB;
      try {
        List<BadgeDB?> badgeDBList = await BadgesHelper.getBadgeInfosFromDB(badgeList);
        badgeDB = badgeDBList.first;
      } catch (error) {
        LogUtil.e("user selected badge info fetch failed: $error");
      }
      return badgeDB;
    }
    return null;
  }
}
