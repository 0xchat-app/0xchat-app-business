
import 'dart:math';

import 'package:cashu_dart/cashu_dart.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_chat/manager/chat_message_helper.dart';
import 'package:ox_chat/page/ecash/ecash_info_isar.dart';
import 'package:ox_chat/page/ecash/ecash_signature_record.dart';
import 'package:ox_chat/page/ecash/ecash_signature_record_isar.dart';
import 'package:ox_chat/utils/custom_message_utils.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:ox_common/business_interface/ox_chat/custom_message_type.dart';
import 'package:ox_common/business_interface/ox_chat/utils.dart';
import 'package:ox_common/utils/encrypt_utils.dart';
import 'package:isar/isar.dart';

class EcashHelper {

  static Future<EcashPackage> createPackageFromMessage(types.CustomMessage message) async {

    String senderPubKey = message.author.id;
    int totalAmount = 0;
    String memo = '';
    List<String> tokenList = [];
    List<UserDBISAR> receiver = [];
    List<EcashPackageSignee> signees = [];
    String validityDate = '';

    switch (message.customType) {
      case CustomMessageType.ecash:
        totalAmount = EcashMessageEx(message).amount;
        memo = EcashMessageEx(message).description;
        tokenList = EcashMessageEx(message).tokenList;
        break ;
      case CustomMessageType.ecashV2:
        totalAmount = EcashV2MessageEx(message).amount;
        memo = EcashV2MessageEx(message).description;
        tokenList = EcashV2MessageEx(message).tokenList;
        receiver = EcashV2MessageEx(message).receiverPubkeys
            .map((pubkey) => Account.sharedInstance.getUserInfo(pubkey))
            .where((user) => user is UserDBISAR)
            .toList()
            .cast<UserDBISAR>();
        signees = EcashV2MessageEx(message).signees
            .map((signee) => (Account.sharedInstance.getUserInfo(signee.$1), signee.$2))
            .where((e) => e.$1 is UserDBISAR)
            .toList()
            .cast<EcashPackageSignee>();
        validityDate = EcashV2MessageEx(message).validityDate;
      default:
        break ;
    }

    final tokenInfoList = <EcashTokenInfo>[];
    final historyMap = await getHistoryForTokenList(tokenList);
    for (final token in tokenList) {
      final tokenMD5 = EncryptUtils.generateMd5(token);
      final info = Cashu.infoOfToken(token);
      if (info == null) continue;
      final tokenInfo = EcashTokenInfo(
        token: token,
        amount: info.amount,
        redeemHistory: historyMap[tokenMD5],
      );
      tokenInfoList.add(tokenInfo);
    }

    return EcashPackage(
      messageId: message.id,
      totalAmount: totalAmount,
      tokenInfoList: tokenInfoList,
      memo: memo,
      senderPubKey: senderPubKey,
      receiver: receiver,
      signees: signees,
      validityDate: validityDate,
    );
  }

  static Future<Map<String, EcashReceiptHistoryISAR>> getHistoryForTokenList(List<String> tokenList) async {
    final tokenMD5List = tokenList.map((token) => EncryptUtils.generateMd5(token));
    final isar = DBISAR.sharedInstance.isar;
    final historyByOther = await isar.ecashReceiptHistoryISARs.filter()
        .anyOf(tokenMD5List, (q, tokenMD5) => q.tokenMD5EqualTo(tokenMD5))
        .findAll();

    final historyByMe = await Cashu.getHistory(value: tokenList);

    final Map<String, EcashReceiptHistoryISAR> result = {};
    historyByOther.forEach((entry) {
      result[entry.tokenMD5] = entry;
    });
    historyByMe.forEach((entry) {
      if (entry.amount > 0) {
        final receiptEntry = entry.toReceiptHistory();
        result[receiptEntry.tokenMD5] = receiptEntry;
      }
    });

    return result;
  }

  static Future<EcashReceiptHistoryISAR> addReceiptHistoryForToken(String token) async {
    final history = EcashReceiptHistoryISAR(
      tokenMD5: EncryptUtils.generateMd5(token),
      isMe: false,
    );
    await DBISAR.sharedInstance.isar.writeTxn(() async {
      await DBISAR.sharedInstance.isar.ecashReceiptHistoryISARs.put(history);
    });
    return history;
  }

  static updateReceiptHistoryForPackage(EcashPackage package) async {
    final unreceivedToken = package.tokenInfoList
        .where((info) => info.redeemHistory == null)
        .toList();
    for (final tokenInfo in unreceivedToken) {
      final token = tokenInfo.token;
      final spendable = await Cashu.isEcashTokenSpendableFromToken(token);
      if (spendable == false) {
        final history = await addReceiptHistoryForToken(token);
        tokenInfo.redeemHistory = history;
      }
    }
  }

  static Future<bool?> tryRedeemTokenList(EcashPackage package) async {
    final unreceivedToken = package.tokenInfoList
        .where((info) => info.redeemHistory == null)
        .toList()
        ..shuffle();

    var hasRedeemError = false;
    for (final tokenInfo in unreceivedToken) {
      final token = tokenInfo.token;
      final response = await Cashu.redeemEcash(
        ecashString: token,
        redeemPrivateKey: [Account.sharedInstance.currentPrivkey],
        signFunction: (key, message) async {
          return Account.getSignatureWithSecret(message, key);
        },
      );
      if (response.code == ResponseCode.tokenAlreadySpentError) {
        final history = await addReceiptHistoryForToken(token);
        tokenInfo.redeemHistory = history;
        continue ;
      }

      if (response.isSuccess) {
        final history = (await Cashu.getHistory(value: [token])).firstOrNull;
        tokenInfo.redeemHistory = history?.toReceiptHistory();
        return true;
      }

      hasRedeemError = true;
    }

    if (hasRedeemError) return null;

    return false;
  }

  static Future<String> addSignatureToToken(String token) async {
    return await Cashu.addSignatureToToken(
      ecashString: token,
      privateKeyList: [Account.sharedInstance.currentPrivkey],
      signFunction: (key, message) async {
        return await Account.getSignatureWithSecret(message, key);
      },
    ) ?? '';
  }

  static Future<bool> isMessageSigned(String messageId) async {
    final isar = DBISAR.sharedInstance.isar;
    final signRecord = await isar.ecashSignatureRecordISARs.filter().messageIdEqualTo(messageId).findFirst();
    return signRecord != null;
  }

  static Future<bool> setMessageSigned(String messageId) async {
    await DBISAR.sharedInstance.isar.writeTxn(() async {
      await DBISAR.sharedInstance.isar.ecashSignatureRecordISARs
          .put(EcashSignatureRecordISAR(messageId: messageId));
    });
    return true;
  }
}

extension IHistoryEntryEcashEx on IHistoryEntry {
  EcashReceiptHistoryISAR toReceiptHistory() =>
    EcashReceiptHistoryISAR(
      tokenMD5: EncryptUtils.generateMd5(value),
      isMe: true,
      timestamp: timestamp.toInt(),
    );
}