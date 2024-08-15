import 'dart:async';
import 'package:chatcore/chat-core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ox_cache_manager/ox_cache_manager.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_common/widgets/zaps/zaps_action_handler.dart';
import 'package:ox_discovery/page/widgets/zap_done_animation.dart';
import 'package:ox_localizable/ox_localizable.dart';

import '../../enum/moment_enum.dart';
import '../../model/moment_ui_model.dart';
import '../../utils/discovery_utils.dart';
import '../moments/create_moments_page.dart';
import '../moments/reply_moments_page.dart';

import 'package:flutter/services.dart';
import 'package:nostr_core_dart/nostr.dart';


class MomentOptionWidget extends StatefulWidget {
  final ValueNotifier<NotedUIModel?> notedUIModel;
  final bool isShowMomentOptionWidget;
  const MomentOptionWidget({super.key,required this.notedUIModel,this.isShowMomentOptionWidget = true});

  @override
  _MomentOptionWidgetState createState() => _MomentOptionWidgetState();
}

class _MomentOptionWidgetState extends State<MomentOptionWidget>
    with SingleTickerProviderStateMixin {

  late ValueNotifier<NotedUIModel?> notedUIModel;
  late final AnimationController _shakeController;
  bool _isDefaultEcashWallet = false;
  bool _isDefaultNWCWallet = false;
  bool _isZapProcessing = false;
  final Completer<bool> _completer = Completer();

  bool _reactionTag = false;

  final List<EMomentOptionType> momentOptionTypeList = [
    EMomentOptionType.reply,
    EMomentOptionType.repost,
    EMomentOptionType.like,
    EMomentOptionType.zaps,
  ];


  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(duration:const Duration(milliseconds: 800),vsync: this);
    _shakeController.addListener(_resetAnimation);
    _init();
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notedUIModel.value != oldWidget.notedUIModel.value) {
      _init();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _shakeController.removeListener(_resetAnimation);
    super.dispose();
  }

  void _resetAnimation() {
    if(_shakeController.isCompleted) {
      _shakeController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    if(!widget.isShowMomentOptionWidget) return const SizedBox();
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: (){},
      child: Container(
        height: 41.px,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(
              Adapt.px(8),
            ),
          ),
          color: ThemeColor.color180,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 12.px,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: momentOptionTypeList.map((EMomentOptionType type) {
            return ValueListenableBuilder<NotedUIModel?>(
              valueListenable: notedUIModel,
              builder: (context, model, child) => _showItemWidget(type,model),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _showItemWidget(EMomentOptionType type,NotedUIModel? model){
    if(model == null) return const SizedBox();
    bool isZap = type == EMomentOptionType.zaps;
    Widget iconTextWidget = _iconTextWidget(
      type: type,
      isSelect: _isClickByMe(type,model),
      onTap: () => _onTapCallback(type)(),
      clickNum: _getClickNum(type,model),
    );
    if(isZap){
      return Expanded(
        child: ZapDoneAnimation(
          controller: _shakeController,
          child: iconTextWidget,
        ),
      );
    }
    return Expanded(child: iconTextWidget);
  }

  GestureTapCallback _onTapCallback(EMomentOptionType type) {
    NoteDBISAR? noteDB = notedUIModel.value?.noteDB;
    if(noteDB == null) return () => {};
    switch (type) {
      case EMomentOptionType.reply:
        return () async{
          await OXNavigator.presentPage(context, (context) => ReplyMomentsPage(notedUIModel: notedUIModel),fullscreenDialog:true);
          _updateNoteDB();
        };
      case EMomentOptionType.repost:
        return () => showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => _buildBottomDialog());

      case EMomentOptionType.like:
        return () async {
          if (noteDB.reactionCountByMe > 0 || _reactionTag) return;
          bool isSuccess = false;
          if (noteDB.groupId.isEmpty) {
            OKEvent event = await Moment.sharedInstance.sendReaction(noteDB.noteId);
            isSuccess = event.status;
          }else{
            OKEvent event = await RelayGroup.sharedInstance.sendGroupNoteReaction(noteDB.noteId);
            isSuccess = event.status;
          }

          if (isSuccess) {
            _reactionTag = true;
            _updateNoteDB();
            CommonToast.instance.show(context, Localized.text('ox_discovery.like_success_tips'));

          }
        };
      case EMomentOptionType.zaps:
        return _handleZap;
    }
  }

  Widget _iconTextWidget({
    required EMomentOptionType type,
    required bool isSelect,
    GestureTapCallback? onTap,
    int? clickNum,
  }) {
    final content = clickNum == null || clickNum == 0 ? '' : clickNum.toString();
    Color textColors = isSelect ? ThemeColor.gradientMainStart : ThemeColor.color80;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => onTap?.call(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.only(
              right: 4.px,
            ),
            child: CommonImage(
              iconName: type.getIconName,
              size: 16.px,
              package: 'ox_discovery',
              color: textColors,
            ),
          ),
          Text(
            content,
            style: TextStyle(
              color: textColors,
              fontSize: 12.px,
              fontWeight: FontWeight.w400,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomDialog() {
    NotedUIModel? draftNotedUIModel = notedUIModel.value;
    if(draftNotedUIModel == null) return const SizedBox();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Adapt.px(12)),
        color: ThemeColor.color180,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            EMomentQuoteType.repost,
            index: 0,
            onTap: () async {
              OXNavigator.pop(context);
              String groupId = draftNotedUIModel.noteDB.groupId;
              bool success = false;
              if(groupId.isEmpty){
                OKEvent event = await Moment.sharedInstance.sendRepost(draftNotedUIModel.noteDB.noteId, null);
                success = event.status;
              }else{
                OKEvent event = await RelayGroup.sharedInstance.sendRepost(draftNotedUIModel.noteDB.noteId, null);
                success = event.status;
              }
              if (success) {
                _updateNoteDB();
                CommonToast.instance.show(context, Localized.text('ox_discovery.repost_success_tips'));
              }
            },
          ),
          Divider(
            color: ThemeColor.color170,
            height: Adapt.px(0.5),
          ),
          _buildItem(
            EMomentQuoteType.quote,
            index: 1,
            onTap: () {
              OXNavigator.pop(context);
              OXNavigator.presentPage(context, (context) => CreateMomentsPage(type: EMomentType.quote,notedUIModel: notedUIModel));
            },
          ),
          Container(
            height: Adapt.px(8),
            color: ThemeColor.color190,
          ),
          GestureDetector(
            onTap: () {
              OXNavigator.pop(context);
            },
            child: Text(
              Localized.text('ox_common.cancel'),
              style: TextStyle(
                color: ThemeColor.color0,
                fontSize: Adapt.px(16),
                fontWeight: FontWeight.w400,
              ),
            ),
          ).setPadding(EdgeInsets.symmetric(
            vertical: 10.px,
          )),
          SizedBox(
            height: Adapt.px(21),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    EMomentQuoteType type, {
    required int index,
    GestureTapCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: Adapt.px(56),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CommonImage(
              iconName: type.getIconName,
              size: 24.px,
              package: 'ox_discovery',
              color: ThemeColor.color0,
            ),
            SizedBox(
              width: 10.px,
            ),
            Text(
              type.text,
              style: TextStyle(
                color: ThemeColor.color0,
                fontSize: Adapt.px(16),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      onTap: onTap,
    );
  }


  int _getClickNum(EMomentOptionType type,NotedUIModel model){
    NoteDBISAR noteDB = model.noteDB;
    switch(type){
      case EMomentOptionType.repost:
       return (noteDB.repostCount) + (noteDB.quoteRepostCount);
      case EMomentOptionType.like:
        return noteDB.reactionCount;
      case EMomentOptionType.zaps:
        return noteDB.zapAmount;
      case EMomentOptionType.reply:
        return noteDB.replyCount;
    }
  }

  bool _isClickByMe(EMomentOptionType type,NotedUIModel model){
    NoteDBISAR noteDB = model.noteDB;
    switch(type){
      case EMomentOptionType.repost:
        return noteDB.repostCountByMe > 0;
      case EMomentOptionType.like:
        return _reactionTag ? _reactionTag : noteDB.reactionCountByMe > 0;
      case EMomentOptionType.zaps:
        return noteDB.zapAmountByMe > 0;
      case EMomentOptionType.reply:
        return noteDB.replyCountByMe > 0;
    }
  }

  void _init(){
    notedUIModel = widget.notedUIModel;
    setState(() {});
  }


  void _updateNoteDB() async {
    if(notedUIModel.value == null)  return;
    ValueNotifier<NotedUIModel?> noteNotifier = await DiscoveryUtils.getValueNotifierNoted(
      notedUIModel.value!.noteDB.noteId,
      isUpdateCache: true,
      notedUIModel: notedUIModel.value!,
    );

    if(noteNotifier.value == null) return;
    if(mounted){
      notedUIModel.value = noteNotifier.value;
    }

  }

  _handleZap() async {
    NotedUIModel? draftNotedUIModel = notedUIModel.value;
    if(draftNotedUIModel == null) return;

    UserDBISAR? user = await Account.sharedInstance.getUserInfo(draftNotedUIModel.noteDB.author);
    String? pubkey = Account.sharedInstance.me?.pubKey;
    //Special product requirement
    final isAssistedProcess = await OXCacheManager.defaultOXCacheManager.getForeverData('$pubkey.isShowWalletSelector') ?? true;
    if(user == null) return;
    if(_isZapProcessing) return;
    _isZapProcessing = true;
    ZapsActionHandler handler = await ZapsActionHandler.create(
      userDB: user,
      isAssistedProcess: isAssistedProcess,
      zapsInfoCallback: (zapsInfo) async {
        if(_isDefaultEcashWallet || _isDefaultNWCWallet) {
          final amount = int.parse(zapsInfo['amount']);
          await _shakeController.forward();
          // _updateZapsUIWithUnreal(amount);
          _updateNoteDB();
          if (!_completer.isCompleted) {
            _completer.complete(false);
          }
        } else {
          _completer.complete(false);
        }
      });
    _isDefaultEcashWallet = handler.isDefaultEcashWallet;
    _isDefaultNWCWallet = handler.isDefaultNWCWallet;
    await handler.handleZap(context: context,eventId: draftNotedUIModel.noteDB.noteId,);
    if (isAssistedProcess) {
      _isZapProcessing = false;
    } else {
      _isZapProcessing = await _completer.future;
    }
  }

  _updateZapsUIWithUnreal(int amount) {
    if(notedUIModel.value == null) return;
    NoteDBISAR newNote = notedUIModel.value!.noteDB;
    newNote.zapAmount = newNote.zapAmount + amount;
    newNote.zapAmountByMe = amount;

    notedUIModel.value = NotedUIModel(noteDB: newNote);

  }
}
