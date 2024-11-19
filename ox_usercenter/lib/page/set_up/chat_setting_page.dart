import 'package:flutter/material.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/widgets/common_appbar.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_usercenter/utils/text_scale_slider.dart';

class ChatSettingPage extends StatefulWidget {
  const ChatSettingPage({super.key});

  @override
  State<ChatSettingPage> createState() => _ChatSettingPageState();
}

class _ChatSettingPageState extends State<ChatSettingPage> {
  double _textScale = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.color190,
      appBar: CommonAppBar(
        useLargeTitle: false,
        centerTitle: true,
        title: Localized.text('ox_usercenter.str_settings_chat'),
        backgroundColor: ThemeColor.color190,
      ),
      body: _buildBody().setPadding(
        EdgeInsets.symmetric(horizontal: 24.px, vertical: 12.px),
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        Column(
          children: [
            _buildChatWidget(
              name: 'Elon Musk',
              content: 'Good morning!\r\nDo you know what time it is？',
              picture: 'icon_chat_settings_left.png',
              isSender: false,
            ),
            SizedBox(height: 16.px),
            _buildChatWidget(
              name: 'Nika',
              content: 'It’s Morning in Tokyo',
              picture: 'icon_chat_settings_right.png',
            ),
          ],
        ),
        Positioned(
          bottom: 20.px,
          left: 0.px,
          right: 0.px,
          child: TextScaleSlider(
            onChanged: (value) {
              setState(() {
                _textScale = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatWidget({
    required String name,
    required String content,
    required String picture,
    bool isSender = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      textDirection: isSender ? TextDirection.rtl : TextDirection.ltr,
      children: [
        CommonImage(
          iconName: picture,
          width: 40.px,
          height: 40.px,
          package: 'ox_usercenter',
        ),
        SizedBox(width: 16.px),
        Expanded(
          child: Column(
            crossAxisAlignment:
                isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                name,
                textScaler: TextScaler.linear(_textScale),
                style: TextStyle(
                  fontSize: 12.px,
                  color: ThemeColor.color0,
                  height: 17.px / 12.px,
                ),
              ),
              SizedBox(height: 4.px),
              Container(
                padding: EdgeInsets.all(10.px),
                decoration: BoxDecoration(
                  color: ThemeColor.color180,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16.px),
                    bottomRight: Radius.circular(16.px),
                    bottomLeft: Radius.circular(16.px),
                  ),
                ),
                child: Text(
                  content,
                  textScaler: TextScaler.linear(_textScale),
                  style: TextStyle(
                    fontSize: 14.px,
                    color: ThemeColor.color0,
                    height: 20.px / 14.px,
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
