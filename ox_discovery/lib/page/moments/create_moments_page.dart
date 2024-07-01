import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:chatcore/chat-core.dart';
import 'package:flutter/material.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/ox_userinfo_manager.dart';
import 'package:ox_common/utils/uplod_aliyun_utils.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/widgets/common_hint_dialog.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:flutter/services.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_discovery/enum/visible_type.dart';
import 'package:ox_discovery/page/moments/visibility_selection_page.dart';
import 'package:ox_discovery/page/widgets/send_progress_widget.dart';
import 'package:ox_discovery/utils/discovery_utils.dart';
import 'package:ox_localizable/ox_localizable.dart';

import '../../enum/moment_enum.dart';
import '../../model/moment_extension_model.dart';
import '../../model/moment_ui_model.dart';
import '../../utils/album_utils.dart';
import '../../utils/moment_content_analyze_utils.dart';
import '../../utils/moment_widgets_utils.dart';
import '../widgets/Intelligent_input_box_widget.dart';
import '../widgets/moment_quote_widget.dart';
import '../widgets/nine_palace_grid_picture_widget.dart';

import 'package:chatcore/chat-core.dart';
import 'package:nostr_core_dart/nostr.dart';


enum ESendMomentsType {
  personal,
  group
}

class CreateMomentsPage extends StatefulWidget {
  final String? groupId;
  final ESendMomentsType sendMomentsType;
  final EMomentType type;
  final List<String>? imageList;
  final String? videoPath;
  final String? videoImagePath;
  final ValueNotifier<NotedUIModel>? notedUIModel;
  const CreateMomentsPage(
      {Key? key,
      required this.type,
      this.sendMomentsType = ESendMomentsType.personal,
      this.groupId,
      this.imageList,
      this.videoPath,
      this.videoImagePath,
      this.notedUIModel})
      : super(key: key);

  @override
  State<CreateMomentsPage> createState() => _CreateMomentsPageState();
}

class _CreateMomentsPageState extends State<CreateMomentsPage> {

  Map<String,UserDB> draftCueUserMap = {};

  List<String> addImageList = [];

  String? videoPath;
  String? videoImagePath;

  bool _isInputFocused = false;

  final TextEditingController _textController = TextEditingController();

  final ProcessController _processController = ProcessController();
  final Completer<void> _completer = Completer<void>();
  Completer<String>? _uploadCompleter;

  int get totalCount => _visibleType == VisibleType.allContact
      ? Contacts.sharedInstance.allContacts.length
      : _selectedContacts?.length ?? 0;

  VisibleType _visibleType = VisibleType.everyone;
  List<UserDB>? _selectedContacts;

  @override
  void initState() {
    if(widget.imageList != null || widget.videoPath != null) {
      _uploadCompleter = Completer<String>();
      _getUploadMediaContent();
    }
    super.initState();
    _initDraft();
  }

  @override
  void dispose() {
    _processController.process.dispose();
    super.dispose();
  }

