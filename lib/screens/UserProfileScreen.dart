import 'package:chat/components/Permissions.dart';
import 'package:chat/main.dart';
import 'package:chat/models/UserModel.dart';
import 'package:chat/utils/AppColors.dart';
import 'package:chat/utils/AppCommon.dart';
import 'package:chat/utils/AppConstants.dart';
import 'package:chat/utils/Appwidgets.dart';
import 'package:chat/utils/CallFunctions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class UserProfileScreen extends StatefulWidget {
  final String uid;

  UserProfileScreen({required this.uid});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late UserModel currentUser;
  bool isBlocked = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    isBlocked = await userService.userByEmail(getStringAsync(userEmail)).then((value) => value.blockedTo!.contains(userService.ref!.doc(widget.uid)));
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget buildImageIconWidget() {
      if (currentUser.photoUrl!.isNotEmpty) {
        return cachedImage(currentUser.photoUrl, fit: BoxFit.cover);
      }
      return Container(
        decoration: BoxDecoration(color: primaryColor),
        padding: EdgeInsets.all(16),
        child: Text(currentUser.name!.length >= 1 ? currentUser.name![0] : 'M', style: boldTextStyle(color: Colors.white, size: 32)).center(),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: StreamBuilder<UserModel>(
          stream: userService.singleUser(widget.uid),
          builder: (context, snap) {
            if (snap.hasData) {
              currentUser = snap.data!;
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 350.0,
                    backgroundColor: primaryColor,
                    floating: true,
                    pinned: true,
                    snap: false,
                    stretch: true,
                    stretchTriggerOffset: 120.0,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      stretchModes: [StretchMode.zoomBackground],
                      titlePadding: EdgeInsetsDirectional.only(start: 50.0, bottom: 20.0),
                      title: Text("${currentUser.name}", style: boldTextStyle(color: Colors.white)),
                      background: buildImageIconWidget(),
                    ),
                  ),
                  SliverFillRemaining(
                    child: Column(
                      children: [
                        _itemAboutPhone(),
                        _buildBlockMSG(),
                        16.height,
                        _buildReport(),
                      ],
                    ),
                  )
                ],
              );
            }
            return snapWidgetHelper(snap);
          },
        ),
      ),
    );
  }

  Widget _itemAboutPhone() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: context.width(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AboutAndPhoneNumber'.translate, style: secondaryTextStyle()),
          8.height,
          SettingItemWidget(
            title: currentUser.userStatus.validate(),
            titleTextStyle: primaryTextStyle(),
            padding: EdgeInsets.all(0),
            subTitle: currentUser.updatedAt!.toDate().timeAgo,
          ),
          Divider(),
          SettingItemWidget(
            title: currentUser.phoneNumber.validate(),
            titleTextStyle: primaryTextStyle(),
            padding: EdgeInsets.all(0),
            subTitle: "mobile".translate,
            trailing: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.message, color: secondaryColor),
                  onPressed: () {
                    finish(context);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.call, color: secondaryColor),
                  onPressed: () async {
                    if (await userService.isUserBlocked(currentUser.uid.validate())) {
                      unblockDialog(context, receiver: currentUser);
                      return;
                    }
                    return await Permissions.cameraAndMicrophonePermissionsGranted()
                        ? CallFunctions.voiceDial(
                            context: context,
                            from: sender,
                            to: currentUser,
                          )
                        : {};
                  },
                ),
                IconButton(
                  icon: Icon(Icons.videocam, color: secondaryColor),
                  onPressed: () async {
                    if (await userService.isUserBlocked(currentUser.uid.validate())) {
                      unblockDialog(context, receiver: currentUser);
                      return;
                    }
                    return await Permissions.cameraAndMicrophonePermissionsGranted()
                        ? CallFunctions.dial(
                            context: context,
                            from: sender,
                            to: currentUser,
                          )
                        : {};
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void blockMessage() async {
    List<DocumentReference> temp = [];
    await userService.userByEmail(getStringAsync(userEmail)).then((value) {
      temp = value.blockedTo!;
    });
    if (!temp.contains(userService.ref!.doc(widget.uid))) {
      temp.add(userService.getUserReference(uid: currentUser.uid.validate()));
    }

    userService.blockUser({"blockedTo": temp}).then((value) {
      finish(context);
      finish(context);
      finish(context);
    }).catchError((e) {
      //
    });
  }

  Widget _buildBlockMSG() {
    return SettingItemWidget(
      decoration: BoxDecoration(color: Colors.white),
      title: isBlocked ? "${"Unblock".translate}" : "${"block".translate}",
      leading: Icon(Icons.block, color: Colors.red[800]),
      titleTextStyle: primaryTextStyle(color: Colors.red[800]),
      onTap: () {
        if (isBlocked) {
          unblockDialog(context, receiver: currentUser);
        } else {
          showInDialog(
            context,
            dialogAnimation: DialogAnimation.SCALE,
            title: Text(
              "${"block".translate}" + " ${currentUser.name.validate()}? " + "blocked_contact_will_no_longer_be_able_to_call_you_or_send_you_message".translate,
              style: boldTextStyle(),
              textAlign: TextAlign.justify,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  finish(context);
                },
                child: Text(
                  "cancel".translate,
                  style: TextStyle(color: secondaryColor),
                ),
              ),
              TextButton(
                  onPressed: () async {
                    blockMessage();
                  },
                  child: Text("block".translate.toUpperCase(), style: TextStyle(color: secondaryColor))),
            ],
          );
        }
      },
    );
  }

  void reportBy() async {
    List<DocumentReference> temp = [];
    temp = await userService.userByEmail(currentUser.email).then((value) => value.reportedBy!);
    if (!temp.contains(userService.ref!.doc(getStringAsync(userId)))) {
      temp.add(userService.getUserReference(uid: getStringAsync(userId)));
    }

    if (temp.length >= appSettingStore.mReportCount) {
      userService.reportUser({"isActive": false}, currentUser.uid.validate()).then((value) {
        finish(context);
        finish(context);
        finish(context);
        toast("${"UserAccountIsDeactivatedByAdminToRestorePleaseContactAdmin".translate}");
        toast(value.toString());
      }).catchError((e) {
        //
      });
    } else {
      userService.reportUser({"reportedBy": temp}, currentUser.uid.validate()).then((value) {
        finish(context);
        finish(context);
        finish(context);
        toast(value.toString());
      }).catchError((e) {
        //
      });
    }
  }

  Widget _buildReport() {
    return SettingItemWidget(
      title: "report_contact".translate,
      decoration: BoxDecoration(color: Colors.white),
      leading: Icon(Icons.thumb_down, color: Colors.red[800]),
      titleTextStyle: primaryTextStyle(color: Colors.red[800]),
      onTap: () {
        showInDialog(
          context,
          dialogAnimation: DialogAnimation.SCALE,
          title: Text("${"report".translate} ${currentUser.name.validate()} ?", style: boldTextStyle()),
          actions: [
            TextButton(
              onPressed: () {
                finish(context);
              },
              child: Text(
                "cancel".translate,
                style: TextStyle(color: secondaryColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                reportBy();
              },
              child: Text(
                "report".translate.toUpperCase(),
                style: TextStyle(color: secondaryColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
