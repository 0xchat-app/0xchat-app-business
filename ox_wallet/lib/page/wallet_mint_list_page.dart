import 'package:flutter/material.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/widgets/common_appbar.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:ox_common/widgets/theme_button.dart';
import 'package:ox_wallet/page/wallet_mint_management_add_page.dart';
import 'package:ox_wallet/page/wallet_mint_management_page.dart';
import 'package:ox_wallet/services/ecash_manager.dart';
import 'package:cashu_dart/cashu_dart.dart';
import 'package:ox_wallet/widget/common_card.dart';

class WalletMintListPage extends StatefulWidget {
  const WalletMintListPage({super.key});

  @override
  State<WalletMintListPage> createState() => _WalletMintListPageState();
}

class _WalletMintListPageState extends State<WalletMintListPage> {

  List<IMint> mintItems = [];

  @override
  void initState() {
    mintItems = EcashManager.shared.mintList;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.color190,
      appBar: CommonAppBar(
        title: 'Mints',
        centerTitle: true,
        useLargeTitle: false,
      ),
      body: Column(
        children: [
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) => CommonCard(
              verticalPadding: 8.px,
              child: _buildItem(
                title: _mintTitle(index),
                subTitle: '${mintItems[index].balance} Sats',
                onTap: () => OXNavigator.pushPage(
                    context,
                    (context) => WalletMintManagementPage(mint: mintItems[index],)).then((value) {
                  setState(() {});
                }),
              ),
            ),
            separatorBuilder: (context,index) => SizedBox(height: 12.px,),
            itemCount: mintItems.length,
          ),
          mintItems.isNotEmpty ? SizedBox(height: 24.px,) : Container(),
          ThemeButton(text: 'Add Mint',height: 48.px,onTap: () => OXNavigator.pushPage(context, (context) => const WalletMintManagementAddPage()).then((value) {
            if (value != null && value as bool) {
                setState(() {});
              }
            }),),
        ],
      ).setPadding(EdgeInsets.symmetric(horizontal: 24.px,vertical: 12.px)),
    );
  }

  Widget _buildItem({required String title,required String subTitle,Function()? onTap}){
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title ?? '',style: TextStyle(fontSize: 16.px,color: ThemeColor.color0,height: 22.px / 16.px,overflow: TextOverflow.ellipsis),),
                Text(subTitle,style: TextStyle(fontSize: 14.px,height: 20.px / 14.px),),
              ],
            ),
          ),
          CommonImage(
            iconName: 'icon_wallet_more_arrow.png',
            size: 24.px,
            package: 'ox_wallet',
          )
        ],
      ),
    );
  }

  String _mintTitle(int index){
    final defaultTitle = mintItems[index].name.isNotEmpty ? mintItems[index].name : mintItems[index].mintURL;
    final suffix = index == 0 ? ' (Default)' : '';
    final result = '$defaultTitle$suffix';
    if(EcashManager.shared.defaultIMint == null) return defaultTitle;
    return result;
  }
}
