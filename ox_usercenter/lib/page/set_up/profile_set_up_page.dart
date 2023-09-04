import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatcore/chat-core.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:flutter/material.dart';
import 'package:ox_common/log_util.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/utils/uplod_aliyun_utils.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/utils/ox_relay_manager.dart';
import 'package:ox_common/utils/ox_userinfo_manager.dart';
import 'package:ox_common/widgets/common_appbar.dart';
import 'package:ox_common/widgets/common_button.dart';
import 'package:ox_common/widgets/common_hint_dialog.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_usercenter/model/request_verify_dns.dart';
import 'package:ox_usercenter/page/set_up/avatar_preview_page.dart';

class ProfileSetUpPage extends StatefulWidget {
  const ProfileSetUpPage({Key? key}) : super(key: key);

  @override
  State<ProfileSetUpPage> createState() => _ProfileSetUpPageState();
}

class _ProfileSetUpPageState extends State<ProfileSetUpPage> {
  UserDB? mCurrentUserInfo;
  final TextEditingController _userNameTextEditingController = TextEditingController();
  final TextEditingController _dnsTextEditingController = TextEditingController();
  final TextEditingController _aboutTextEditingController = TextEditingController();
  final TextEditingController _bltTextEditingController = TextEditingController();
  final ValueNotifier<bool> _is0xchatAddress = ValueNotifier<bool>(true);
  List<String> _relayNameList = [];
  File? imageFile;

  @override
  void initState() {
    super.initState();
    mCurrentUserInfo = OXUserInfoManager.sharedInstance.currentUserInfo;
    _userNameTextEditingController.text = mCurrentUserInfo?.name ?? '';
    _aboutTextEditingController.text = mCurrentUserInfo?.about ?? '';
    _bltTextEditingController.text = mCurrentUserInfo?.lnurl ?? '';
    _initData();
    _initDNSItem();
  }

  void _initData() async {
    _relayNameList = OXRelayManager.sharedInstance.relayAddressList;
    mCurrentUserInfo = await Account.sharedInstance.reloadProfileFromRelay(mCurrentUserInfo!.pubKey);
    setState(() {});
  }

