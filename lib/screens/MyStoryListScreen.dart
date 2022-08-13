import 'package:chat/models/StoryModel.dart';
import 'package:chat/utils/AppColors.dart';
import 'package:chat/utils/AppCommon.dart';
import 'package:chat/utils/Appwidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';

class MyStoryListScreen extends StatefulWidget {
  final List<StoryModel>? list;

  MyStoryListScreen({this.list});

  @override
  MyStoryListScreenState createState() => MyStoryListScreenState();
}

class MyStoryListScreenState extends State<MyStoryListScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    //
  }

  Future<void> deletePost({String? id, String? url}) async {
    appStore.setLoading(true);
    await storyService.deleteStory(id: id, url: url!).then((value) {
      appStore.setLoading(false);

      toast('remove_successfully'.translate);
      finish(context);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('my_status'.translate, textColor: Colors.white),
      body: Stack(
        children: [
          ListView.builder(
              itemCount: widget.list!.length,
              shrinkWrap: true,
              padding: EdgeInsets.all(8),
              itemBuilder: (_, i) {
                StoryModel data = widget.list![i];

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
                      child: cachedImage(data.imagePath.validate(), fit: BoxFit.cover).cornerRadiusWithClipRRect(50),
                    ),
                    16.width,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('my_status'.translate, style: boldTextStyle(size: 18)),
                        Text(formatTime(data.createAt!.millisecondsSinceEpoch.validate()), style: secondaryTextStyle()),
                      ],
                    ).expand(),
                    PopupMenuButton<int>(
                      itemBuilder: (context) {
                        return <PopupMenuEntry<int>>[
                          PopupMenuItem(child: Text('delete'.translate), value: 0),
                        ];
                      },
                      onSelected: (v) async {
                        if (v == 0) {
                          showConfirmDialogCustom(context, title: 'remove_story_confirmation'.translate, positiveText: 'lbl_yes'.translate, negativeText: 'lbl_no'.translate, onAccept: (v) {
                            deletePost(id: data.id, url: data.imagePath);
                          });
                        }
                      },
                    ),
                  ],
                );
              }),
          Observer(builder: (_) => Loader().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
