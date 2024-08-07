
import 'package:flutter/foundation.dart';

abstract class ChatTypeKey {
  // DB Option
  String getSQLFilter();
  List<String> getSQLFilterArgs();

  // Equatable
  bool operator ==(Object other);
  int get hashCode;
}

@immutable
class PrivateChatKey implements ChatTypeKey {
  final String userId1;
  final String userId2;

  PrivateChatKey(this.userId1, this.userId2);

  String getSQLFilter() {
    return '(sessionId IS NULL OR sessionId = "") AND ((sender = ? AND receiver = ? ) OR (sender = ? AND receiver = ? )) ';
  }

  List<String> getSQLFilterArgs() {
    return [userId1, userId2, userId2, userId1];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrivateChatKey &&
        ((other.userId1 == userId1 && other.userId2 == userId2) || (other.userId1 == userId2 && other.userId2 == userId1));
  }

  @override
  int get hashCode => userId1.hashCode ^ userId2.hashCode;

  @override
  String toString() {
    return '${super.toString()}, userId1: $userId1, userId2: $userId2';
  }
}

@immutable
class GroupKey implements ChatTypeKey {
  final String groupId;

  GroupKey(this.groupId);

  String getSQLFilter() {
    return ' groupId = ? ';
  }

  List<String> getSQLFilterArgs() {
    return [groupId];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupKey && other.groupId == groupId;
  }

  @override
  int get hashCode => groupId.hashCode;

  @override
  String toString() {
    return '${super.toString()}, groupId: $groupId';
  }
}

@immutable
class ChannelKey implements ChatTypeKey {
  final String channelId;

  ChannelKey(this.channelId);

  String getSQLFilter() {
    return ' groupId = ? ';
  }

  List<String> getSQLFilterArgs() {
    return [channelId];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChannelKey && other.channelId == channelId;
  }

  @override
  int get hashCode => channelId.hashCode;

  @override
  String toString() {
    return '${super.toString()}, channelId: $channelId';
  }
}

@immutable
class SecretChatKey implements ChatTypeKey {
  final String sessionId;

  SecretChatKey(this.sessionId);

  String getSQLFilter() {
    return ' sessionId = ? ';
  }

  List<String> getSQLFilterArgs() {
    return [sessionId];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecretChatKey && other.sessionId == sessionId;
  }

  @override
  int get hashCode => sessionId.hashCode;

  @override
  String toString() {
    return '${super.toString()}, sessionId: $sessionId';
  }
}

@immutable
class RelayGroupKey implements ChatTypeKey {
  final String groupId;

  RelayGroupKey(this.groupId);

  String getSQLFilter() {
    return ' groupId = ? ';
  }

  List<String> getSQLFilterArgs() {
    return [groupId];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelayGroupKey && other.groupId == groupId;
  }

  @override
  int get hashCode => groupId.hashCode;

  @override
  String toString() {
    return '${super.toString()}, groupId: $groupId';
  }
}