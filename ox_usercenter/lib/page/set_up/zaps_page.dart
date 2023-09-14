import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ox_cache_manager/ox_cache_manager.dart';
import 'package:ox_common/business_interface/ox_usercenter/zaps_detail_model.dart';
import 'package:ox_common/model/wallet_model.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/utils/ox_userinfo_manager.dart';
import 'package:ox_common/widgets/common_appbar.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';
import 'package:ox_usercenter/model/zaps_record.dart';
import 'package:ox_usercenter/page/set_up/zaps_record_page.dart';

///Title: zaps_page
///Description: TODO(Fill in by oneself)
///Copyright: Copyright (c) 2021
///@author Michael
///CreateTime: 2023/5/10 17:26
class ZapsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ZapsPageState();
  }
}

class _ZapsPageState extends State<ZapsPage> {
  bool _walletSwitchSelected = true;
  // final TextEditingController _zapAmountTextEditingController = TextEditingController();
  final List<WalletModel> _walletList = WalletModel.wallets;
  String _selectedWalletName = '';
  ZapsRecord? _zapsRecord;
  String pubKey = '';
  // double _defaultZapAmount = 0;
  // final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    pubKey = OXUserInfoManager.sharedInstance.currentUserInfo?.pubKey ?? '';
    _selectedWalletName = await OXCacheManager.defaultOXCacheManager.getForeverData('$pubKey.defaultWallet') ?? Localized.text('ox_usercenter.not_set_wallet_status');
    _walletSwitchSelected = await OXCacheManager.defaultOXCacheManager.getForeverData('$pubKey.isShowWalletSelector') ?? true;
    // _defaultZapAmount = await YLCacheManager.defaultYLCacheManager.getForeverData('$pubKey.defaultZapAmount');
    _zapsRecord  = await getZapsRecord(context: context,userPubKey: pubKey);
    // _focusNode.addListener(() {
      // if(!_focusNode.hasFocus){
      //   double defaultZapAmount = double.parse(_zapAmountTextEditingController.text);
      //   YLCacheManager.defaultYLCacheManager.saveForeverData('$pubKey.defaultZapAmount',defaultZapAmount);
      // }
    // });
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        backgroundColor: ThemeColor.color190,
        appBar: CommonAppBar(
          title: Localized.text('ox_usercenter.zaps'),
          centerTitle: true,
          useLargeTitle: false,
          titleTextColor: ThemeColor.color0,
        ),
        body: _body(),
      ),
      onTap: (){
        FocusScope.of(context).requestFocus(FocusNode());
      },
    );
  }

  Widget _body() {
    List<ZapsRecordDetail>  zapsRecordDetails= _zapsRecord?.list ?? [];
    // String totalZaps = _totalZaps(_zapsRecord?.totalZaps ?? 0);
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildItem(label: Localized.text('ox_usercenter.zaps'),itemBody: Container(
            width: double.infinity,
            height: Adapt.px(104 + 0.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Adapt.px(16)),
              color: ThemeColor.color180,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildItemBody(title: Localized.text('ox_usercenter.show_wallet_selector'), isShowDivider: true,trailing: _buildWalletSelector(),isShowArrow: false),
                _buildItemBody(title: Localized.text('ox_usercenter.select_default_wallet'), flag: _selectedWalletName,onTap: ()=>_walletSelectorDialog()),
              ],
            ),
          ),),
          // _buildItem(label: 'Default zap amount in sats', itemBody: _zapAmountView(hitText: '$_defaultZapAmount',controller: _zapAmountTextEditingController,focusNode: _focusNode),),
          // _buildItem(label: 'Cumulative Zaps', itemBody: _zapAmountView(hitText: totalZaps,enable: false)),
          zapsRecordDetails.isNotEmpty ? _buildItem(label: Localized.text('ox_usercenter.zaps_record'), itemBody: _buildZapsRecord()) : Container(),
        ],
      ).setPadding(EdgeInsets.symmetric(
        horizontal: Adapt.px(24),
        vertical: Adapt.px(12),
      )),
    );
  }

  Widget _zapAmountView({String? hitText,TextEditingController? controller,bool? enable,FocusNode? focusNode}){
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Adapt.px(16)),
        color: ThemeColor.color180,
      ),
      padding: EdgeInsets.symmetric(horizontal: Adapt.px(16), vertical: Adapt.px(12)),
      child: TextField(
        readOnly: false,
        enabled: enable,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: hitText,
          isCollapsed: true,
          hintStyle: TextStyle(
            fontSize: Adapt.px(16),
            fontWeight: FontWeight.w400,
            color: ThemeColor.color40,
          ),
          border: InputBorder.none,
        ),
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: ThemeColor.color40),
      ),
    );
  }

  Widget _buildItemBody({String? title, bool isShowDivider = false,Widget? trailing, String? flag, GestureTapCallback? onTap,bool isShowArrow = true}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: Adapt.px(52),
          padding: EdgeInsets.symmetric(horizontal: Adapt.px(16)),
          child: Row(
          children: [
            Text(
              title ?? '',
              style: TextStyle(
                color: ThemeColor.color0,
                fontSize: Adapt.px(16),
              ),
            ),
            Expanded(
              child: SizedBox(
                width: Adapt.px(122),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: onTap,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      trailing ?? SizedBox(
                        child: Text(
                          flag ?? '',
                          style: TextStyle(
                            fontSize: Adapt.px(16),
                            color: ThemeColor.color100,
                          ),
                        textAlign: TextAlign.end,
                      ),
                    ), isShowArrow ? CommonImage(
                      iconName: 'icon_arrow_more.png',
                      width: Adapt.px(24),
                      height: Adapt.px(24),
                    ):Container(),
                  ],
                  ),
                ),
              ),
            ),
           ],
          ),
        ),
        Visibility(
          visible: isShowDivider,
          child: Divider(
            height: Adapt.px(0.5),
            color: ThemeColor.color160,
          ),
        ),
      ],
    );
  }

  void _walletSelectorDialog(){
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Material(
            type: MaterialType.transparency,
            child: Opacity(
              opacity: 1,
              child: Container(
                alignment: Alignment.bottomCenter,
                height: Adapt.px(401),
                decoration: BoxDecoration(
                  color: ThemeColor.color180,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:  SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // GestureDetector(
                      //   behavior: HitTestBehavior.translucent,
                      //   onTap: (){
                      //     YLNavigator.pop(context);
                      //     setState(() {
                      //       _selectedWalletName = 'Local default';
                      //     });
                      //   },
                      //   child: Container(
                      //     width: double.infinity,
                      //     height: Adapt.px(56),
                      //     alignment: Alignment.center,
                      //     child: Text(
                      //       'Default',
                      //       style: TextStyle(fontSize: Adapt.px(16), color: Colors.white),
                      //     ),
                      //   ),
                      // ),
                      // Container(
                      //   height: Adapt.px(0.5),
                      //   color: ThemeColor.color190,
                      // ),
                      SizedBox(
                        width: double.infinity,
                        // height: Adapt.px(280),
                        child: ListView.builder(
                          scrollDirection: Axis.vertical,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemBuilder: _itemWidget,
                          itemCount: _walletList.length,
                          shrinkWrap: true,
                        ),
                      ),
                      Container(
                        height: Adapt.px(8),
                        color: ThemeColor.color190,
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          OXNavigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          height: Adapt.px(56),
                          color: ThemeColor.color180,
                          child: Center(
                            child: Text(
                              Localized.text('ox_common.cancel'),
                              style: TextStyle(fontSize: 16, color: ThemeColor.gray02),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ));
      },
    );
  }

  Widget _itemWidget(BuildContext context, int index) {
    String walletName = _walletList[index].title;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        OXNavigator.pop(context);
        if(walletName != _selectedWalletName){
          await OXCacheManager.defaultOXCacheManager.saveForeverData('$pubKey.defaultWallet', walletName);
        }
        setState(() {
          _selectedWalletName = walletName;
        });
      },
      child: Container(
        height: Adapt.px(56),
        alignment: Alignment.center,
        child: Text(
          walletName,
          style: TextStyle(fontSize: Adapt.px(16), color: ThemeColor.color0),
        ),
      ),
    );
  }

  Widget _buildItemLabel({required String label}){
    return Container(
      alignment: Alignment.topLeft,
      child: Text(
        label,
        style: TextStyle(
          fontSize: Adapt.px(16),
          color: ThemeColor.color0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildItem({required String label,required Widget itemBody}){
    return Column(
      children: [
        _buildItemLabel(label: label),
        SizedBox(height: Adapt.px(12),),
        itemBody,
        SizedBox(height: Adapt.px(12),),
      ],
    );
  }

  Widget _buildWalletSelector(){
    return SizedBox(
      width: Adapt.px(36),
      height: Adapt.px(20),
      child: Switch(
        value: _walletSwitchSelected,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFFC084FC),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: ThemeColor.color160,
        onChanged: (value) async {
          if(!value){
            if(_selectedWalletName ==  Localized.text('ox_usercenter.not_set_wallet_status')){
              CommonToast.instance.show(context, Localized.text('ox_usercenter.not_set_wallet_tips'));
              return;
            }
          }

          setState(() {
            _walletSwitchSelected = value;
          });
          await OXCacheManager.defaultOXCacheManager.saveForeverData('$pubKey.isShowWalletSelector', value);
        },
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }

  Widget _buildZapsRecord() {

    List<ZapsRecordDetail>  zapsRecordDetails= _zapsRecord?.list ?? [];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Adapt.px(16)),
        color: ThemeColor.color180,
      ),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 0),
        itemBuilder: (context, index) => _buildItemBody(
            title: '+${zapsRecordDetails[index].amount}',
            flag: zapsRecordDetails[index].zapsTimeFormat,
            onTap: () => OXNavigator.pushPage(context, (context) => ZapsRecordPage(zapsRecordDetail: zapsRecordDetails[index],))),
        separatorBuilder: (context, index) => Divider(
          height: Adapt.px(0.5),
          color: ThemeColor.color160,
        ),
        itemCount: zapsRecordDetails.length,
        shrinkWrap: true,
      ),
    );
  }

  String _totalZaps(double totalZaps) {
    String result = '';

    if (totalZaps >= 210 && totalZaps < 2100) {
      result = '😊 ';
    } else if (totalZaps >= 2100 && totalZaps < 21000) {
      result = '🥰 ';
    } else if (totalZaps >= 21000 && totalZaps < 210000) {
      result = '😘 ';
    } else if (totalZaps >= 210000 && totalZaps < 2100000) {
      result = '❤️ ';
    } else if (totalZaps >= 2100000 && totalZaps < 21000000) {
      result = '🔥️';
    } else if (totalZaps >= 21000000) {
      result = '🚀️';
    }

    result = result + '$totalZaps';
    return result;
  }
}

class ZapsRecordRe{
  String id;
  int stats;
  String from;
  String to;
  DateTime time;
  String description;

  ZapsRecordRe(
      this.id, this.stats, this.from, this.to, this.time, this.description);
}