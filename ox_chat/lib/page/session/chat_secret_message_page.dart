import 'dart:io';

import 'package:chatcore/chat-core.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:ox_chat/utils/message_prompt_tone_mixin.dart';
import 'package:ox_chat/widget/common_chat_widget.dart';
import 'package:ox_chat/widget/not_contact_top_widget.dart';
import 'package:ox_chat/widget/secret_hint_widget.dart';
import 'package:ox_chat_ui/ox_chat_ui.dart';
import 'package:ox_common/business_interface/ox_chat/utils.dart';
import 'package:ox_common/model/chat_type.dart';
import 'package:ox_common/utils/ox_chat_binding.dart';
import 'package:ox_common/utils/ox_chat_observer.dart';
import 'package:ox_common/utils/string_utils.dart';
import 'package:ox_common/widgets/common_hint_dialog.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_chat/manager/chat_data_cache.dart';
import 'package:ox_chat/utils/general_handler/chat_general_handler.dart';
import 'package:ox_chat/utils/widget_tool.dart';
import 'package:ox_common/widgets/avatar.dart';
import 'package:ox_common/model/chat_session_model_isar.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/widgets/common_appbar.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:screen_protector/screen_protector.dart';

class ChatSecretMessagePage extends StatefulWidget {
  final ChatSessionModelISAR communityItem;
  final String? anchorMsgId;

  const ChatSecretMessagePage({Key? key, required this.communityItem, this.anchorMsgId}) : super(key: key);

  @override
  State<ChatSecretMessagePage> createState() => _ChatSecretMessagePageState();
}

class _ChatSecretMessagePageState extends State<ChatSecretMessagePage> with OXChatObserver, MessagePromptToneMixin, ChatGeneralHandlerMixin {

  late ChatGeneralHandler chatGeneralHandler;
  List<types.Message> _messages = [];

  bool isShowContactMenu = true;

  SecretSessionDBISAR? _secretSessionDB;
  UserDBISAR? get otherUser => chatGeneralHandler.otherUser;

  ChatHintParam? bottomHintParam;

  @override
  ChatSessionModelISAR get session => widget.communityItem;

  String get sessionId => widget.communityItem.chatId;

  @override
  void initState() {
    setupChatGeneralHandler();
    super.initState();

    OXChatBinding.sharedInstance.addObserver(this);
    protectScreen();
    initSecretData();
    prepareData();
    addListener();
  }

  @override
  void dispose() {
    OXChatBinding.sharedInstance.removeObserver(this);
    ChatDataCache.shared.removeObserver(widget.communityItem);
    disProtectScreen();
    super.dispose();
  }

  void protectScreen() async {
    if (Platform.isAndroid) {
      await ScreenProtector.protectDataLeakageOn();
    } else if (Platform.isIOS) {
      await ScreenProtector.preventScreenshotOn();
      ScreenProtector.addListener(() {
        final key = 'ox_chat.screenshot_hint_message';
        chatGeneralHandler.sendSystemMessage(
          context,
          Localized.text(key).replaceAll(r'${user}', Localized.text('ox_common.you')).capitalize(),
          localTextKey: key,
        );
      }, (p0) {
        final key = 'ox_chat.screen_record_hint_message';
        chatGeneralHandler.sendSystemMessage(
          context,
          Localized.text(key).replaceAll(r'${user}', Localized.text('ox_common.you')).capitalize(),
          localTextKey: key,
        );
      });
    }
  }

  void disProtectScreen() async {
    if (Platform.isAndroid) {
      await ScreenProtector.protectDataLeakageOff();
    } else if (Platform.isIOS) {
      await ScreenProtector.preventScreenshotOff();
      ScreenProtector.removeListener();
    }
  }

  void initSecretData() {
    if (widget.communityItem.chatType == ChatType.chatSecret || widget.communityItem.chatType == ChatType.chatSecretStranger) {
      setState(() {
        _secretSessionDB = Contacts.sharedInstance.secretSessionMap[widget.communityItem.chatId];
      });
    }
  }

  void setupChatGeneralHandler() {
    chatGeneralHandler = ChatGeneralHandler(
      session: widget.communityItem,
      refreshMessageUI: (messages) {
        setState(() {
          if (messages != null) _messages = messages;
        });
      },
      fileEncryptionType: types.EncryptionType.encrypted,
    );
  }

  void prepareData() {
    _loadMoreMessages();
    _updateChatStatus();
    ChatDataCache.shared.setSessionAllMessageIsRead(widget.communityItem);
  }

