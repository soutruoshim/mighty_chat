import 'dart:io';

import 'package:chat/components/SelectedAttachmentComponent.dart';
import 'package:chat/components/StoryListWidget.dart';
import 'package:chat/main.dart';
import 'package:chat/models/StoryModel.dart';
import 'package:chat/screens/StoryListScreen.dart';
import 'package:chat/utils/AppColors.dart';
import 'package:chat/utils/AppCommon.dart';
import 'package:chat/utils/AppConstants.dart';
import 'package:chat/utils/Appwidgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import 'MyStoryListScreen.dart';

class StoriesScreen extends StatefulWidget {
  @override
  StoriesScreenState createState() => StoriesScreenState();
}

class StoriesScreenState extends State<StoriesScreen> {
  List<RecentStoryModel> recentStoryList = [];
  List<RecentStoryModel> recentList = [];

  List<StoryModel> myStoryList = [];

  DateTime currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    //
  }

  Future<File> selectImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    return File(result!.files.single.path!);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    Widget myStatusWidget({List<StoryModel>? data}) {
      return Stack(
        children: [
          Row(
            children: [
              Container(
                height: 70,
                width: 70,
                margin: EdgeInsets.only(top: 4, bottom: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: primaryColor, width: 2),
                  borderRadius: radius(50),
                ),
                child: cachedImage(data!.isNotEmpty ? data.first.imagePath.validate() : '', fit: BoxFit.cover).cornerRadiusWithClipRRect(50),
              ),
              16.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('my_status'.translate, style: boldTextStyle(size: 18)),
                  Text(data.isEmpty ? 'Add Story' : formatTime(data.first.createAt!.millisecondsSinceEpoch.validate()), style: secondaryTextStyle()),
                ],
              ).expand(),
              if (data.isNotEmpty)
                IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () {
                      MyStoryListScreen(list: data).launch(context);
                    }),
            ],
          ).paddingAll(16).onTap(() async {
            if (data.isNotEmpty) {
              StoryListScreen(list: data, userName: data.first.userName, time: data.first.createAt, userImg: data.first.userImgPath).launch(context);
            } else {
              File? file = await selectImages();
              SelectedAttachmentComponent(file: file, isStory: true).launch(context);
            }
          }),
        ],
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: context.height(),
          width: context.width(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<List<StoryModel>>(
                  future: storyService.getMyStory(uid: getStringAsync(userId)),
                  builder: (_, snap) {
                    myStoryList.clear();

                    if (snap.hasData) {
                      snap.data!.forEach((e) {
                        if (e.createAt!.toDate().difference(currentDate).inDays == 0) {
                          myStoryList.add(e);
                        }
                      });

                      return myStatusWidget(data: myStoryList);
                    }
                    return SizedBox();
                  }),
              16.height,
              FutureBuilder<List<StoryModel>>(
                future: storyService.getAllStory(uid: getStringAsync(userId)),
                builder: (_, snap) {
                  if (snap.hasError) return Text(snap.error.toString(), style: boldTextStyle()).center();
                  if (snap.hasData) {
                    // snap.data!.removeWhere((element) => element.createAt!.toDate().isToday);
                    if (snap.data!.isNotEmpty) {
                      recentStoryList.clear();

                      snap.data!.forEach(
                        (element) async {
                          RecentStoryModel data = RecentStoryModel();
                          data.userId = element.userId;
                          data.userName = element.userName;
                          data.userImgPath = element.userImgPath;
                          data.createAt = element.createAt;
                          data.updatedAt = element.updatedAt;
                          data.list = [];

                          if (data.createAt!.toDate().difference(currentDate).inDays == 0) {
                            if (recentStoryList.length > 0) {
                              final index = recentStoryList.indexWhere((e) => e.userId == element.userId);
                              if (index > -1) {
                                recentStoryList[index].list?.add(element);
                              } else {
                                data.list!.add(element);
                                recentStoryList.add(data);
                              }
                            } else {
                              data.list!.add(element);
                              recentStoryList.add(data);
                            }
                          } else {
                            await storyService.removeDocument(element.id!);
                            await storyService.deleteStory(id: element.id!, url: element.imagePath);
                          }
                        },
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('recent_stories'.translate, style: secondaryTextStyle()).paddingSymmetric(horizontal: 16),
                          16.height,
                          StoryListWidget(recentStoryList).visible(recentStoryList.isNotEmpty),
                          NoChatWidget().center().expand().visible(recentStoryList.isEmpty),
                        ],
                      );
                    } else {
                      return NoChatWidget().visible(recentStoryList.isEmpty);
                    }
                  }
                  return snapWidgetHelper(snap);
                },
              ).expand(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt_outlined, color: Colors.white),
        onPressed: () async {
          File? file = await selectImages();
          bool res = await (SelectedAttachmentComponent(file: file, isStory: true).launch(context));
          if (res) {
            //
          }
        },
      ),
    );
  }
}
