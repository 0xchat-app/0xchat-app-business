import 'package:chatcore/chat-core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:ox_chat/manager/chat_message_helper.dart';
import 'package:ox_common/log_util.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/utils/ox_chat_binding.dart';
import 'package:ox_common/utils/ox_userinfo_manager.dart';
import 'package:ox_common/widgets/common_appbar.dart';
import 'package:ox_common/widgets/common_textfield.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_localizable/ox_localizable.dart';

class ContactFriendRemarkPage extends StatefulWidget {
  final UserDB userDB;

  ContactFriendRemarkPage({Key? key, required this.userDB}) : super(key: key);

  @override
  State<ContactFriendRemarkPage> createState() => _ContactFriendRemarkPageState();
}

class _ContactFriendRemarkPageState extends State<ContactFriendRemarkPage> {
  TextEditingController _editingController = TextEditingController();
  FocusNode _codeFocusNode = new FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _editingController.text = widget.userDB.nickName != null && widget.userDB.nickName!.isNotEmpty ? widget.userDB.nickName! : (widget.userDB.name ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.color200,
      resizeToAvoidBottomInset: false,
      appBar: CommonAppBar(
        useLargeTitle: false,
        centerTitle: true,
        title: '',
        backgroundColor: ThemeColor.color200,
        actions: [
          Container(
            margin: EdgeInsets.only(right: Adapt.px(24)),
            height: double.infinity,
            alignment: Alignment.centerRight,
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _settingRemark();
              },
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    colors: [
                      ThemeColor.gradientMainEnd,
                      ThemeColor.gradientMainStart,
                    ],
                  ).createShader(Offset.zero & bounds.size);
                },
                child: Text(
                  Localized.text('ox_common.complete'),
                  style: TextStyle(
                    fontSize: Adapt.px(16),
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.only(left: Adapt.px(30), right: Adapt.px(30), top: Adapt.px(24)),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              alignment: Alignment.topCenter,
              child: Text(
                'Edit Remark',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: Adapt.px(24),
                  color: ThemeColor.color0,
                ),
              ),
            ),
            CommonTextField(
              controller: _editingController,
              hintText: widget.userDB.nickName ?? 'Please enter a nickname',
              title: 'Remark',
              type: TextFieldType.normal,
              keyboardType: TextInputType.text,
              inputFormatters: [LengthLimitingTextInputFormatter(30)],
              needCaptchaButton: true,
              captchaButtonEnable: true,
              captachaOnPressed: () {
                LogUtil.e('Michael: CommonTextField captachaOnPressed');
              },
              focusNode: _codeFocusNode,
              margin: EdgeInsets.only(top: Adapt.px(24),),
            ),
            SizedBox(
              height: Adapt.px(48),
            ),
          ],
        ),
      ),
    );
  }

  void _settingRemark() async {
    String remarkValue = _editingController.text.toString();
    final pubKey = widget.userDB.pubKey;
    if (widget.userDB.nickName == remarkValue) {
      OXNavigator.pop(context);
      return ;
    }
    if(pubKey == null){
      CommonToast.instance.show(context, 'Account abnormally');
      return;
    }
    await OXLoading.show();
    final OKEvent okEvent = await Friends.sharedInstance.updateFriendNickName(pubKey, remarkValue);
    await OXLoading.dismiss();
    if (okEvent.status) {
      widget.userDB.nickName = remarkValue;
      OXChatBinding.sharedInstance.updateChatSession(pubKey, chatName: widget.userDB.getUserShowName());
      OXNavigator.pop(context, remarkValue);
    } else {
      CommonToast.instance.show(context, okEvent.message);
    }

  }
}
