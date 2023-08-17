import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/widgets/common_appbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ox_common/widgets/common_pull_refresher.dart';
import 'package:ox_common/widgets/common_status_view.dart';
import 'package:ox_common/widgets/common_loading.dart';

class RelayDetailPage extends StatefulWidget {

  final String relayURL;

  const RelayDetailPage({super.key,required this.relayURL});

  @override
  State<RelayDetailPage> createState() => _RelayDetailPageState();
}

class _RelayDetailPageState extends State<RelayDetailPage> {

  final RefreshController _refreshController = RefreshController();

  Future<Map<String, dynamic>?>? _future;

  Future<Map<String, dynamic>?> _getRelayDetails(String relayUrl,{bool? refresh}) async {
    OXLoading.show();
    RelayDB? relayDB  = await Relays.getRelayDetails(relayUrl,refresh: refresh);
    OXLoading.dismiss();
    Map<String, dynamic>? relayAttributes = await relayDB?.relayAttributes;
    return relayAttributes;
  }

  @override
  void initState() {
    super.initState();
    _future = _getRelayDetails(widget.relayURL);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "Relay Detail",
        useLargeTitle: false,
        centerTitle: true,
        backCallback: (){
          OXNavigator.pop(context);
          OXLoading.dismiss();
        },
      ),
      backgroundColor: ThemeColor.color190,
      body: _buildBody(),
    );
  }

  Widget _buildBody(){

    return OXSmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      child: FutureBuilder(
        future: _future,
        builder: (context,snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              OXLoading.dismiss();
              return CommonStatusView(pageStatus: PageStatus.noData);
            }

            Map<String, dynamic>? relayAttributes = snapshot.data;
            List<MapEntry<String, dynamic>> items = [];
            if (relayAttributes != null) {
              items = relayAttributes.entries.toList();
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  for(int i = 0;i < items.length; i++)
                    if (items[i].key.contains('ADMIN'))
                      _buildItem(
                          label: items[i].key,
                          bodyContent: items[i].value['name'],
                          leading: _buildAdminAvatar(items[i].value['picture']),
                          // actions: CommonImage(
                          //   iconName: 'icon_arrow_more.png',
                          //   width: Adapt.px(24),
                          //   height: Adapt.px(24),
                          // ),
                        )
                      else if (items[i].key.contains('SUPPORTED NIPS'))
                      _buildItem(label: items[i].key,bodyContent: items[i].value as String,contentColor: ThemeColor.gradientMainStart)
                    else
                      _buildItem(label: items[i].key,bodyContent: items[i].value as String),
                ],
              ),
            );
          }

          return Container();
        }
      ),
    );
  }

  Widget _buildItem({required String label,String? bodyContent,Widget? leading, Widget? actions,double? height,Color? contentColor}){
    bool isShow = bodyContent != null && bodyContent.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Adapt.px(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isShow ? _buildItemLabel(label: label) : Container(),
          SizedBox(height: Adapt.px(12),),
          isShow ? _buildItemBody(content: bodyContent,leading: leading,actions: actions,contentColor: contentColor) : Container(),
          SizedBox(height: Adapt.px(16),),
        ],
      ),
    );
  }

  Widget _buildItemLabel({required String label}) {
    return Text(
      label,
      style: TextStyle(
          fontSize: Adapt.px(14),
          fontWeight: FontWeight.w600,
          color: ThemeColor.color0),
    );
  }

  Widget _buildItemBody({String? content,Widget? leading, Widget? actions,Color? contentColor}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: Adapt.px(12), horizontal: Adapt.px(16)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Adapt.px(16)),
        color: ThemeColor.color180,
      ),
      child: Row(children: [
        leading ?? Container(),
        Expanded(
          child: Text(
            content ?? '',
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
              fontSize: Adapt.px(16),
              fontWeight: FontWeight.w400,
              color: contentColor ?? ThemeColor.color0,
              height: Adapt.px(22) / Adapt.px(16),
            ),
          ),
        ),
        actions ?? Container()
      ]),
    );
  }

  Widget _buildAdminAvatar(String picture) {
    Image placeholderImage = Image.asset(
      'assets/images/user_image.png',
      fit: BoxFit.cover,
      width: Adapt.px(76),
      height: Adapt.px(76),
      package: 'ox_common',
    );

    return ClipOval(
      child: Container(
        width: Adapt.px(44),
        height: Adapt.px(44),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Adapt.px(44)),
          color: ThemeColor.color180,
        ),
        child: CachedNetworkImage(
          imageUrl: picture,
          fit: BoxFit.cover,
          placeholder: (context, url) => placeholderImage,
          errorWidget: (context, url, error) => placeholderImage,
        ),
      ),
    ).setPadding(EdgeInsets.only(right: Adapt.px(12)));
  }

  void _onRefresh() async {
    _future = _getRelayDetails(widget.relayURL,refresh: true);
    _refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

extension RelayAttributes on RelayDB {

  Future<Map<String, dynamic>> get relayAttributes async {

    UserDB? user = await Account.getUserFromDB(pubkey: pubkey ?? '');

    if(user != null){
      if(user.name == null || user.name!.isEmpty || user.picture == null || user.picture!.isEmpty){
        List<String> pubKeys = [pubkey!];
        Map<String, UserDB> profiles = await Account.syncProfilesFromRelay(pubKeys);
        user = profiles.values.first;
      }
    }

    Map<String, String> relayOwner = <String, String>{
      'name': user?.name ?? '',
      'picture': user?.picture ?? '',
    };
    
    if(supportedNips != null){
      supportedNips = supportedNips!.substring(1,supportedNips!.length - 1);
    }else{
      supportedNips = '';
    }

    return <String, dynamic>{
      'ADMIN': relayOwner,
      'RELAY': url,
      'DESCRIPTION': description ?? '',
      'CONTACT': contact ?? '',
      'SOFTWARE': software ?? '',
      'VERSION': version ?? '',
      'SUPPORTED NIPS': supportedNips,
    };
  }
}
