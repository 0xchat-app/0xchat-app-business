import 'package:flutter/material.dart';

import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';

import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:flutter/services.dart';

import 'package:chatcore/chat-core.dart';

import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';



class ContactRelayPage extends StatefulWidget {
  final UserDB userDB;

  ContactRelayPage({Key? key, required this.userDB}) : super(key: key);
  @override
  _ContactRelayPage createState() => new _ContactRelayPage();
}

class _ContactRelayPage extends State<ContactRelayPage> {
  final TextEditingController _relayTextFieldController =
  TextEditingController();
  bool _isShowDelete = false;
  List<String> _relaysList = [];

  int? _selectRelayIndex = 0;

  @override
  void initState() {
    super.initState();
    _getRelays();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: ThemeColor.color190, borderRadius: BorderRadius.circular(20)),
      child: SafeArea(
        child: Container(
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _appBar(),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: Adapt.px(12),
            horizontal: Adapt.px(24),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            Localized.text('ox_chat.enter_or_relay'),
            style: TextStyle(
              color: ThemeColor.color0,
              fontSize: Adapt.px(16),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _inputRelayView(),
        SizedBox(
          height: Adapt.px(12),
        ),
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: Adapt.px(24),
            ),
            alignment: Alignment.center,
            child: ListView.builder(
              primary: false,
              itemCount: _relaysList.length,
              itemBuilder: (context, index) => _relayItemWidget(index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _appBar() {
    return Container(
      height: Adapt.px(56),
      padding: EdgeInsets.symmetric(
        horizontal: Adapt.px(24),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              OXNavigator.pop(context);
            },
            child: CommonImage(
              iconName: "title_close.png",
              width: Adapt.px(24),
              height: Adapt.px(24),
              useTheme: true,
            ),
          ),
          Expanded(
            child: Container(
              child: Text(
                'Relay',
                style: TextStyle(
                  color: ThemeColor.color0,
                  fontSize: Adapt.px(17),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          GestureDetector(
            onTap: _createSecretChat,
            child: Center(
              child: CommonImage(
                iconName: 'icon_done.png',
                width: Adapt.px(24),
                height: Adapt.px(24),
                useTheme: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputRelayView() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Adapt.px(24),
      ),
      width: double.infinity,
      height: Adapt.px(48),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: ThemeColor.color180,
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(left: Adapt.px(16)),
            width: Adapt.px(24),
            height: Adapt.px(24),
            child: CommonImage(
              iconName: 'icon_relay_paste.png',
              width: Adapt.px(24),
              height: Adapt.px(24),
              package: 'ox_usercenter',
              useTheme: true,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _relayTextFieldController,
              decoration: InputDecoration(
                hintText: 'wss://some.relay.com',
                hintStyle: TextStyle(
                  color: ThemeColor.color100,
                  fontSize: Adapt.px(15),
                ),
                suffixIcon: _delTextIconWidget(),
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (str) {
                setState(() {
                  if (str.isNotEmpty) {
                    _isShowDelete = true;
                    _selectRelayIndex = null;
                  } else {
                    _isShowDelete = false;
                    _selectRelayIndex = 0;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget? _delTextIconWidget() {
    if (!_isShowDelete) return null;
    return IconButton(
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      onPressed: () {
        setState(() {
          _relayTextFieldController.text = '';
          _isShowDelete = false;
          _selectRelayIndex = 0;
        });
      },
      icon: CommonImage(
        iconName: 'icon_textfield_close.png',
        width: Adapt.px(16),
        height: Adapt.px(16),
      ),
    );
  }

  Widget _relayItemWidget(int index) {
    String relay = _relaysList[index];

    return GestureDetector(
      onTap: () {
        if (_selectRelayIndex == null) {
          _selectRelayIndex = index;
        } else {
          _selectRelayIndex = _selectRelayIndex == index ? null : index;
        }
        setState(() {});
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: ThemeColor.color180,
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                vertical: Adapt.px(10),
                horizontal: Adapt.px(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CommonImage(
                        iconName: 'icon_settings_relays.png',
                        width: Adapt.px(32),
                        height: Adapt.px(32),
                        package: 'ox_usercenter',
                      ),
                      Container(
                        padding: EdgeInsets.only(
                          left: Adapt.px(12),
                        ),
                        child: Text(
                          relay,
                          style: TextStyle(
                            color: ThemeColor.color0,
                            fontSize: Adapt.px(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _selectFollowsWidget(index),
                ],
              ),
            ),
            _dividerWidget(index),
          ],
        ),
      ),
    );
  }

  Widget _selectFollowsWidget(int index) {
    bool isShowSelectIcon = _selectRelayIndex == index;
    if (!isShowSelectIcon) return Container();
    return CommonImage(
      iconName: 'icon_select_follows.png',
      width: Adapt.px(32),
      height: Adapt.px(32),
      package: 'ox_chat',
    );
  }

  Widget _dividerWidget(int index) {
    if (_relaysList.length - 1 == index) return Container();
    return Divider(
      height: Adapt.px(0.5),
      color: ThemeColor.color160,
    );
  }

  void _getRelays() {
    _relaysList = Connect.sharedInstance.relays();
    setState(() {});
  }

  void _createSecretChat() async {
    String chatRelay = _relaysList[_selectRelayIndex ?? 0];
    String inputText = _relayTextFieldController.text;
    if (_selectRelayIndex == null && !inputText.isNotEmpty) {
      CommonToast.instance.show(context, Localized.text('ox_chat.secret_chat_relay_enter_tips'),);
      return;
    }

    if (inputText.isNotEmpty) {
      if (!_isWssWithValidURL(_relayTextFieldController.text)) {
        CommonToast.instance.show(context, Localized.text('ox_chat.secret_chat_relay_input_right_wss_tips'),);
        return;
      }
      chatRelay = inputText;
    }
    OXNavigator.pop(context,chatRelay);

  }

  bool _isWssWithValidURL(String input) {
    RegExp regex = RegExp(
        r'^wss:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(:[0-9]{1,5})?(\/\S*)?$');
    return regex.hasMatch(input);
  }
}
