import 'package:chat/models/StoryModel.dart';
import 'package:chat/screens/StoryListScreen.dart';
import 'package:chat/utils/AppColors.dart';
import 'package:chat/utils/Appwidgets.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class StoryListWidget extends StatelessWidget {
  static String tag = '/StoryListWidget';
  final List<RecentStoryModel> list;

  StoryListWidget(this.list);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ListView.builder(
            itemCount: list.length,
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (_, i) {
              RecentStoryModel data = list[i];

              return Row(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    margin: EdgeInsets.only(top: 4, bottom: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryColor, width: 2),
                      borderRadius: radius(50),
                    ),
                    child: cachedImage(data.list!.first.imagePath.validate(), fit: BoxFit.cover).cornerRadiusWithClipRRect(50),
                  ),
                  16.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.userName.validate(), style: boldTextStyle(size: 18)),
                      Text(formatTime(data.createAt!.millisecondsSinceEpoch.validate()), style: secondaryTextStyle()),
                    ],
                  )
                ],
              ).paddingSymmetric(horizontal: 16, vertical: 4).onTap(() {
                StoryListScreen(list: data.list, userName: data.userName, time: data.createAt, userImg: data.userImgPath).launch(context);
              });
            }).visible(list.isNotEmpty),
      ],
    );
  }
}
