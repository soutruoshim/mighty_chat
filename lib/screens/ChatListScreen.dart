import 'package:chat/components/ChatOptionDialog.dart';
import 'package:chat/components/LastMessageContainer.dart';
import 'package:chat/components/UserProfileImageDialog.dart';
import 'package:chat/main.dart';
import 'package:chat/models/ContactModel.dart';
import 'package:chat/models/UserModel.dart';
import 'package:chat/screens/ChatRequestScreen/ChatRequestScreen.dart';
import 'package:chat/screens/DashboardScreen.dart';
import 'package:chat/screens/NewChatScreen.dart';
import 'package:chat/screens/PickupLayout.dart';
import 'package:chat/utils/AppColors.dart';
import 'package:chat/utils/AppCommon.dart';
import 'package:chat/utils/AppConstants.dart';
import 'package:chat/utils/Appwidgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import 'ChatScreen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  ChatListScreenState createState() => ChatListScreenState();
}

class ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver {
  String id = '';

  bool autoFocus = false;

  String searchCont = "";

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    if (appStore.isDarkMode) {
      setStatusBarColor(scaffoldSecondaryDark, statusBarBrightness: Brightness.light, statusBarIconBrightness: Brightness.light);
    } else {
      setStatusBarColor(primaryColor);
    }
    WidgetsBinding.instance!.addObserver(this);

    Map<String, dynamic> presenceStatusTrue = {
      'isPresence': true,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    };

    await userService.updateUserStatus(presenceStatusTrue, getStringAsync(userId));

    id = await getString(userId);

    setState(() {});

    LiveStream().on(SEARCH_KEY, (s) {
      searchCont = s as String;
      setState(() {});
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    Map<String, dynamic> presenceStatusFalse = {
      'isPresence': false,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    };
    if (state == AppLifecycleState.detached) {
      userService.updateUserStatus(presenceStatusFalse, getStringAsync(userId));
    }

    if (state == AppLifecycleState.paused) {
      userService.updateUserStatus(presenceStatusFalse, getStringAsync(userId));
    }
    if (state == AppLifecycleState.resumed) {
      Map<String, dynamic> presenceStatusTrue = {
        'isPresence': true,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      };

      userService.updateUserStatus(presenceStatusTrue, getStringAsync(userId));
    }
  }

  @override
  void dispose() {
    super.dispose();
    LiveStream().dispose(SEARCH_KEY);
    WidgetsBinding.instance!.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      child: Scaffold(
        body: SizedBox.expand(
          child: SingleChildScrollView(
            child: Column(
              children: [
                FutureBuilder<int>(
                  future: chatRequestService.getRequestLength(),
                  builder: (context, snap) {
                    if (snap.hasData) {
                      if (snap.data.validate() != 0) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.request_page, color: primaryColor, size: 28),
                            16.width,
                            Text('New Chat Request', style: primaryTextStyle()).expand(),
                            Text("${snap.data.validate()}", style: boldTextStyle()),
                          ],
                        ).paddingSymmetric(vertical: 16, horizontal: 16).onTap(() {
                          ChatRequestScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
                        });
                      } else {
                        return SizedBox();
                      }
                    }
                    return SizedBox();
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: chatMessageService.fetchContacts(userId: getStringAsync(userId)),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Text(snapshot.error.toString(), style: boldTextStyle()).center();
                    if (snapshot.hasData) {
                      messageRequestStore.addContactData(data: snapshot.data!.docs.map((e) => ContactModel.fromJson(e.data() as Map<String, dynamic>)).toList(), isClear: true);

                      if (snapshot.data!.docs.length == 0) {
                        return SizedBox(
                          child: NoChatWidget(),
                          height: context.height() - context.statusBarHeight - kToolbarHeight - 100,
                          width: context.width(),
                        );
                      } else {
                        return ListView.separated(
                          itemCount: snapshot.data!.docs.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            ContactModel contact = ContactModel.fromJson(snapshot.data!.docs[index].data() as Map<String, dynamic>);
                            return _buildChatItemWidget(contact: contact);
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return Divider(indent: 80, height: 0);
                          },
                        );
                      }
                    }
                    return snapWidgetHelper(snapshot);
                  },
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add, color: Colors.white),
          onPressed: () {
            isSearch = false;
            hideKeyboard(context);

            setState(() {});

            NewChatScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
          },
        ),
      ),
    );
  }

  StreamBuilder<List<UserModel>> _buildChatItemWidget({required ContactModel contact}) {
    return StreamBuilder(
      stream: chatMessageService.getUserDetailsById(id: contact.uid, searchText: searchCont),
      builder: (context, snap) {
        if (snap.hasData) {
          return ListView.builder(
            itemBuilder: (context, index) {
              UserModel data = snap.data![index];

              if (snap.data!.length == 0) {
                return NoChatWidget().center();
              }
              return InkWell(
                onTap: () async {
                  if (id != data.uid) {
                    hideKeyboard(context);
                    ChatScreen(data).launch(context);
                  }
                },
                onLongPress: () async {
                  await showInDialog(
                    context,
                    builder: (p0) {
                      return ChatOptionDialog(receiverUser: data);
                    },
                    contentPadding: EdgeInsets.zero,
                    dialogAnimation: DialogAnimation.SCALE,
                    title: Text("select_chat_option".translate, style: boldTextStyle(size: 20)).center(),
                  );
                  setState(() {});
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      data.photoUrl!.isEmpty
                          ? Container(
                              height: 50,
                              width: 50,
                              padding: EdgeInsets.all(10),
                              color: primaryColor,
                              child: Text(data.name.validate()[0].toUpperCase(), style: secondaryTextStyle(color: Colors.white)).center().fit(),
                            ).cornerRadiusWithClipRRect(50).onTap(() {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return UserProfileImageDialog(data: data);
                                },
                              );
                            })
                          : Hero(
                              tag: data.uid.validate(),
                              child: cachedImage(data.photoUrl.validate(), height: 50, width: 50, fit: BoxFit.cover).cornerRadiusWithClipRRect(50),
                            ).onTap(() {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return UserProfileImageDialog(data: data);
                                },
                              );
                            }),
                      10.width,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                data.name.validate().capitalizeFirstLetter(),
                                style: primaryTextStyle(size: 18),
                                maxLines: 1,
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.ellipsis,
                              ).expand(),
                              StreamBuilder<int>(
                                stream: chatMessageService.getUnReadCount(senderId: getStringAsync(userId), receiverId: contact.uid!),
                                builder: (context, snap) {
                                  if (snap.hasData) {
                                    if (snap.data != 0) {
                                      return Container(
                                        height: 18,
                                        width: 18,
                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: secondaryColor),
                                        child: Text(
                                          snap.data.validate().toString(),
                                          style: secondaryTextStyle(size: 12, color: Colors.white),
                                        ).fit().center(),
                                      );
                                    }
                                  }
                                  return Offstage();
                                },
                              ),
                            ],
                          ),
                          2.height,
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LastMessageContainer(
                                stream: chatMessageService.fetchLastMessageBetween(senderId: getStringAsync(userId), receiverId: contact.uid!),
                              ),
                            ],
                          ),
                        ],
                      ).expand(),
                    ],
                  ),
                ),
              );
            },
            itemCount: snap.data!.length,
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            dragStartBehavior: DragStartBehavior.start,
          );
        }
        return snapWidgetHelper(snap, loadingWidget: Offstage());
      },
    );
  }
}
