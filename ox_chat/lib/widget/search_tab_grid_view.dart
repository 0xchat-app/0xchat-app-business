import 'package:flutter/material.dart';
import 'package:ox_chat/page/contacts/contact_media_widget.dart';
import 'package:ox_chat/widget/media_message_viewer.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/widgets/gallery/gallery_image_widget.dart';

class SearchTabGridView extends StatefulWidget {
  // final List<T> data;
  final List<MessageDBISAR> data;

  // final Widget Function(BuildContext context, T item) builder;

  const SearchTabGridView({
    super.key,
    required this.data,
    // required this.builder,
  });

  @override
  State<SearchTabGridView> createState() => _SearchTabGridViewState();
}

class _SearchTabGridViewState extends State<SearchTabGridView> {

  List<MessageDBISAR> _mediaMessages = [];

  @override
  void initState() {
    super.initState();
    _getMediaList();
  }

  void _getMediaList() async {
    Map result = await Messages.loadMessagesFromDB(
      messageTypes: [
        MessageType.image,
        MessageType.encryptedImage,
        MessageType.video,
        MessageType.encryptedVideo,
      ],
    );
    _mediaMessages = result['messages'] ?? <MessageDBISAR>[];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.px,vertical: 2.px),
      shrinkWrap: true,
      itemCount: _mediaMessages.length,
      itemBuilder: (context, index) {
        final mediaMessage = _mediaMessages[index];
        if (MessageDBISAR.stringtoMessageType(mediaMessage.type) == MessageType.image ||
            MessageDBISAR.stringtoMessageType(mediaMessage.type) == MessageType.encryptedImage) {
          return GestureDetector(
            onTap: () {
              OXNavigator.pushPage(
                context,
                (context) => MediaMessageViewer(
                  messages: _mediaMessages,
                  initialIndex: index,
                ),
              );
            },
            child: GalleryImageWidget(
              uri: mediaMessage.decryptContent,
              fit: BoxFit.cover,
              decryptKey: mediaMessage.decryptSecret,
              decryptNonce: mediaMessage.decryptNonce,
            ),
          );
        }

        return MediaVideoWidget(messageDBISAR: mediaMessage);
      },
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
    );
  }
}
