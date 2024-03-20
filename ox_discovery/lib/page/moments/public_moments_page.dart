import 'dart:ui';
import 'dart:io';
import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/widgets/common_appbar.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:flutter/services.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:ox_localizable/ox_localizable.dart';

import '../../enum/moment_enum.dart';
import '../../model/moment_model.dart';
import '../../utils/moment_rich_text.dart';
import '../../utils/moment_widgets.dart';
import '../widgets/horizontal_scroll_widget.dart';
import '../widgets/moment_option_widget.dart';
import '../widgets/nine_palace_grid_picture_widget.dart';
import 'create_moments_page.dart';
import 'notifications_moments_page.dart';

class PublicMomentsPage extends StatefulWidget {
  const PublicMomentsPage({Key? key}) : super(key: key);

  @override
  State<PublicMomentsPage> createState() => _PublicMomentsPageState();
}

class _PublicMomentsPageState extends State<PublicMomentsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 24.px,
        ),
        margin: EdgeInsets.only(
          bottom: 100.px,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _newMomentTipsWidget(),
            _momentItemWidget(EMomentType.picture),
            _momentItemWidget(EMomentType.content),
            _momentItemWidget(EMomentType.video),
            _momentItemWidget(EMomentType.quote),
          ],
        ),
      ),
    );
  }

  Widget _momentItemWidget(EMomentType type) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 12.px,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _momentUserInfoWidget(),
          MomentRichText(
            text:
                "#0xchat it's worth noting that Satoshi Nakamoto's true identity remains unknown, and there is no publicly @Satoshi \nhttps://www.0xchat.com \nRead More",
          ),
          _momentTypeWidget(type),
          MomentOptionWidget(),
          // _momentOptionWidget()
        ],
      ),
    );
  }

  Widget _momentTypeWidget(EMomentType type) {
    Widget contentWidget = const SizedBox(width: 0);
       switch (type) {
      case EMomentType.picture:
        contentWidget = NinePalaceGridPictureWidget(
          width: 248.px,
        ).setPadding(EdgeInsets.only(bottom: 12.px));
        break;
      case EMomentType.quote:
        contentWidget = HorizontalScrollWidget();
        break;
      case EMomentType.video:
        contentWidget = Container(
          margin: EdgeInsets.only(
            bottom: 12.px,
          ),
          decoration: BoxDecoration(
            color: ThemeColor.color100,
            borderRadius: BorderRadius.all(
              Radius.circular(
                Adapt.px(12),
              ),
            ),
          ),
          width: 210.px,
          height: 154.px,
        );
        break;
      case EMomentType.content:
        break;
    }
    return contentWidget;
  }

  Widget _momentUserInfoWidget() {
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            child: Row(
              children: [
                MomentWidgets.clipImage(
                  imageName: 'moment_avatar.png',
                  borderRadius: 40.px,
                  imageSize: 40.px,
                ),
                Container(
                  margin: EdgeInsets.only(
                    left: 10.px,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Satoshi',
                        style: TextStyle(
                          color: ThemeColor.color0,
                          fontSize: 14.px,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Satosh@0xchat.com· 45s ago',
                        style: TextStyle(
                          color: ThemeColor.color120,
                          fontSize: 12.px,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          CommonImage(
            iconName: 'more_moment_icon.png',
            size: 20.px,
            package: 'ox_discovery',
          ),
        ],
      ),
    );
  }

  Widget _newMomentTipsWidget() {
    Widget _wrapContainerWidget(
        {required Widget leftWidget, required String rightContent,required GestureTapCallback onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40.px,
          padding: EdgeInsets.symmetric(
            horizontal: 12.px,
          ),
          decoration: BoxDecoration(
            color: ThemeColor.color180,
            borderRadius: BorderRadius.all(
              Radius.circular(
                Adapt.px(22),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leftWidget,
              SizedBox(
                width: 8.px,
              ),
              Text(
                rightContent,
                style: TextStyle(
                  color: ThemeColor.color0,
                  fontSize: 14.px,
                  fontWeight: FontWeight.w400,
                ),
              )
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.px),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _wrapContainerWidget(
            onTap: () {
              OXNavigator.pushPage(context, (context) => NotificationsMomentsPage());
            },
            leftWidget: _memberAvatarWidget(),
            rightContent: '10 new pots',
          ),
          SizedBox(
            width: 20.px,
          ),
          _wrapContainerWidget(
            onTap: () {
              OXNavigator.pushPage(context, (context) => NotificationsMomentsPage());
            },
            leftWidget: MomentWidgets.clipImage(
              imageName: 'moment_avatar.png',
              borderRadius: 26.px,
              imageSize: 26.px,
            ),
            rightContent: '2 replies',
          ),
        ],
      ),
    );
  }

  Widget _memberAvatarWidget() {
    int groupMemberNum = 4;
    if (groupMemberNum == 0) return Container();
    int renderCount = groupMemberNum > 8 ? 8 : groupMemberNum;
    return Container(
      margin: EdgeInsets.only(
        right: Adapt.px(0),
      ),
      constraints: BoxConstraints(
          maxWidth: Adapt.px(8 * renderCount + 8), minWidth: Adapt.px(26)),
      child: AvatarStack(
        settings: RestrictedPositions(
            // maxCoverage: 0.1,
            // minCoverage: 0.2,
            align: StackAlign.left,
            laying: StackLaying.first),
        borderColor: ThemeColor.color180,
        height: Adapt.px(26),
        avatars: _showMemberAvatarWidget(3),
      ),
    );
  }

  List<ImageProvider<Object>> _showMemberAvatarWidget(int renderCount) {
    List<ImageProvider<Object>> avatarList = [];
    for (var n = 0; n < renderCount; n++) {
      avatarList.add( const AssetImage('assets/images/moment_avatar.png',
          package: 'ox_discovery'));
    }
    return avatarList;
  }

}
