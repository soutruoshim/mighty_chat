import 'package:chat/components/FullScreenImageWidget.dart';
import 'package:chat/main.dart';
import 'package:chat/models/ChatMessageModel.dart';
import 'package:chat/utils/AppColors.dart';
import 'package:chat/utils/AppCommon.dart';
import 'package:chat/utils/AppConstants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:nb_utils/nb_utils.dart';

class StickerChatComponent extends StatelessWidget {
  ChatMessageModel data;
  String time;
  EdgeInsetsGeometry padding;

  StickerChatComponent({required this.data, required this.time, required this.padding});

  @override
  Widget build(BuildContext context) {
    if (data.stickerPath.validate().isNotEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        height: 150,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Image.asset(data.stickerPath.validate(), fit: BoxFit.cover, width: 110),
            Positioned(
              bottom: -5,
              right: 0,
              child: Container(
                margin: data.isMe.validate() ? EdgeInsets.only(top: 0.0, bottom: 0.0, left: isRTL ? 0 : context.width() * 0.25, right: 8) : EdgeInsets.only(top: 2.0, bottom: 2.0, left: 8, right: isRTL ? 0 : context.width() * 0.25),
                padding: padding,
                decoration: BoxDecoration(
                  boxShadow: appStore.isDarkMode ? null : defaultBoxShadow(),
                  color: data.isMe.validate() ? primaryColor : context.cardColor,
                  borderRadius: data.isMe.validate()
                      ? radiusOnly(bottomLeft: chatMsgRadius, topLeft: chatMsgRadius, bottomRight: chatMsgRadius, topRight: chatMsgRadius)
                      : radiusOnly(bottomLeft: chatMsgRadius, topLeft: chatMsgRadius, bottomRight: chatMsgRadius, topRight: chatMsgRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: primaryTextStyle(
                        color: !data.isMe.validate() ? Colors.blueGrey.withOpacity(0.6) : whiteColor.withOpacity(0.6),
                        size: 10,
                      ),
                    ),
                    2.width,
                    data.isMe!
                        ? !data.isMessageRead!
                            ? Icon(Icons.done, size: 12, color: Colors.white60)
                            : Icon(Icons.done_all, size: 12, color: Colors.white60)
                        : Offstage()
                  ],
                ),
              ),
            )
          ],
        ).onTap(() {
          FullScreenImageWidget(
            photoUrl: data.stickerPath,
            isFromChat: true,
            name: data.messageType,
          ).launch(context);
        }),
      );
    } else {
      return Container(
        child: Loader(),
        height: 120,
        width: 120,
      );
    }
  }
}