  void _initDNSItem() {
    String dns = mCurrentUserInfo?.dns ?? '';
    if (dns.isEmpty || dns.contains('@0xchat.com')) {
      _is0xchatAddress.value = true;
      _dnsTextEditingController.text = dns.split('@').first;
    } else {
      _is0xchatAddress.value = false;
      _dnsTextEditingController.text = dns;
    }
    _dnsTextEditingController.addListener(() {
      String dnsStr = _dnsTextEditingController.text;
      if (dnsStr.contains('@')) {
        _is0xchatAddress.value = false;
      } else {
        _is0xchatAddress.value = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        backgroundColor: ThemeColor.color190,
        appBar: CommonAppBar(
          title: '',
          useLargeTitle: false,
          centerTitle: true,
          canBack: false,
          leading: IconButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: CommonImage(
              iconName: "close_icon_white.png",
              width: Adapt.px(24),
              height: Adapt.px(24),
            ),
            onPressed: () {
              OXNavigator.pop(context);
            },
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: Adapt.px(5), top: Adapt.px(12)),
              color: Colors.transparent,
              child: OXButton(
                highlightColor: Colors.transparent,
                color: Colors.transparent,
                minWidth: Adapt.px(44),
                height: Adapt.px(44),
                child: CommonImage(
                  iconName: "icon_done.png",
                  width: Adapt.px(24),
                  height: Adapt.px(24),
                ),
                onPressed: () {
                  _editProfile();
                },
              ),
            ),
          ],
        ),
        body: createBody(),
      ),
      onTap: (){
        FocusScope.of(context).requestFocus(FocusNode());
      },
    );
  }

  void _editProfile() async {
    if (mCurrentUserInfo == null) {
      CommonToast.instance.show(context, Localized.text('ox_common.network_connect_fail'));
    }
    if (_userNameTextEditingController.text.length > 0) {
      mCurrentUserInfo!.name = _userNameTextEditingController.text;
      mCurrentUserInfo!.about = _aboutTextEditingController.text;

      String dns = _dnsTextEditingController.text;
      String lnurl = _bltTextEditingController.text;
      bool result;
      if(dns.isEmpty || dns == mCurrentUserInfo!.dns){
        result = true;
      }else if(dns != mCurrentUserInfo!.dns) {
        if(dns.contains('@') && !dns.contains('@0xchat')) {
          result = await _checkDNS(dns);
        }else if(!dns.contains('@0xchat')){
          dns = '$dns@0xchat.com';
          result = await _set0xchatDNS(dns);
        }else{
          result = await _set0xchatDNS(dns);
        }
      }else{
        result = true;
      }
      if (result) {
        mCurrentUserInfo!.dns = dns;
      } else {
        return;
      }

      if (lnurl != mCurrentUserInfo!.lnurl) {
        result = await _checkLnurl(lnurl);
        if (result) {
          mCurrentUserInfo!.lnurl = lnurl;
        } else {
          return;
        }
      }

      if (imageFile != null) {
        final String url = await UplodAliyun.uploadFileToAliyun(
          fileType: UplodAliyunType.imageType,
          file: imageFile!,
          filename: 'avatar_' + _userNameTextEditingController.text + DateTime.now().microsecondsSinceEpoch.toString() + '.png',
        );
        if (url.isNotEmpty) {
          mCurrentUserInfo!.picture = url;
        }
      }

      UserDB? tempUserDB = await Account.sharedInstance.updateProfile(mCurrentUserInfo!.privkey!, mCurrentUserInfo!);
      if (tempUserDB != null) {
        OXNavigator.pop(context);
      } else {
        CommonToast.instance.show(context, Localized.text('ox_common.network_connect_fail'));
      }
    }else{
      if(_userNameTextEditingController.text.isEmpty){
        CommonToast.instance.show(context, 'Please Enter Username');
      }
    }
  }

  Widget createBody() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Adapt.px(24), vertical: Adapt.px(12)),
      child: CustomScrollView(
        shrinkWrap: false,
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.all(0.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                <Widget>[
                  _buildHeadImgView(),
                  _itemView(Localized.text('ox_login.username'), 'Satoshi Nakamoto', editingController: _userNameTextEditingController),
                  _itemView(Localized.text('ox_login.dns'), 'satoshi(Optional)', editingController: _dnsTextEditingController,
                      suffix: ValueListenableBuilder(
                        valueListenable: _is0xchatAddress,
                        builder: (BuildContext context, dynamic value, Widget? child) {
                          return value ? Text(
                            '@0xchat.com',
                            style: TextStyle(
                                fontSize: Adapt.px(16),
                                color: ThemeColor.color0,
                                fontWeight: FontWeight.w400),
                          ) : Container();
                        },
                      )
                  ),
                  _itemView(Localized.text('ox_login.about'), 'Bitcoin Core Dev (Optional)', editingController: _aboutTextEditingController,maxLines: null),
                  _itemView(Localized.text('ox_login.bitcoin_lightning_tips'), 'Lighting Address or LNURL (Optional)', editingController: _bltTextEditingController,maxLines: null),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadImgView() {
    String headerUrl = OXUserInfoManager.sharedInstance.currentUserInfo?.picture ?? '';
    String localAvatarPath = 'assets/images/user_image.png';
    Image placeholderImage = Image.asset(
      localAvatarPath,
      fit: BoxFit.cover,
      width: Adapt.px(120),
      height: Adapt.px(120),
      package: 'ox_common',
    );

    return Center(
      child: GestureDetector(
        child: SizedBox(
          height: Adapt.px(120),
          width: Adapt.px(120),
          child: Stack(
            children: [
              Container(
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Adapt.px(120)),
                  child: imageFile != null
                      ? Image.file(
                    imageFile!,
                    alignment: Alignment.topCenter,
                    fit: BoxFit.cover,
                    height: Adapt.px(120),
                    width: Adapt.px(120),
                  )
                      : headerUrl.isNotEmpty ? CachedNetworkImage(
                    height: Adapt.px(120),
                    width: Adapt.px(120),
                    imageUrl: headerUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => placeholderImage,
                    errorWidget: (context, url, error) => placeholderImage,
                    // httpHeaders: map,
                  ):placeholderImage,
                ),
              ),
              Center(
                child: Container(
                  width: Adapt.px(111),
                  height: Adapt.px(111),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(Adapt.px(111)),
                    border: Border.all(
                      width: Adapt.px(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          onChangeHeadImg();
        },
      ),
    );
  }

  Widget _itemView(String title, String hintStr, {TextEditingController? editingController,Widget? suffix,int? maxLines = 1}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: Adapt.px(34),
          alignment: Alignment.topLeft,
          child: Text(
            title,
            style: TextStyle(
              fontSize: Adapt.px(16),
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Adapt.px(16)),
            color: ThemeColor.color180,
          ),
          padding: EdgeInsets.symmetric(horizontal: Adapt.px(16), vertical: Adapt.px(13)),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: hintStr,
                    isCollapsed: true,
                    hintStyle: TextStyle(
                      color: ThemeColor.color100,
                    ),
                    border: InputBorder.none,
                  ),
                  controller: editingController,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(color: ThemeColor.color40),
                  maxLines: maxLines,
                ),
              ),
              suffix ?? Container(),
            ],
          ),
        )
      ],
    ).setPadding(EdgeInsets.only(bottom: Adapt.px(12)));
  }
  
  onChangeHeadImg() async {
    OXNavigator.pushPage(context, (context) => AvatarPreviewPage(imageFile: imageFile, userDB: OXUserInfoManager.sharedInstance.currentUserInfo)).then((value) {
      if (value is File) {
        setState(() {
          imageFile = value;
        });
      }
    });
  }

  Widget createRow({
    required bool isRightTitle,
    required bool isRightImage,
    required String leftTitle,
    required String rightTitle,
    required String rightIconName,
    String? leftIconName,
  }) {
    return Container(
      height: Adapt.px(50),
      width: double.infinity,
      child: Row(
        children: [
          SizedBox(
            width: Adapt.px(16),
          ),
          if (leftIconName != null)
            CommonImage(
              iconName: leftIconName,
              width: Adapt.px(32),
              height: Adapt.px(32),
              package: 'ox_usercenter',
            ),
          if (leftIconName != null)
            SizedBox(
              width: Adapt.px(12),
            ),
          Text(
            leftTitle,
            style: TextStyle(color: ThemeColor.titleColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          isRightTitle
              ? Container(
            child: Text(rightTitle,
                style: TextStyle(
                  color: ThemeColor.gray4,
                  fontSize: 16,
                  fontWeight: FontWeight.w200,
                ),
                maxLines: 1,
                textAlign: TextAlign.end),
            width: Adapt.px(150),
          )
              : (isRightImage
              ? CommonImage(
            iconName: rightIconName,
            width: Adapt.px(20),
            height: Adapt.px(20),
          )
              : Container()),
          SizedBox(width: Adapt.px(0)),
          CommonImage(
            iconName: "icon_arrow_right.png",
            width: Adapt.px(20),
            height: Adapt.px(20),
          ),
          SizedBox(
            width: Adapt.px(16),
          )
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _registerNip05(String dns) async {
    String privateKey = mCurrentUserInfo?.privkey ?? '';
    String publicKey = mCurrentUserInfo?.pubKey ?? '';
    String sig = signData([publicKey,dns,_relayNameList], privateKey);
    Map<String, dynamic> params = {};
    params['name'] = _userNameTextEditingController.text;
    params['publicKey'] = publicKey;
    params['nip05Url'] = dns;
    params['relays'] = _relayNameList;
    params['sig'] = sig;

    return await registerNip05(context: context,params: params,showLoading: false);
  }

  Future<bool> _set0xchatDNS(String dns) async {
    Map<String, dynamic>? result = await _registerNip05(dns);
    if(result!=null){
      if(result['code'] == NIP05_SUCCESSFUL){
        return true;
      }else{
        CommonToast.instance.show(context,result['message']);
        return false;
      }
    }else{
      CommonToast.instance.show(context, 'Unrecognized 0xchat DNS address');
      return false;
    }
  }

  Future<bool> _checkDNS(String dnsStr) async {
    String pubKey = mCurrentUserInfo?.pubKey ?? '';
    List<String> temp = dnsStr.split('@');
    String name = temp[0];
    String domain = temp[1];
    DNS dns = DNS(name, domain, pubKey,_relayNameList);
    try{
      OXLoading.show(status: 'Checking...');
      bool result = await Account.checkDNS(dns);
      OXLoading.dismiss();
      if (!result) CommonToast.instance.show(context,'Not a legal DNS address');
      return result;
    }catch(error,stack){
      OXLoading.dismiss();
      CommonToast.instance.show(context,'check DNS address failed');
      LogUtil.e("check dns error:$error\r\n$stack");
      return false;
    }
  }

  Future<bool> _checkLnurl(String lnurl) async {
    if(lnurl.isEmpty){
      return true;
    }
    //when input is ln address
    if (lnurl.contains('@')) {
      try {
        lnurl = await Zaps.getLnurlFromLnaddr(lnurl);
      } catch (error, stack) {
        CommonToast.instance.show(context, 'Please enter the correct Lighting Address');
        LogUtil.d('LN Address parse fail::$error\r\n$stack');
        return false;
      }
    }
    try {
      ZapsDB? zapsDB = await Zaps.getZapsInfoFromLnurl(lnurl);
      if (zapsDB != null) {
        bool allowsNostr = zapsDB.allowsNostr ?? false;
        if (allowsNostr) {
          return true;
        }
      }
      return await _showNoAllowNostrTips();
    } catch (error, stack) {
      CommonToast.instance.show(context, 'Please enter the correct LNURL');
      LogUtil.d('LNURL parse fail:$error\r\n$stack');
      return false;
    }
  }

  Future<bool> _showNoAllowNostrTips() async {
    return await OXCommonHintDialog.show(context,
        title: 'Tips',
        content: 'The LNURL does not support the Nostr protocol, unable to view transaction history',
        actionList: [
          OXCommonHintAction.cancel(onTap: () {
            OXNavigator.pop(context, false);
          }),
          OXCommonHintAction.sure(
              text: 'Confirm',
              onTap: () async {
                OXNavigator.pop(context, true);
              }),
        ],
        isRowAction: true);
  }

  @override
  void dispose() {
    super.dispose();
    _is0xchatAddress.dispose();
  }
}