  void _initDraft(){
    CreateMomentDraft? createMomentMediaDraft = OXMomentCacheManager.sharedInstance.createMomentMediaDraft;
    CreateMomentDraft? createMomentContentDraft = OXMomentCacheManager.sharedInstance.createMomentContentDraft;

    videoPath = widget.videoPath;
    videoImagePath = widget.videoImagePath;
    if(createMomentMediaDraft != null && widget.type != EMomentType.content){

      _textController.text = createMomentMediaDraft.content;
      _visibleType = createMomentMediaDraft.visibleType;
      _selectedContacts = createMomentMediaDraft.selectedContacts;
      draftCueUserMap = createMomentMediaDraft.draftCueUserMap ?? {};

      if(widget.type == EMomentType.video){
        videoPath = createMomentMediaDraft.videoPath ?? '';
        videoImagePath = createMomentMediaDraft.videoImagePath ?? '';
      }

      if(widget.type == EMomentType.picture){
        addImageList = createMomentMediaDraft.imageList ?? [];
      }
    }

    if(createMomentContentDraft != null && widget.type == EMomentType.content){

      _textController.text = createMomentContentDraft.content;
      _visibleType = createMomentContentDraft.visibleType;
      _selectedContacts = createMomentContentDraft.selectedContacts;
      draftCueUserMap = createMomentContentDraft.draftCueUserMap ?? {};
    }

    setState(() {});

  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        decoration: BoxDecoration(
          color: ThemeColor.color190,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(Adapt.px(20)),
            topLeft: Radius.circular(Adapt.px(20)),
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildAppBar(),
                  Container(
                    padding: EdgeInsets.only(
                      left: 24.px,
                      right: 24.px,
                      bottom: widget.type == EMomentType.content ? 100.px : 500.px,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _videoWidget(),
                        _pictureWidget(),
                        _quoteWidget(),
                        _captionWidget(),
                        _visibleContactsWidget(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Align(
              child: SendProgressWidget(
                controller: _processController,
                totalCount: totalCount,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: Adapt.px(57),
      margin: EdgeInsets.only(bottom: Adapt.px(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            child: CommonImage(
              iconName: "icon_back_left_arrow.png",
              width: Adapt.px(24),
              height: Adapt.px(24),
              useTheme: true,
            ),
            onTap: _checkSaveDraft,
          ),
          Text(
            Localized.text('ox_discovery.new_moments_title'),
            style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: Adapt.px(16),
                color: ThemeColor.color0),
          ),
          GestureDetector(
            onTap: _postMoment,
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
                Localized.text('ox_discovery.post'),
                style: TextStyle(
                  fontSize: Adapt.px(16),
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).setPadding(EdgeInsets.symmetric(
      horizontal: 24.px,
    ));
  }

  Widget _pictureWidget() {
    if (widget.type != EMomentType.picture) return const SizedBox();
    return NinePalaceGridPictureWidget(
      isEdit: true,
      imageList: _getImageList(),
      addImageCallback: (List<String> newImageList) {
        addImageList = [...addImageList, ...newImageList];
        setState(() {});
      },
    );
  }

  Widget _videoWidget() {
    if (widget.type != EMomentType.video) return const SizedBox();
    return MomentWidgetsUtils.videoMoment(
        context, videoPath ?? '', videoImagePath ?? '');
  }

  Widget _quoteWidget() {
    ValueNotifier<NotedUIModel>? notedUIModel = widget.notedUIModel;
    if (widget.type != EMomentType.quote || notedUIModel == null) return const SizedBox();
    return MomentQuoteWidget(notedId: widget.notedUIModel!.value.noteDB.noteId);
  }

  Widget _captionWidget() {
    return Container(
      padding: EdgeInsets.only(
        top: 12.px,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(
              bottom: 12.px,
            ),
            child: Text(
              Localized.text('ox_discovery.caption'),
              style: TextStyle(
                  fontSize: 14.px,
                  fontWeight: FontWeight.w600,
                  color: ThemeColor.color0),
            ),
          ),
          IntelligentInputBoxWidget(
              textController: _textController,
              hintText: Localized.text('ox_discovery.caption_hint_text'),
              cueUserCallback: (List<UserDB> userList){
                if(userList.isEmpty) return;
                for(UserDB db in userList){
                  String? getName = db.name;
                  if(getName != null){
                    draftCueUserMap['@${getName}'] = db;
                    setState(() {});
                  }
                }
              },
              isFocusedCallback: (bool isFocus) {
                setState(() {
                  _isInputFocused = isFocus;
                });
              }),
        ],
      ),
    );
  }

  Widget _visibleContactsWidget() {
    if(widget.type == EMomentType.quote) return const SizedBox();
    return Container(
      margin: EdgeInsets.only(
        top: 12.px,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(
              bottom: 12.px,
            ),
            child: Text(
              Localized.text('ox_discovery.visible_destination_title'),
              style: TextStyle(
                  fontSize: 14.px,
                  fontWeight: FontWeight.w600,
                  color: ThemeColor.color0),
            ),
          ),
          GestureDetector(
            onTap: _visibleToUser,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16.px,
              ),
              height: 48.px,
              decoration: BoxDecoration(
                color: ThemeColor.color180,
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    Adapt.px(12),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _visibleType.name,
                    style: TextStyle(
                      fontSize: 16.px,
                      color: ThemeColor.color0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  CommonImage(
                    iconName: 'moment_more_icon.png',
                    size: 24.px,
                    package: 'ox_discovery',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _visibleToUser() {
    OXNavigator.presentPage(
      context,
      (context) => VisibilitySelectionPage(
        visibleType: _visibleType,
        selectedContacts: _selectedContacts,
        onSubmitted: (type,items){
          setState(() {
            _visibleType = type;
            _selectedContacts = items;
          });
        },
      ),
    );
  }

  void _checkSaveDraft() async {
    if(_textController.text.isEmpty && _getImageList().isEmpty && videoPath == null){
      OXNavigator.pop(context);
      return;
    }
   await OXCommonHintDialog.show(context,
        title: '',
        content: 'Whether to reserve this edit ?',
        actionList: [
          OXCommonHintAction(
            text: () => 'UnSave',
            style: OXHintActionStyle.gray,
            onTap: () {
              _clearDraft();
              OXNavigator.pop(context);
            },
          ),
          OXCommonHintAction.sure(
              text: 'Save',
              onTap: () async {
                _saveCreateMomentDraft();
                OXNavigator.pop(context);
              }),
        ],
        isRowAction: true,
    );
    OXNavigator.pop(context);

  }

  void _postMoment() async {
    String getMediaStr = '';
    if (_uploadCompleter != null) {
      OXLoading.show();
      getMediaStr = await _uploadCompleter!.future;
      OXLoading.dismiss();
    }
    // String getMediaStr = await _getUploadMediaContent();
    final inputText = _textController.text;
    String content = '${DiscoveryUtils.changeAtUserToNpub(draftCueUserMap, inputText)} $getMediaStr';
    OKEvent? event;

    NoteDB? noteDB = widget.notedUIModel?.value.noteDB;

    List<String> hashTags = MomentContentAnalyzeUtils(content).getMomentHashTagList;
    List<String>? getHashTags = hashTags.isEmpty ? null : hashTags;
    List<String>? getReplyUser = DiscoveryUtils.getMentionReplyUserList(draftCueUserMap, inputText);

    if(content.trim().isEmpty){
      CommonToast.instance.show(context, Localized.text('ox_discovery.content_empty_tips'));
      return;
    }

    if(widget.sendMomentsType == ESendMomentsType.group) return _postMomentToGroup(content:content,mentions:getReplyUser,hashTags:hashTags);

    if(widget.type == EMomentType.quote && noteDB != null){
      event = await Moment.sharedInstance.sendQuoteRepost(noteDB.noteId,content,hashTags:hashTags,mentions:getReplyUser);
    }else{
      switch (_visibleType) {
        case VisibleType.everyone:
          OXLoading.show();
          event = await Moment.sharedInstance.sendPublicNote(content,hashTags: getHashTags,mentions: getReplyUser);
          break;
        case VisibleType.allContact:
          _updateProgressStatus(0);
          Moment.sharedInstance
              .sendNoteContacts(content,
                  mentions: getReplyUser,
                  hashTags: getHashTags,
                  sendMessageProgressCallBack: (value) {
                    _updateProgressStatus(value);
                  })
              .then((value) => event = value);
          await _completer.future;
          break;
        case VisibleType.private:
          OXLoading.show();
          event = await Moment.sharedInstance.sendNoteJustMe(content,hashTags: getHashTags);
          break;
        case VisibleType.excludeContact:
          final pubkeys = _selectedContacts?.map((e) => e.pubKey).toList();
          _updateProgressStatus(0);
          Moment.sharedInstance
              .sendNoteCloseFriends(pubkeys ?? [], content,
                  mentions: getReplyUser,
                  hashTags: getHashTags,
                  sendMessageProgressCallBack: (value) => _updateProgressStatus(value))
              .then((value) => event = value);
          await _completer.future;
          break;
        default:
          break;
      }
    }

    await OXLoading.dismiss();
    if(event?.status ?? false){
      _clearDraft();
      CommonToast.instance.show(context, Localized.text('ox_chat.sent_successfully'));
    }

    OXNavigator.pop(context);
  }

  void _postMomentToGroup({required String content,required List<String>? mentions,required List<String>? hashTags}) async{
    String? groupId = widget.groupId;
    if(groupId == null) return CommonToast.instance.show(context, 'groupId is empty !');
    List<String> previous = Nip29.getPrevious([[groupId]]);
    OXLoading.show();
    OKEvent result = await RelayGroup.sharedInstance.sendGroupNotes(groupId,content,previous,mentions:mentions,hashTags:hashTags);
    await OXLoading.dismiss();

    if(result.status){
      _clearDraft();
      CommonToast.instance.show(context, Localized.text('ox_chat.sent_successfully'));
    }

    OXNavigator.pop(context);
  }

  Future<String> _getUploadMediaContent() async {
    List<String> imageList = _getImageList();
    if(imageList.isEmpty && videoPath == null) return '';

    if (imageList.isNotEmpty){
      List<String> imgUrlList = await AlbumUtils.uploadMultipleFiles(
        context,
        fileType: UplodAliyunType.imageType,
        filePathList: _getImageList(),
        showLoading: false,
      );
      String getImageUrlToStr = imgUrlList.join(' ');
      _uploadCompleter?.complete(getImageUrlToStr);
      return getImageUrlToStr;
    }

    if (videoPath != null){
      List<String> imgUrlList = await AlbumUtils.uploadMultipleFiles(
        context,
        fileType: UplodAliyunType.videoType,
        filePathList: [videoPath!],
        showLoading: false
      );
      String getVideoUrlToStr = imgUrlList.join(' ');
      _uploadCompleter?.complete(getVideoUrlToStr);
      return getVideoUrlToStr;
    }

    return '';
  }

  List<String> _getImageList() {
    List<String> containsImageList = [
      ...widget.imageList ?? [],
      ...addImageList
    ];
    return containsImageList;
  }

  void _updateProgressStatus(int value) {
    _processController.process.value = value;
    if (value > totalCount) {
      _completer.complete();
    }
  }

  void _saveCreateMomentDraft() {
    CreateMomentDraft draft = CreateMomentDraft(
      type: widget.type,
      content: _textController.text,
      selectedContacts: _selectedContacts,
      draftCueUserMap: draftCueUserMap,
      visibleType : _visibleType,
      imageList: _getImageList(),
      videoPath: videoPath,
      videoImagePath: videoImagePath,
    );
    if(widget.type != EMomentType.content){
      OXMomentCacheManager.sharedInstance.createMomentMediaDraft = draft;
      return;
    }
    OXMomentCacheManager.sharedInstance.createMomentContentDraft = draft;
  }

  void _clearDraft() {
    final sharedInstance = OXMomentCacheManager.sharedInstance;
    if(widget.type == EMomentType.content){
      sharedInstance.createMomentContentDraft = null;
    }else{
      sharedInstance.createMomentMediaDraft = null;
    }
  }
}
