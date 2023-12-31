import 'dart:async';
import 'dart:convert';

import 'package:nostr_core_dart/nostr.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:ox_chat/manager/chat_data_cache.dart';
import 'package:ox_chat/manager/chat_message_helper.dart';
import 'package:ox_chat/utils/chat_log_utils.dart';
import 'package:ox_chat/utils/send_message/chat_strategy_factory.dart';
import 'package:ox_common/model/chat_session_model.dart';
import 'package:ox_chat/model/message_content_model.dart';
import 'package:ox_chat/utils/general_handler/chat_nostr_scheme_handler.dart';
import 'package:ox_chat/utils/message_factory.dart';
import 'package:chatcore/chat-core.dart';

typedef MessageContentEncoder = FutureOr<String?> Function(
    types.Message message);

class ChatSendMessageHelper {
  static Future<String?> sendMessage({
    required ChatSessionModel session,
    required types.Message message,
    bool isLocal = false,
    MessageContentEncoder? contentEncoder,
  }) async {
    // prepare data
    var sendFinish = OXValue(false);
    final type = message.dbMessageType(
        encrypt: message.fileEncryptionType != types.EncryptionType.none);
    final contentString = (await contentEncoder?.call(message)) ??
        message.contentString(message.content);
    final replayId = message.repliedMessage?.id ?? '';

    // create chat sender strategy
    final senderStrategy = ChatStrategyFactory.getStrategy(session);
    // for test
    // senderStrategy.session.expiration = currentUnixTimestampSeconds() + 5;
    // prepare send event
    Event? event;
    var plaintEvent = message.sourceKey;
    if (plaintEvent != null && plaintEvent is String) {
      try {
        event = Event.fromJson(jsonDecode(plaintEvent));
      } catch (_) {
        return 'send message error';
      }
    }

    if (event == null) {
      event = await senderStrategy.getSendMessageEvent(
        messageType: type,
        contentString: contentString,
        replayId: replayId,
        decryptSecret: message.decryptKey,
      );
    }
    if (event == null) {
      return 'send message fail';
    }

    final sourceKey = jsonEncode(event);
    types.Message sendMsg = message.copyWith(
      id: event.id,
      sourceKey: sourceKey,
      expiration: senderStrategy.session.expiration == null
          ? null
          : senderStrategy.session.expiration! + currentUnixTimestampSeconds(),
    );

    if (sendMsg.type == types.MessageType.text &&
        ChatNostrSchemeHandle.getNostrScheme(sendMsg.content) != null) {
      sendMsg = CustomMessageFactory().createTemplateMessage(
        author: sendMsg.author,
        timestamp: sendMsg.createdAt,
        roomId: session.chatId,
        id: sendMsg.id,
        title: 'Loading...',
        content: 'Loading...',
        icon: '',
        link: '',
      );
      ChatNostrSchemeHandle.tryDecodeNostrScheme(message.content)
          .then((nostrSchemeContent) async {
        if (nostrSchemeContent != null) {
          MessageContentModel contentModel = MessageContentModel();
          contentModel.content = nostrSchemeContent;
          var chatMessage =
              await ChatDataCache.shared.getMessage(null, session, sendMsg.id);
          if (chatMessage != null) {
            chatMessage = CustomMessageFactory().createMessage(
                author: chatMessage.author,
                timestamp: chatMessage.createdAt,
                roomId: chatMessage.roomId ?? '',
                remoteId: chatMessage.remoteId ?? '',
                sourceKey: chatMessage.sourceKey,
                contentModel: contentModel,
                status: chatMessage.status ?? types.Status.sending)!;
            ChatDataCache.shared.updateMessage(
                message: chatMessage, session: session, originMessage: sendMsg);
          }
        }
      });
    } else if (sendMsg.type == types.MessageType.text &&
        Zaps.isLightningInvoice(sendMsg.content)) {
      Map<String, String> req = Zaps.decodeInvoice(sendMsg.content);
      sendMsg = CustomMessageFactory().createZapsMessage(
        author: sendMsg.author,
        timestamp: sendMsg.createdAt,
        roomId: session.chatId,
        id: sendMsg.id,
        remoteId: sendMsg.remoteId,
        sourceKey: sourceKey,
        zapper: '',
        invoice: sendMsg.content,
        amount: req['amount'] ?? '0',
        description: 'Best wishes',
        expiration: sendMsg.expiration,
      );
    }

    ChatLogUtils.info(
      className: 'ChatSendMessageHelper',
      funcName: 'sendMessage',
      message:
          'content: ${sendMsg.content}, type: ${sendMsg.type}, messageKind: ${senderStrategy.session.messageKind}, expiration: ${senderStrategy.session.expiration}',
    );

    ChatDataCache.shared.addNewMessage(session: session, message: sendMsg);

    senderStrategy
        .doSendMessageAction(
      messageType: type,
      contentString: contentString,
      replayId: replayId,
      decryptSecret: message.decryptKey,
      event: event,
      isLocal: isLocal,
    )
        .then((event) {
      sendFinish.value = true;
      final updatedMessage = sendMsg.copyWith(
        remoteId: event.eventId,
        status: event.status ? types.Status.sent : types.Status.error,
      );
      ChatDataCache.shared
          .updateMessage(session: session, message: updatedMessage);
    });

    // If the message is not sent within a short period of time, change the status to the sending state
    _setMessageSendingStatusIfNeeded(session, sendFinish, sendMsg);

    return null;
  }

  static void updateMessageStatus(
      ChatSessionModel session, types.Message message, types.Status status) {
    final updatedMessage = message.copyWith(
      status: status,
    );
    ChatDataCache.shared
        .updateMessage(session: session, message: updatedMessage);
  }

  static void _setMessageSendingStatusIfNeeded(ChatSessionModel session,
      OXValue<bool> sendFinish, types.Message message) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!sendFinish.value) {
        updateMessageStatus(session, message, types.Status.sending);
      }
    });
  }
}
