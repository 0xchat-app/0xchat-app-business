import 'package:flutter/material.dart';
import 'package:ox_common/widgets/common_appbar.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_wallet/page/wallet_send_ecash_coin_selection_page.dart';
import 'package:ox_wallet/page/wallet_send_ecash_new_token_page.dart';
import 'package:ox_wallet/widget/common_card.dart';
import 'package:ox_wallet/widget/switch_widget.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/theme_button.dart';
import 'package:ox_common/navigator/navigator.dart';

class WalletSendEcashOverviewPage extends StatefulWidget {
  const WalletSendEcashOverviewPage({super.key});

  @override
  State<WalletSendEcashOverviewPage> createState() => _WalletSendEcashOverviewPageState();
}

class _WalletSendEcashOverviewPageState extends State<WalletSendEcashOverviewPage> {

  List<CardItemModel> _items = [];

  bool _isCoinSelection = false;

  @override
  void initState() {
    _items = [
      CardItemModel(label: 'Payment type',content: 'Send Ecash',),
      CardItemModel(label: 'Mint',content: 'mint.tangjingxing.com',),
      CardItemModel(label: 'Amount',content: '255 Sats',),
      CardItemModel(label: 'Balance after TX',content: '45 Sats',),
      CardItemModel(
        label: 'Coin Selection',
        content: 'Your Ecash balance is essentially a collection of coin-sets. Coin selection allows you to choose the coins you want to spend. Coin- sets are assigned a keyset-ID by the mint, which may change over time. Newly added keysets are highlighted in green. It is advisable to spend older sets first.',
      ),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.color190,
      appBar: CommonAppBar(
        title: 'Send Ecash',
        centerTitle: true,
        useLargeTitle: false,
      ),
      body: ListView(
        children: [
          CommonCard(
            verticalPadding: 0,
            horizontalPadding: 0,
            child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemBuilder: _buildItem,
                separatorBuilder: (context,index) => Container(height: 0.5.px,color: ThemeColor.color160,),
                itemCount: _items.length),
          ).setPaddingOnly(top: 12.px),
          ThemeButton(
            text: 'Create Token',
            height: 48.px,
            onTap: _createToken,
          ).setPaddingOnly(top: 24.px),
        ],
      ).setPadding(EdgeInsets.symmetric(horizontal: 24.px)),
    );
  }

  Widget _buildItem(context,index){
    List<CommonCardItem> commonCardItemList= _items.map((element){
      if(element.label == 'Coin Selection'){
        return CommonCardItem(
          label: element.label,
          content: element.content,
          action: SwitchWidget(
            value: _isCoinSelection,
            onChanged: (value) async {
              if (value) {
                final result = await OXNavigator.pushPage(context, (context) => const WalletSendEcashCoinSelectionPage());
                if(result != null && result as bool){
                  _isCoinSelection = true;
                  _items.addAll([
                    CardItemModel(label: 'Selected',content: '44/25 Sats',),
                    CardItemModel(label: 'Change',content: 'Sats',),
                  ]);
                }else{
                  _isCoinSelection = false;
                }
              }else{
                _items.removeWhere((element) => element.label == 'Selected' || element.label == 'Change');
                _isCoinSelection = false;
              }
              setState(() {});
            },
          ),
        );
      }
      return CommonCardItem(label: element.label,content: element.content);
    }).toList();
    return commonCardItemList[index];
  }

  void _createToken(){
    OXNavigator.pushPage(context, (context) => const WalletSendEcashNewTokenPage());
  }
}
