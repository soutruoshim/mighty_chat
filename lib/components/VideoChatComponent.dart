import 'package:chat/components/FullScreenImageWidget.dart';
import 'package:chat/models/ChatMessageModel.dart';
import 'package:chat/utils/Appwidgets.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class VideoChatComponent extends StatelessWidget {
  ChatMessageModel data;
  String time;

  VideoChatComponent({required this.data, required this.time});

  @override
  Widget build(BuildContext context) {
    if (data.photoUrl.validate().isNotEmpty || data.photoUrl != null) {
      return Container(
        height: 250,
        width: 250,
        child: Stack(
          children: [
            cachedImage(data.photoUrl.validate(), height: 250, width: 250, fit: BoxFit.cover),
            Container(
              decoration: boxDecorationWithShadow(backgroundColor: Colors.black38, boxShape: BoxShape.circle, spreadRadius: 0, blurRadius: 0),
              child: IconButton(
                icon: Icon(Icons.play_arrow, color: Colors.white),
                onPressed: () {
                  FullScreenImageWidget(photoUrl: data.photoUrl, isFromChat: true, isVideo: true, name: data.messageType).launch(context);
                },
              ),
            ).center(),
            Positioned(
              bottom: 8,
              right: 8,
              child: Row(
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
            )
          ],
        ),
      );
    } else {
      return SizedBox(child: Loader(), height: 250, width: 250);
    }
  }
}
