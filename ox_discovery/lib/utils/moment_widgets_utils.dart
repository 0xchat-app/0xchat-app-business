import 'package:chatcore/chat-core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/utils/uplod_aliyun_utils.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:ox_common/widgets/common_network_image.dart';
import 'package:ox_discovery/page/widgets/moment_rich_text_widget.dart';
import 'package:ox_module_service/ox_module_service.dart';

import '../model/moment_ui_model.dart';
import '../page/moments/moments_page.dart';
import 'discovery_utils.dart';


class MomentWidgetsUtils {
  static Widget clipImage({
    required double borderRadius,
    String? imageName,
    Widget? child,
    double imageHeight = 20,
    double imageWidth = 20,
    double? imageSize,
    package = 'ox_discovery',
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        borderRadius,
      ),
      child: child ??
          CommonImage(
            iconName: imageName ?? '',
            width: imageSize ?? imageWidth,
            height: imageSize ?? imageHeight,
            package: package,
          ),
    );
  }

  static Widget quoteMoment(BuildContext context,UserDB userDB, NotedUIModel notedUIModel, bool isOneLine,double width) {
    Widget _getImageWidget() {
      List<String> _getImagePathList = notedUIModel.getImageList;
      if (_getImagePathList.isEmpty) return const SizedBox();
      return ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(11.5.px),
          topRight: Radius.circular(11.5.px),
        ),
        child: Container(
          height: 172.px,
          color: ThemeColor.color100,
          child: OXCachedNetworkImage(
            imageUrl: _getImagePathList[0],
            fit: BoxFit.cover,
            placeholder: (context, url) => MomentWidgetsUtils.badgePlaceholderContainer(height:172,width: width),
            errorWidget: (context, url, error) => MomentWidgetsUtils.badgePlaceholderContainer(size:172,width: width),
            height: 172.px,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        OXNavigator.pushPage(
            context, (context) => MomentsPage(notedUIModel: ValueNotifier(notedUIModel)));
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 1.px,
            color: ThemeColor.color160,
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(
              11.5.px,
            ),
          ),
        ),
        child: Column(
          children: [
            _getImageWidget(),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.px),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        MomentWidgetsUtils.clipImage(
                          borderRadius: 40.px,
                          imageSize: 40.px,
                          child: OXCachedNetworkImage(
                            imageUrl: userDB.picture ?? '',
                            fit: BoxFit.cover,
                            width: 20.px,
                            height: 20.px,
                            placeholder: (context, url) => MomentWidgetsUtils.badgePlaceholderImage(size:20),
                            errorWidget: (context, url, error) => MomentWidgetsUtils.badgePlaceholderImage(size:20),
                          ),
                        ),
                        Text(
                          userDB.name ?? '--',
                          style: TextStyle(
                            fontSize: 12.px,
                            fontWeight: FontWeight.w500,
                            color: ThemeColor.color0,
                          ),
                        ).setPadding(
                          EdgeInsets.symmetric(
                            horizontal: 4.px,
                          ),
                        ),
                        Text(
                          DiscoveryUtils.getUserMomentInfo(userDB, notedUIModel.createAtStr)[0],
                          style: TextStyle(
                            fontSize: 12.px,
                            fontWeight: FontWeight.w400,
                            color: ThemeColor.color120,
                          ),
                        )
                      ],
                    ).setPaddingOnly(bottom: 4.px),
                    MomentRichTextWidget(
                      text: notedUIModel.noteDB.content,
                      textSize: 12.px,
                      maxLines: isOneLine ? 1 : 2,
                      isShowMoreTextBtn: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget videoMoment(context, String videoUrl, String? videoImagePath) {

    Widget _showImageWidget(){
      if(videoImagePath != null){
        return MomentWidgetsUtils.clipImage(
          borderRadius: 8.px,
          child: Image.asset(
            videoImagePath,
            width: 210.px,
            height: 210.px,
            fit: BoxFit.cover,
            package: null,
          ),
        );
      }

      return OXCachedNetworkImage(
        imageUrl: videoImagePath ?? UplodAliyun.getSnapshot(videoUrl),
        fit: BoxFit.fill,
        placeholder: (context, url) =>
            MomentWidgetsUtils.badgePlaceholderContainer(size: 210),
        errorWidget: (context, url, error) =>
            MomentWidgetsUtils.badgePlaceholderContainer(size: 210),
        width: 210.px,
      );
    }
    return GestureDetector(
      onTap: () {
        OXModuleService.pushPage(context, 'ox_chat', 'ChatVideoPlayPage', {
          'videoUrl': videoUrl,
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
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
          ),
          MomentWidgetsUtils.clipImage(
            borderRadius: 16,
            child: _showImageWidget(),
          ).setPaddingOnly(bottom: 20.px),
          // VideoCoverWidget(videoUrl:videoUrl),
          CommonImage(
            iconName: 'play_moment_icon.png',
            package: 'ox_discovery',
            size: 60.0.px,
            color: Colors.white,
          )
        ],
      ),
    );
  }

  static Widget emptyNoteMoment(String content,double height){
    return Container(
      margin: EdgeInsets.symmetric(
          vertical: 10.px
      ),
      height: height.px,
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.px,
          color: ThemeColor.color160,
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(
            11.5.px,
          ),
        ),
      ),
      child: Center(
        child: Text(
          'Moment not found !',
          style: TextStyle(
            color: ThemeColor.color100,
            fontSize: 16.px,
          ),
        ),
      ),
    );
  }

  static Widget badgePlaceholderImage({int size = 24}) {
    return CommonImage(
      iconName: 'icon_badge_default.png',
      fit: BoxFit.cover,
      width: size.px,
      height: size.px,
      useTheme: true,
    );
  }

  static Widget badgePlaceholderContainer({int size = 24,double? width, double? height}) {
    return Container(
      width: width ?? size.px,
      height: height ?? size.px,
      color: ThemeColor.color180,
    );
  }

  static int getTextLine(String text,double width,int? maxLine){
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: text.trim(),),
      maxLines: maxLine ?? 100,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: width);
    bool isOver = textPainter.didExceedMaxLines;
    int lineCount = textPainter.computeLineMetrics().length;

    return lineCount;
  }
}