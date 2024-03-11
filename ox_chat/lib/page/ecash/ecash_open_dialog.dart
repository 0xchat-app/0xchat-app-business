
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:chatcore/chat-core.dart';
import 'package:easy_loading_button/easy_loading_button.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:ox_chat/manager/chat_data_cache.dart';
import 'package:ox_chat/manager/chat_message_helper.dart';
import 'package:ox_chat/manager/ecash_helper.dart';
import 'package:ox_chat/page/ecash/ecash_info.dart';
import 'package:ox_chat/utils/custom_message_utils.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/future_extension.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';

import 'ecash_detail_page.dart';

class EcashOpenDialog extends StatefulWidget {
  EcashOpenDialog({
    required this.package,
    required this.approveOnTap,
  });

  final EcashPackage package;
  final VoidCallback approveOnTap;

  @override
  State<StatefulWidget> createState() => EcashOpenDialogState();

  static Future<bool?> show({
    BuildContext? context,
    required EcashPackage package,
    required VoidCallback approveOnTap,
  }) {
    return OXNavigator.pushPage<bool>(
      context,
      (context) => EcashOpenDialog(
        package: package,
        approveOnTap: approveOnTap,
      ),
      type: OXPushPageType.transparent,
    );
  }
}

class EcashOpenDialogState extends State<EcashOpenDialog> with SingleTickerProviderStateMixin {

  static const themeColor = Color(0xFF7F38CA);

  String ownerName = '';
  bool isRedeemed = false;
  bool isForOtherUser = false;

  bool needSignature = false;
  bool isFinishSignature = true;
  bool nextSignatureIsMe = false;

  late AnimationController animationController;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();
    prepareAnimation();
    isRedeemed = widget.package.isRedeemed;
    isForOtherUser = widget.package.isForOtherUser;

    needSignature = widget.package.signees.isNotEmpty;
    if (needSignature) {
      isFinishSignature = widget.package.isFinishSignature;
      nextSignatureIsMe = widget.package.nextSignatureIsMe;
    }

