import 'package:chat/components/Permissions.dart';
import 'package:chat/main.dart';
import 'package:chat/models/UserModel.dart';
import 'package:chat/screens/UserProfileScreen.dart';
import 'package:chat/utils/AppColors.dart';
import 'package:chat/utils/AppCommon.dart';
import 'package:chat/utils/AppConstants.dart';
import 'package:chat/utils/CallFunctions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

class ChatAppBarWidget extends StatefulWidget {
  final UserModel? receiverUser;

  ChatAppBarWidget({required this.receiverUser});

  @override
  ChatAppBarWidgetState createState() => ChatAppBarWidgetState();
}

class ChatAppBarWidgetState extends State<ChatAppBarWidget> {
  bool isRequestAccept = false;
  bool isBlocked = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    isBlocked = await userService.userByEmail(getStringAsync(userEmail)).then((value) => value.blockedTo!.contains(userService.ref!.doc(widget.receiverUser!.uid)));

    await chatRequestService.isRequestsUserExist(widget.receiverUser!.uid!).then((value) {
      isRequestAccept = !value;
      setState(() {});
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    String getTime(int val) {
      String? time;
      DateTime date = DateTime.fromMicrosecondsSinceEpoch(val * 1000);
      if (date.day == DateTime.now().day) {
        time = "at ${DateFormat('hh:mm a').format(date)}";
      } else {
        time = date.timeAgo;
      }
      return time;
    }

    return AppBar(
      automaticallyImplyLeading: false,
      title: StreamBuilder<UserModel>(
        stream: userService.singleUser(widget.receiverUser!.uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Container();
          }
          if (snap.hasData) {
            UserModel data = snap.data!;

            return Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_back, color: whiteColor),
                    4.width,
                    data.photoUrl!.isEmpty
                        ? Hero(tag: data.uid.validate(), child: Image.asset("assets/app_icon.png", height: 35, width: 35, fit: BoxFit.cover).cornerRadiusWithClipRRect(50))
                        : Hero(tag: data.uid!, child: Image.network(data.photoUrl.validate(), height: 35, width: 35, fit: BoxFit.cover).cornerRadiusWithClipRRect(50)),
                  ],
                ).paddingSymmetric(vertical: 16).onTap(() => finish(context)),
                10.width,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.name!, style: TextStyle(color: whiteColor)),
                    data.isPresence! ? Text('Online', style: secondaryTextStyle(color: Colors.white70)) : Text("Last seen ${getTime(data.lastSeen!.validate())}", style: secondaryTextStyle(color: Colors.white70)),
                  ],
                ).paddingSymmetric(vertical: 16).onTap(
                  () {
                    UserProfileScreen(uid: data.uid.validate()).launch(context, pageRouteAnimation: PageRouteAnimation.Scale, duration: 300.milliseconds);
                  },
                ).expand(),
              ],
            );
          }

          return snapWidgetHelper(snap, loadingWidget: Container());
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.video_call),
          onPressed: isRequestAccept
              ? () async {
                  if (isBlocked) {
                    unblockDialog(context, receiver: widget.receiverUser!);
                    return;
                  }
                  return await Permissions.cameraAndMicrophonePermissionsGranted() ? CallFunctions.dial(context: context, from: sender, to: widget.receiverUser!) : {};
                }
              : null,
        ),
        IconButton(
          icon: Icon(Icons.call),
          onPressed: isRequestAccept
              ? () async {
                  if (isBlocked) {
                    unblockDialog(context, receiver: widget.receiverUser!);
                    return;
                  }
                  return await Permissions.cameraAndMicrophonePermissionsGranted() ? CallFunctions.voiceDial(context: context, from: sender, to: widget.receiverUser!) : {};
                }
              : null,
        ),
        PopupMenuButton(
          padding: EdgeInsets.zero,
          offset: Offset(10, -50),
          icon: Icon(Icons.more_vert),
          color: context.cardColor,
          onSelected: (dynamic value) async {
            if (value == 1) {
              UserProfileScreen(uid: widget.receiverUser!.uid.validate()).launch(context, pageRouteAnimation: PageRouteAnimation.Scale, duration: 300.milliseconds);
            } else if (value == 2) {
              showInDialog(
                context,
                dialogAnimation: DialogAnimation.SCALE,
                title: Text("Report ${widget.receiverUser!.name.validate()} ?", style: boldTextStyle()),
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
                      child: Text("report".translate.toUpperCase(), style: TextStyle(color: secondaryColor))),
                ],
              );
            } else if (value == 3) {
              if (isBlocked) {
                unblockDialog(context, receiver: widget.receiverUser!);
              } else {
                showInDialog(
                  context,
                  dialogAnimation: DialogAnimation.SCALE,
                  title: Text(
                    "Block" + " ${widget.receiverUser!.name.validate()}? " + "blocked_contact_will_no_longer_be_able_to_call_you_or_send_you_message".translate,
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
            } else if (value == 4) {
              bool? res = await showConfirmDialog(context, "clear_chats".translate, buttonColor: secondaryColor);
              if (res ?? false) {
                chatMessageService.clearAllMessages(senderId: sender.uid, receiverId: widget.receiverUser!.uid!).then((value) {
                  toast("chat_clear".translate);
                  hideKeyboard(context);
                }).catchError((e) {
                  toast(e);
                });
              }
            }
          },
          itemBuilder: (context) {
            List<PopupMenuItem> list = [];
            list.add(PopupMenuItem(value: 1, child: Text('view_Contact'.translate, style: primaryTextStyle())));
            list.add(PopupMenuItem(value: 2, child: Text('report'.translate, style: primaryTextStyle())));
            list.add(PopupMenuItem(value: 3, child: Text(isBlocked ? 'Unblock' : 'block'.translate, style: primaryTextStyle())));
            list.add(PopupMenuItem(value: 4, child: Text('clear_Chat'.translate, style: primaryTextStyle())));
            if (isRequestAccept) {
              return list;
            } else {
              return <PopupMenuItem>[];
            }
          },
        ),
      ],
      backgroundColor: context.primaryColor,
    );
  }

  void blockMessage() async {
    List<DocumentReference> temp = [];
    await userService.userByEmail(getStringAsync(userEmail)).then((value) {
      temp = value.blockedTo!;
    });
    if (!temp.contains(userService.ref!.doc(widget.receiverUser!.uid))) {
      temp.add(userService.getUserReference(uid: widget.receiverUser!.uid.validate()));
    }

    userService.blockUser({"blockedTo": temp}).then((value) {
      finish(context);
      finish(context);
      finish(context);
    }).catchError((e) {
      //
    });
  }

  void reportBy() async {
    List<DocumentReference> temp = [];
    temp = await userService.userByEmail(widget.receiverUser!.email).then((value) => value.reportedBy!);

    if (!temp.contains(userService.ref!.doc(getStringAsync(userId)))) {
      temp.add(userService.getUserReference(uid: getStringAsync(userId)));
    }

    if (temp.length >= appSettingStore.mReportCount) {
      userService.reportUser({"isActive": false}, widget.receiverUser!.uid.validate()).then((value) {
        finish(context);
        finish(context);
        finish(context);
        toast("User account is deactivated by Admin, to restore please contact admin");
        toast(value.toString());
      }).catchError((e) {
        //
      });
    } else {
      userService.reportUser({"reportedBy": temp}, widget.receiverUser!.uid.validate()).then((value) {
        finish(context);
        finish(context);
        finish(context);
        toast(value.toString());
      }).catchError((e) {
        //
      });
    }
  }
}
