import 'package:chat/components/AudioPlayComponent.dart';
import 'package:chat/components/ImageChatComponent.dart';
import 'package:chat/components/StickerChatComponent.dart';
import 'package:chat/components/TextChatComponent.dart';
import 'package:chat/components/VideoChatComponent.dart';
import 'package:chat/main.dart';
import 'package:chat/models/ChatMessageModel.dart';
import 'package:chat/utils/AppColors.dart';
import 'package:chat/utils/AppCommon.dart';
import 'package:chat/utils/AppConstants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

class ChatItemWidget extends StatefulWidget {
  final ChatMessageModel? data;

  ChatItemWidget({this.data});

  @override
  _ChatItemWidgetState createState() => _ChatItemWidgetState();
}

class _ChatItemWidgetState extends State<ChatItemWidget> {
  String? images;

  void initState() {
    super.initState();
    init();
  }

  init() async {
    //
  }

  @override
  Widget build(BuildContext context) {
    String time;

    DateTime date = DateTime.fromMicrosecondsSinceEpoch(widget.data!.createdAt! * 1000);
    if (date.day == DateTime.now().day) {
      time = DateFormat('hh:mm a').format(DateTime.fromMicrosecondsSinceEpoch(widget.data!.createdAt! * 1000));
    } else {
      time = DateFormat('dd-mm-yyyy hh:mm a').format(DateTime.fromMicrosecondsSinceEpoch(widget.data!.createdAt! * 1000));
    }

    EdgeInsetsGeometry customPadding(String? messageTypes) {
      switch (messageTypes) {
        case TEXT:
          return EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        case IMAGE:
        case VIDEO:
        case AUDIO:
        return EdgeInsets.symmetric(horizontal: 4, vertical: 4);
        default:
          return EdgeInsets.symmetric(horizontal: 4, vertical: 4);
      }
    }

    Widget chatItem(String? messageTypes) {
      switch (messageTypes) {
        case TEXT:
          return TextChatComponent(data: widget.data!, time: time);

        case IMAGE:
          return ImageChatComponent(data: widget.data!, time: time);

        case VIDEO:
          return VideoChatComponent(data: widget.data!, time: time);

        case AUDIO:
          return AudioPlayComponent(data: widget.data, time: time);

        case STICKER:
          return StickerChatComponent(data: widget.data!, time: time, padding: customPadding(messageTypes));

        default:
          return Container();
      }
    }

    return GestureDetector(
      onLongPress: !widget.data!.isMe!
          ? null
          : () async {
              bool? res = await showConfirmDialog(context, 'Delete Message', buttonColor: secondaryColor);
              if (res ?? false) {
                hideKeyboard(context);
                chatMessageService
                    .deleteSingleMessage(
                  senderId: widget.data!.senderId,
                  receiverId: widget.data!.receiverId!,
                  documentId: widget.data!.id,
                )
                    .then((value) {
                  //
                }).catchError(
                  (e) {
                    log(e.toString());
                  },
                );
              }
            },
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.data!.isMe.validate() ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisAlignment: widget.data!.isMe! ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              margin: widget.data!.isMe.validate()
                  ? EdgeInsets.only(top: 0.0, bottom: 0.0, left: isRTL ? 0 : context.width() * 0.25, right: 8)
                  : EdgeInsets.only(top: 2.0, bottom: 2.0, left: 8, right: isRTL ? 0 : context.width() * 0.25),
              padding: customPadding(widget.data!.messageType),
              decoration: widget.data!.messageType != MessageType.STICKER.name
                  ? BoxDecoration(
                      boxShadow: appStore.isDarkMode ? null : defaultBoxShadow(),
                      color: widget.data!.isMe.validate() ? primaryColor : context.cardColor,
                      borderRadius: widget.data!.isMe.validate()
                          ? radiusOnly(
                              bottomLeft: chatMsgRadius,
                              topLeft: chatMsgRadius,
                              bottomRight: 0,
                              topRight: chatMsgRadius,
                            )
                          : radiusOnly(
                              bottomLeft: 0,
                              topLeft: chatMsgRadius,
                              bottomRight: chatMsgRadius,
                              topRight: chatMsgRadius,
                            ),
                    )
                  : null,
              child: chatItem(widget.data!.messageType),
            ),
          ],
        ),
        margin: EdgeInsets.only(top: 2, bottom: 2),
      ),
    );
  }
}
