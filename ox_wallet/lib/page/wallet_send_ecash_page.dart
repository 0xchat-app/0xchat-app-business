import 'package:flutter/material.dart';
import 'package:ox_common/log_util.dart';
import 'package:ox_common/widgets/common_appbar.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_wallet/widget/common_card.dart';
import 'package:ox_wallet/widget/sats_amount_card.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/widgets/theme_button.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:cashu_dart/cashu_dart.dart';
import 'wallet_send_ecash_overview_page.dart';

class WalletSendEcashPage extends StatelessWidget {

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  WalletSendEcashPage({super.key});

  String get amount => _amountController.text;
  String get description => _descriptionController.text;
  bool get enable => amount.isNotEmpty && double.parse(amount) > 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        backgroundColor: ThemeColor.color190,
        appBar: CommonAppBar(
          title: 'Send Ecash',
          centerTitle: true,
          useLargeTitle: false,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SatsAmountCard(controller: _amountController,).setPaddingOnly(top: 12.px),
            _buildDescription(),
            _buildContinueButton(),
          ],
        ).setPadding(EdgeInsets.symmetric(horizontal: 24.px)),
      ),
    );
  }

  Widget _buildDescription(){
    return CommonCard(
      verticalPadding: 24.px,
      child: TextField(
        controller: _descriptionController,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
          hintText: 'This is Description',
          hintStyle: TextStyle(fontSize: 13.sp)
        ),
      ),
    ).setPaddingOnly(top: 24.px);
  }

  Widget _buildContinueButton() {
    return ValueListenableBuilder(
        valueListenable: _amountController,
        builder: (context,value,child) {
          return ThemeButton(
            text: 'Continue',
            height: 48.px,
            enable: enable,
            // onTap: () => OXNavigator.pushPage(context, (context) => const WalletSendEcashOverviewPage()),
            onTap: () => _sendEcash(context),
          ).setPaddingOnly(top: 24.px);
        }
    );
  }
  
  Future<void> _sendEcash(BuildContext context) async {
    try {
      List<IMint> mintList = Cashu.mintList();
      IMint mint = mintList.first;
      if (mint.balance <= 0) {
        CommonToast.instance.show(context, 'Insufficient mint balance');
        return;
      }
      int amountSats = int.parse(amount);
      await Cashu.sendEcash(mint: mint, amount: amountSats, memo: description);
    } catch (e, s) {
      LogUtil.e('');
    }
  }
}
