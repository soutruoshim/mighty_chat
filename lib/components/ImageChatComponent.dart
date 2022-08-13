import 'package:chat/components/FullScreenImageWidget.dart';
import 'package:chat/models/ChatMessageModel.dart';
import 'package:chat/utils/Appwidgets.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ImageChatComponent extends StatelessWidget {
  final ChatMessageModel data;
  final String time;

  ImageChatComponent({required this.data, required this.time});

  @override
  Widget build(BuildContext context) {
    if (data.photoUrl.validate().isNotEmpty || data.photoUrl != null) {
      return Stack(
        children: [
          cachedImage(data.photoUrl.validate(), fit: BoxFit.contain, width: 250).cornerRadiusWithClipRRect(10),
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, style: primaryTextStyle(color: !data.isMe.validate() ? Colors.blueGrey.withOpacity(0.6) : whiteColor.withOpacity(0.6), size: 10)),
                2.width,
                data.isMe!
                    ? !data.isMessageRead!
                        ? Icon(Icons.done, size: 12, color: Colors.white60)
                        : Icon(Icons.done_all, size: 12, color: Colors.white60)
                    : Offstage()
              ],
            ),
          )
        ],
      ).onTap(
        () {
          FullScreenImageWidget(
            photoUrl: data.photoUrl,
            isFromChat: true,
            name: data.messageType,
          ).launch(context);
        },
      );
    } else {
      return Container(child: Loader(), height: 250, width: 250);
    }
  }
}
