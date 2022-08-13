import 'package:chat/components/UserProfileImageDialog.dart';
import 'package:chat/main.dart';
import 'package:chat/models/ChatRequestModel.dart';
import 'package:chat/models/UserModel.dart';
import 'package:chat/screens/ChatScreen.dart';
import 'package:chat/screens/PickupLayout.dart';
import 'package:chat/utils/AppColors.dart';
import 'package:chat/utils/Appwidgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ChatRequestScreen extends StatefulWidget {
  @override
  _ChatRequestScreenState createState() => _ChatRequestScreenState();
}

class _ChatRequestScreenState extends State<ChatRequestScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      child: Scaffold(
        appBar: appBarWidget("Chat Request", textColor: Colors.white),
        body: Stack(
          children: [
            StreamBuilder<List<ChatRequestModel>>(
                stream: chatRequestService.getChatRequestList(),
                builder: (context, snap) {
                  if (snap.hasData) {
                    if (snap.data!.length == 0) {
                      return NoChatWidget().center();
                    }
                    return ListView.builder(
                      itemCount: snap.data!.length,
                      padding: EdgeInsets.only(bottom: 60, top: 16),
                      itemBuilder: (context, index) {
                        ChatRequestModel data = snap.data![index];
                        return FutureBuilder<UserModel>(
                          future: getUser(data.senderIdRef!),
                          builder: (context, val) {
                            if (val.hasData) {
                              return SettingItemWidget(
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                leading: val.data!.photoUrl!.isEmpty
                                    ? Container(
                                        height: 50,
                                        width: 50,
                                        padding: EdgeInsets.all(10),
                                        color: primaryColor,
                                        child: Text(val.data!.name.validate()[1].toUpperCase(), style: secondaryTextStyle(color: Colors.white)).center().fit(),
                                      ).cornerRadiusWithClipRRect(50).onTap(() {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return UserProfileImageDialog(data: val.data);
                                          },
                                        );
                                      })
                                    : Hero(
                                        tag: val.data!.uid.validate(),
                                        child: cachedImage(val.data!.photoUrl.validate(), height: 50, width: 50, fit: BoxFit.cover).cornerRadiusWithClipRRect(50),
                                      ).onTap(() {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return UserProfileImageDialog(data: val.data);
                                          },
                                        );
                                      }),
                                title: val.data!.name.validate(),
                                // subTitle: data.createdAt!.toDate().timeAgo,
                                onTap: () async {
                                  ChatScreen(val.data!).launch(context);
                                },
                              );
                            }
                            return snapWidgetHelper(val, loadingWidget: Offstage());
                          },
                        );
                      },
                    );
                  }

                  return snapWidgetHelper(snap);
                }),
            NoChatWidget().center().visible(false),
          ],
        ),
      ),
    );
  }

  Future<UserModel> getUser(DocumentReference data) async {
    return await data.get().then((value) => UserModel.fromJson(value.data() as Map<String, dynamic>));
  }
}