  void addListener() {
    ChatDataCache.shared.addObserver(widget.communityItem, (value) {
      chatGeneralHandler.refreshMessage(_messages, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.color200,
      resizeToAvoidBottomInset: false,
      appBar: CommonAppBar(
        useLargeTitle: false,
        centerTitle: true,
        title: otherUser?.getUserShowName() ?? '',
        titleWidget: Center(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.only(top: Adapt.px(2)),
                child: CommonImage(
                  iconName: 'icon_lock_secret.png',
                  width: Adapt.px(16),
                  height: Adapt.px(16),
                  package: 'ox_chat',
                ),
              ),
              SizedBox(
                width: Adapt.px(4),
              ),
              Text(
                otherUser?.getUserShowName() ?? '',
                style: TextStyle(
                  color: ThemeColor.color0,
                  fontSize: Adapt.px(17),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: ThemeColor.color200,
        backCallback: () {
          OXNavigator.popToRoot(context);
        },
        actions: [
          Container(
            alignment: Alignment.center,
            child: OXUserAvatar(
              isSecretChat:true,
              chatId: widget.communityItem.chatId,
              user: otherUser,
              size: Adapt.px(36),
              isClickable: true,
              onReturnFromNextPage: () {
                setState(() {});
              },
            ),
          ).setPadding(EdgeInsets.only(right: Adapt.px(24))),
        ],
      ),
      body: CommonChatWidget(
        handler: chatGeneralHandler,
        messages: _messages,
        anchorMsgId: widget.anchorMsgId,
        customTopWidget: isShowContactMenu
            ? NotContactTopWidget(chatSessionModel: widget.communityItem, onTap: _hideContactMenu)
            : null,
        customCenterWidget: _messages.length > 0 ? null : SecretHintWidget(chatSessionModel: widget.communityItem),
        customBottomWidget: (_secretSessionDB == null || _secretSessionDB!.currentStatus == 2) ? null : customBottomWidget(),
        bottomHintParam: bottomHintParam,
      ),
    );
  }

  @override
  void didSecretChatAcceptCallBack(SecretSessionDBISAR ssDB) {
    setState(() {
      _secretSessionDB = ssDB;
    });
  }

  @override
  void didSecretChatRejectCallBack(SecretSessionDBISAR ssDB) {
    setState(() {
      _secretSessionDB = ssDB;
    });
  }

  @override
  void didContactUpdatedCallBack() {
    _updateChatStatus();
  }

  void _hideContactMenu() {
    setState(() {
      isShowContactMenu = false;
    });
  }

  void _updateChatStatus() {
    final userId = otherUser?.pubKey ?? '';
    if (userId.isEmpty) return ;

    final isContact = Contacts.sharedInstance.allContacts.containsKey(userId);
    isShowContactMenu = !isContact;
  }

  Widget customBottomWidget() {
    UserDBISAR? otherDB = Account.sharedInstance.userCache[widget.communityItem.getOtherPubkey]?.value;
    String showUsername = otherDB?.getUserShowName() ?? '';
    String _hintText = '';
    String _leftBtnTxt = '';
    String _rightBtnTxt = '';
    if (_secretSessionDB!.currentStatus == 0) {
      _hintText = 'str_waiting_other_join'.localized({r'$username': showUsername});
    } else if (_secretSessionDB!.currentStatus == 1) {
      _leftBtnTxt = 'str_reject_secret_chat'.localized();
      _rightBtnTxt = 'str_john_secret_chat'.localized();
    } else if (_secretSessionDB!.currentStatus == 3) {
      _hintText = Localized.text('ox_chat.str_other_rejected');
    } else if (_secretSessionDB!.currentStatus == 6) {
      _hintText = Localized.text('ox_chat.str_other_expired');
    }

    return Container(
      width: double.infinity,
      height: Adapt.px(58),
      margin: EdgeInsets.only(
        left: Adapt.px(12),
        right: Adapt.px(12),
        bottom: Adapt.px(30),
      ),
      decoration: BoxDecoration(
        color: ThemeColor.color190,
        borderRadius: BorderRadius.circular(Adapt.px(12)),
      ),
      alignment: Alignment.center,
      child: GestureDetector(
        child: _secretSessionDB!.currentStatus == 1
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: Adapt.px(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          _rejectSecretChat();
                        },
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          alignment: Alignment.center,
                          child: Text(
                            _leftBtnTxt,
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: ThemeColor.color100,
                              fontSize: Adapt.px(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          _johnSecretChat();
                        },
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          alignment: Alignment.center,
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
                              _rightBtnTxt,
                              style: TextStyle(
                                fontSize: Adapt.px(14),
                                letterSpacing: Adapt.px(0.4),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: Adapt.px(50)),
                child: Text(
                  _hintText,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: ThemeColor.color100,
                    fontSize: Adapt.px(14),
                  ),
                ),
              ),
        onTap: () {
          setState(() {});
        },
      ),
    );
  }

  Future<void> _loadMoreMessages() async {
    await chatGeneralHandler.loadMoreMessage(_messages);
  }

  void _rejectSecretChat() async {
    OXCommonHintDialog.show(context,
        title: '',
        content: Localized.text('ox_chat.secret_message_reject_tips'),
        actionList: [
          OXCommonHintAction.cancel(onTap: () {
            OXNavigator.pop(context);
          }),
          OXCommonHintAction.sure(
              text: Localized.text('ox_common.confirm'),
              onTap: () async {
                await OXLoading.show();
                final OKEvent okEvent = await Contacts.sharedInstance.reject(_secretSessionDB!.sessionId);
                await OXLoading.dismiss();
                if (okEvent.status) {
                  UserDBISAR? toPubkeyUserDB = Contacts.sharedInstance.allContacts[_secretSessionDB!.toPubkey];
                  await OXChatBinding.sharedInstance.deleteSession(
                    [widget.communityItem.chatId],
                    isStranger: toPubkeyUserDB == null,
                  );
                  OXNavigator.pop(context); //pop dialog
                  OXNavigator.pop(context); //pop page
                } else {
                  CommonToast.instance.show(context, okEvent.message);
                }
              }),
        ],
        isRowAction: true);
  }

  void _johnSecretChat() async {
    await OXLoading.show();
    final OKEvent okEvent = await Contacts.sharedInstance.accept(_secretSessionDB!.sessionId);
    await OXLoading.dismiss();
    if (okEvent.status) {
      OXChatBinding.sharedInstance.updateChatSession(
        widget.communityItem.chatId,
        content: 'secret_chat_accepted_tips'.localized({r"${name}": otherUser?.name ?? ''}),
      );
      OXChatBinding.sharedInstance.changeChatSessionType(widget.communityItem, true);
      setState(() {});
    } else {
      CommonToast.instance.show(context, okEvent.message);
    }
  }
}
