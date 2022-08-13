import 'package:chat/main.dart';
import 'package:chat/models/ChatMessageModel.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class TextChatComponent extends StatelessWidget {
  ChatMessageModel data;
  String time;

  TextChatComponent({required this.data, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: data.isMe! ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(data.message!,
            style: primaryTextStyle(
              color: data.isMe! ? Colors.white : textPrimaryColorGlobal,
              size: mChatFontSize,
            ),
            maxLines: null),
        1.height,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: primaryTextStyle(color: !data.isMe.validate() ? Colors.blueGrey.withOpacity(0.6) : whiteColor.withOpacity(0.6), size: 10),
            ),
            2.width,
            data.isMe!
                ? !data.isMessageRead!
                    ? Icon(Icons.done, size: 12, color: Colors.white60)
                    : Icon(Icons.done_all, size: 12, color: Colors.white60)
                : Offstage()
          ],
        ),
      ],
    );
  }
}