    Account.sharedInstance.getUserInfo(widget.package.senderPubKey).handle((user) {
      setState(() {
        ownerName = user?.getUserShowName() ?? 'anonymity';
      });
    });
    animationController.forward(from: 0);
  }

  prepareAnimation() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    scaleAnimation = CurvedAnimation(
      parent: animationController,
      curve: ElasticOutCurve(0.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: popAction,
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: GestureDetector(
            onTap: () { },
            child: ScaleTransition(
              scale: scaleAnimation,
              child: Card(
                color: themeColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: 280.px,
                  padding: EdgeInsets.symmetric(horizontal: 20.px),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      buildTitle().setPaddingOnly(top: 60.px),
                      buildSubtitle().setPaddingOnly(top: 4.px),
                      buildIcon().setPaddingOnly(top: 40.px),
                      buildOptionArea(),
                      buildViewDetailButton().setPaddingOnly(top: 12.px),
                      buildBottomView().setPaddingOnly(top: 12.px),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTitle() {
    final text = isForOtherUser
        ? 'For ${EcashHelper.userListText(widget.package.receiver)} only'
        : widget.package.memo;
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
    );
  }

  Widget buildSubtitle() {
    return Text(
      '$ownerName\'s Ecash',
      style: TextStyle(
        color: Colors.white,
        fontSize: 12.sp,
        height: 1.4,
      ),
    );
  }

  Widget buildIcon() {
    return CommonImage(
      height: 100.px,
      width: 88.px,
      iconName: "icon_cashu_nut.png",
      package: 'ox_chat',
    );
  }

  Widget buildOptionArea() {
    Widget? child;
    if (needSignature && (!isFinishSignature || isForOtherUser)) {
      child = nextSignatureIsMe
          ? buildSignatureOption()
          : buildSignatureProcessView().setPaddingOnly(top: 24.px);
    }
    if (child == null) {
      child = isForOtherUser
          ? SizedBox()
          : buildRedeemOption();
    }

    return Container(
      height: 127.px,
      child: child,
    );
  }

  Widget buildSignatureProcessView() {
    final signees = widget.package.signees;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: signees.length,
      itemBuilder: (_, int index) {
        final (user, signature) = signees[index];
        final isFinish = signature.isNotEmpty;
        final color = ThemeColor.white.withOpacity(isFinish ? 1 : 0.6);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(user.getUserShowName()),
            Container(
              width: 15.px,
              height: 15.px,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 1,
                ),
              ),
              child: isFinish
                  ? Icon(
                Icons.check,
                color: color,
                size: 13.px,
              ) : null,
            )
          ],
        );
      },
      separatorBuilder: (_, __) => Divider(height: 4.px,)
    );
  }

  Widget buildSignatureOption() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        buildApproveButton(),
      ]
    );
  }

  Widget buildRedeemOption() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        buildRedeemButton()
      ],
    );
  }

  Widget buildRedeemButton() {
    return Opacity(
      opacity: isRedeemed ? 0.4 : 1,
      child: EasyButton(
        idleStateWidget: Center(
          child: Text(
            isRedeemed ? 'Redeemed' : 'Redeem',
            style: TextStyle(
              color: ThemeColor.darkColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        loadingStateWidget: const CircularProgressIndicator(
          strokeWidth: 3.0,
          valueColor: AlwaysStoppedAnimation<Color>(
            themeColor,
          ),
        ),
        height: 44.px,
        borderRadius: 22.px,
        contentGap: 6.0,
        buttonColor: Colors.white,
        onPressed: redeemPackage,
      ),
    );
  }

  Widget buildApproveButton() {
    return EasyButton(
      idleStateWidget: Center(
        child: Text(
          'Approve',
          style: TextStyle(
            color: ThemeColor.darkColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      loadingStateWidget: const CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          themeColor,
        ),
      ),
      height: 44.px,
      borderRadius: 22.px,
      contentGap: 6.0,
      buttonColor: Colors.white,
      onPressed: widget.approveOnTap,
    );
  }

  Widget buildViewDetailButton() {
    return GestureDetector(
      onTap: jumpToDetailPage,
      child: Text(
        'view detail',
        style: TextStyle(
          color: Colors.white,
          decoration: TextDecoration.underline,
          fontSize: 12.sp,
          height: 1.4,
        ),
      ),
    );
  }

  Widget buildBottomView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 0.5, color: Colors.white.withOpacity(0.4),),
        Container(
          height: 33.px,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cashu Ecash',
                style: TextStyle(
                  color: ThemeColor.white,
                  fontSize: 12.sp,
                ),
              ),
              CommonImage(
                iconName: 'icon_zaps_0xchat.png',
                package: 'ox_chat',
                size: Adapt.px(16),
              ),
            ],
          ),
        )
      ],
    );
  }

  void popAction() {
    OXNavigator.pop(context);
  }

  void jumpToDetailPage([bool requestRemote = true]) async {
    if (!widget.package.isAllReceive) {
      if (requestRemote) {
        OXLoading.show();
        await EcashHelper.updateReceiptHistoryForPackage(widget.package);
        OXLoading.dismiss();
      }
    }

    if (widget.package.isAllReceive || widget.package.isRedeemed) {
      updateMessageToRedeemedState(widget.package.messageId);
    }

    popAction();
    OXNavigator.pushPage(null, (context) => EcashDetailPage(
      package: widget.package,
    ));
  }

  void redeemPackage() async {
    if (isRedeemed) return ;

    final success = await EcashHelper.tryRedeemTokenList(widget.package);

    if (success == null) {
      CommonToast.instance.show(context, 'Redeem Failed, Please try again.');
      setState(() {
        isRedeemed = widget.package.isRedeemed;
      });
      return ;
    }
    if (success) {
      jumpToDetailPage(false);
    } else {
      CommonToast.instance.show(context, 'All tokens already spent.');
      setState(() {
        isRedeemed = widget.package.isRedeemed;
      });
    }

    updateMessageToRedeemedState(widget.package.messageId);
  }

  Future updateMessageToRedeemedState(String messageId) async {
    final messages = await Messages.loadMessagesFromDB(where: 'messageId = ?', whereArgs: [messageId]);
    final messageDB = (messages['messages'] as List<MessageDB>).firstOrNull;
    if (messageDB != null) {
      final chatKey = ChatDataCacheGeneralMethodEx.getChatTypeKeyWithMessage(messageDB);
      final uiMessage = await ChatDataCache.shared.getMessage(
        chatKey,
        null,
        messageId,
      );
      if (uiMessage is types.CustomMessage) {
        EcashMessageEx(uiMessage).isOpened = true;
        messageDB.decryptContent = jsonEncode(uiMessage.metadata);
        await DB.sharedInstance.update(messageDB);
        await ChatDataCache.shared.updateMessage(chatKey: chatKey, message: uiMessage);
      }
    }
  }

}
