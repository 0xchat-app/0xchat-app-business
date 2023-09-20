
import 'package:flutter/material.dart';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:chatcore/chat-core.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:ox_chat/widget/mention_user_list.dart';
import 'package:ox_common/model/chat_session_model.dart';
import 'package:ox_common/model/chat_type.dart';

extension ChatSessionModelMentionEx on ChatSessionModel {
  bool get isSupportMention {
    switch (this.chatType) {
      case ChatType.chatChannel:
        return true;
      default:
        return false;
    }
  }
}

class ProfileMentionWrapper {

  ProfileMentionWrapper(this.source, [this.user]) {
    if (user == null) {
      final userFuture = Account.sharedInstance.getUserInfo(source.pubkey);
      if (userFuture is Future<UserDB?>) {
        userFuture.then((value){
          user = value;
        });
      } else {
        user = userFuture;
      }
    }
  }

  factory ProfileMentionWrapper.create({
    required int start,
    required int end,
    required String pubkey,
    List<String> relays = const [],
  }) {
    return ProfileMentionWrapper(ProfileMention(start, end, pubkey, relays));
  }

  ProfileMention source;
  UserDB? user;

  ProfileMentionWrapper copyWith({int? start, int? end, String? pubkey, List<String>? relays, UserDB? user}) {
    return ProfileMentionWrapper(
      ProfileMention(
        start ?? this.source.start,
        end ?? this.source.end,
        pubkey ?? this.source.pubkey,
        relays ?? this.source.relays,
      ),
      user ?? this.user,
    );
  }
}

const _mentionPrefix = '@';
const _mentionSuffix = ' ';

class ChatMentionHandler {

  TextEditingController _inputController = TextEditingController();

  List<ProfileMentionWrapper> mentions = [];

  List<UserDB> allUser = [];

  final userList = ValueNotifier<List<UserDB>>([]);
}

extension ChatMentionMessageEx on ChatMentionHandler {
  String? tryEncoder(types.Message message) {
    if (mentions.isNotEmpty && message is types.TextMessage) {
      final originText = message.text;
      _updateMentions(originText);
      return Nip27.encodeProfileMention(mentions.map((e) => e.source).toList(), originText);
    }
    return null;
  }

  static Future<String?> tryDecoder(String text) async {
    List<ProfileMention> mentions = Nip27.decodeProfileMention(text);
    if (mentions.isEmpty) return null;
    await Future.forEach(mentions.reversed, (mention) async {
      final userName = (await Account.sharedInstance.getUserInfo(mention.pubkey))?.name ?? '';
      text = text.replaceRange(mention.start, mention.end, '$_mentionPrefix$userName');
    });
    return text;
  }
}

extension ChatMentionInputFieldEx on ChatMentionHandler {

  TextEditingController get inputController => _inputController;
  void set inputController(value) {
    _inputController.removeListener(_inputFieldOnTextChanged);
    _inputController = value;
    _inputController.addListener(_inputFieldOnTextChanged);
  }

  String mentionTextString(String text) => '$_mentionPrefix$text$_mentionSuffix';

  void _inputFieldOnTextChanged() {
    final newText = inputController.text;
    _updateMentions(newText);
    _showUserListIfNeeded(newText, inputController.selection);
  }

  void _updateMentions(String newText) {
    final newMentions = <ProfileMentionWrapper>[];
    final Map<String, int> searchStarrMap = {};

    mentions.forEach((mention) {
      final userName = mention.user?.name;
      if (userName == null) return ;

      final target = mentionTextString(userName);
      var searchStart = searchStarrMap[userName] ?? 0;
      if (searchStart > newText.length) return ;

      final start = newText.indexOf(target, searchStart);
      if (start < 0) return ;

      final newMention = mention.copyWith(start: start, end: start + target.length - 1);
      newMentions.add(newMention);
      searchStarrMap[userName] = newMention.source.end + 1;
    });

    mentions.clear();
    mentions.addAll(newMentions);
  }

  void _showUserListIfNeeded(String newText, TextSelection selection) {

    if (!newText.contains(_mentionPrefix)) {
      _updateUserListValue([]);
      return ;
    }

    final cursorPosition = selection.start;
    if (!selection.isCollapsed) {
      _updateUserListValue([]);
      return ;
    }

    if (newText.endsWith(_mentionPrefix)) {
      _updateUserListValue(allUser);
      return ;
    }
    final prefixStart = newText.lastIndexOf(_mentionPrefix, cursorPosition);
    if (prefixStart < 0) {
      _updateUserListValue([]);
      return ;
    }

    // Check if the last target string's mention has been recorded.
    var isRecorded = false;
    final searchText = newText.substring(prefixStart + 1, cursorPosition).toLowerCase();
    mentions.forEach((mention) {
      if (isRecorded) return ;
      final userName = mention.user?.name;
      if (userName == null) return ;

      final target = '$_mentionPrefix$userName$_mentionSuffix';
      if (searchText == target) isRecorded = true;
    });

    if (isRecorded) {
      _updateUserListValue([]);
      return ;
    }

    // Try search user.
    final result = allUser.where((user) {
      final isNameMatch = user.name?.toLowerCase().contains(searchText) ?? false;
      final isDNSMatch = user.dns?.toLowerCase().contains(searchText) ?? false;
      final isNickNameMatch = user.nickName?.toLowerCase().contains(searchText) ?? false;
      return isNameMatch || isDNSMatch || isNickNameMatch;
    }).toList();

    _updateUserListValue(result);
  }
}

extension ChatMentionUserListEx on ChatMentionHandler {

  void _updateUserListValue(List<UserDB> value) {
    userList.value = value;
  }

  Widget buildMentionUserList() {
    return MentionUserList(userList, mentionUserListOnPressed);
  }

  void mentionUserListOnPressed(UserDB item) {
    final originText = inputController.text;
    final selection = inputController.selection;
    final cursorPosition = selection.start;
    if (!selection.isCollapsed) {
      return ;
    }

    final prefixStart = originText.lastIndexOf(_mentionPrefix, cursorPosition);
    if (prefixStart < 0) {
      return ;
    }

    final userName = item.name ?? '';
    if (userName.isEmpty) return ;

    final replaceText = mentionTextString(userName);
    final newText = originText.replaceRange(prefixStart, cursorPosition, replaceText);
    final end = prefixStart + replaceText.length;
    inputController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: end),
    );

    final mention = ProfileMentionWrapper.create(
      start: prefixStart,
      end: end,
      pubkey: item.pubKey,
      relays: ['wss://relay.0xchat.com'],
    );
    mentions.add(mention);
  }
}