import 'dart:io';

import 'package:chat/components/ChatItemWidget.dart';
import 'package:chat/components/ChatTopWidget.dart';
import 'package:chat/components/SelectedAttachmentComponent.dart';
import 'package:chat/main.dart';
import 'package:chat/models/ChatMessageModel.dart';
import 'package:chat/models/ChatRequestModel.dart';
import 'package:chat/models/ContactModel.dart';
import 'package:chat/models/FileModel.dart';
import 'package:chat/models/StickerModel.dart';
import 'package:chat/models/UserModel.dart';
import 'package:chat/screens/PickupLayout.dart';
import 'package:chat/services/ChatMessageService.dart';
import 'package:chat/utils/AppColors.dart';
import 'package:chat/utils/AppCommon.dart';
import 'package:chat/utils/AppConstants.dart';
import 'package:chat/utils/Appwidgets.dart';
import 'package:chat/utils/providers/ChatRequestProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:paginate_firestore/paginate_firestore.dart';

class ChatScreen extends StatefulWidget {
  final UserModel? receiverUser;

  ChatScreen(this.receiverUser);

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late ChatMessageService chatMessageService;
  String id = '';

  InterstitialAd? myInterstitial;

  TextEditingController messageCont = TextEditingController();
  FocusNode messageFocus = FocusNode();

  bool isFirstMsg = false;
  bool isBlocked = false;

  @override
  void initState() {
    super.initState();
    init();

    if (mAdShowCount < 5) {
      mAdShowCount++;
    } else {
      mAdShowCount = 0;
      buildInterstitialAd();
    }
  }

  InterstitialAd? buildInterstitialAd() {
    InterstitialAd.load(
        adUnitId: kReleaseMode ? mAdMobInterstitialId : InterstitialAd.testAdUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(onAdFailedToLoad: (LoadAdError error) {
          throw error.message;
        }, onAdLoaded: (InterstitialAd ad) {
          ad.show();
        }));
  }

  init() async {
    if (appStore.isDarkMode) {
      setStatusBarColor(scaffoldSecondaryDark, statusBarBrightness: Brightness.light, statusBarIconBrightness: Brightness.light);
    } else {
      setStatusBarColor(primaryColor);
    }

    WidgetsBinding.instance!.addObserver(this);
    oneSignal.disablePush(true);

    id = getStringAsync(userId);

    mChatFontSize = getIntAsync(FONT_SIZE_PREF, defaultValue: 16);
    mIsEnterKey = getBoolAsync(IS_ENTER_KEY, defaultValue: false);
    mSelectedImage = getStringAsync(SELECTED_WALLPAPER, defaultValue: "assets/default_wallpaper.png");

    chatMessageService = ChatMessageService();
    chatMessageService.setUnReadStatusToTrue(senderId: sender.uid!, receiverId: widget.receiverUser!.uid!);
    isBlocked = await userService.isUserBlocked(widget.receiverUser!.uid!);

    setState(() {});
  }

  void sendMessage({FilePickerResult? result, String? stickerPath}) async {
    if (isBlocked.validate(value: false)) {
      unblockDialog(context, receiver: widget.receiverUser!);
      return;
    }

    if (result == null && stickerPath.validate().isEmpty) {
      if (messageCont.text.trim().isEmpty) {
        messageFocus.requestFocus();
        return;
      }
    }

    ChatMessageModel data = ChatMessageModel();
    data.receiverId = widget.receiverUser!.uid;
    data.senderId = sender.uid;
    data.message = messageCont.text;
    data.isMessageRead = false;
    data.stickerPath = stickerPath;
    data.createdAt = DateTime.now().millisecondsSinceEpoch;

    if (result != null) {
      if (result.files.single.path.isImage) {
        data.messageType = MessageType.IMAGE.name;
      } else if (result.files.single.path.isVideo) {
        data.messageType = MessageType.VIDEO.name;
      } else if (result.files.single.path.isAudio) {
        data.messageType = MessageType.AUDIO.name;
      } else {
        data.messageType = MessageType.TEXT.name;
      }
    } else if (stickerPath.validate().isNotEmpty) {
      data.messageType = MessageType.STICKER.name;
    } else {
      data.messageType = MessageType.TEXT.name;
    }
    messageCont.clear();

    if (!widget.receiverUser!.blockedTo!.contains(userService.getUserReference(uid: getStringAsync(userId)))) {
      if (await chatRequestService.isRequestsUserExist(widget.receiverUser!.uid!)) {
        sendNormalMessages(data, result: result != null ? result : null);
      } else {
        sendChatRequest(data, result: result != null ? result : null);
      }
    } else {
      data.isMessageRead = true;
      chatMessageService.addMessage(data).then((value) {
        messageCont.clear();
      });
    }
  }

  void sendNormalMessages(ChatMessageModel data, {FilePickerResult? result}) async {
    if (isFirstMsg) {
      ContactModel data = ContactModel();
      data.uid = widget.receiverUser!.uid;
      data.addedOn = Timestamp.now();
      data.lastMessageTime = DateTime.now().millisecondsSinceEpoch;

      chatMessageService.getContactsDocument(of: getStringAsync(userId), forContact: widget.receiverUser!.uid).set(data.toJson()).then((value) {
        //
      }).catchError((e) {
        log(e);
      });
    }
    notificationService.sendPushNotifications(getStringAsync(userDisplayName), messageCont.text, receiverPlayerId: widget.receiverUser!.oneSignalPlayerId).catchError(log);
    messageCont.clear();
    setState(() {});

    await chatMessageService.addMessage(data).then((value) async {
      if (result != null) {
        FileModel fileModel = FileModel();
        fileModel.id = value.id;
        fileModel.file = File(result.files.single.path!);
        fileList.add(fileModel);

        setState(() {});
      }

      await chatMessageService.addMessageToDb(senderDoc: value, data: data, sender: sender, user: widget.receiverUser, image: result != null ? File(result.files.single.path!) : null, isRequest: false).then((value) {
        //
      });
    });

    userService.fireStore.collection(USER_COLLECTION).doc(getStringAsync(userId)).collection(CONTACT_COLLECTION).doc(widget.receiverUser!.uid).update({'lastMessageTime': DateTime.now().millisecondsSinceEpoch}).catchError((e) {
      log(e);
    });
    userService.fireStore.collection(USER_COLLECTION).doc(widget.receiverUser!.uid).collection(CONTACT_COLLECTION).doc(getStringAsync(userId)).update({'lastMessageTime': DateTime.now().millisecondsSinceEpoch}).catchError((e) {
      log(e);
    });
  }

  void sendChatRequest(ChatMessageModel data, {FilePickerResult? result}) async {
    if (!widget.receiverUser!.oneSignalPlayerId.isEmptyOrNull) {
      notificationService.sendPushNotifications(getStringAsync(userDisplayName), messageCont.text, receiverPlayerId: widget.receiverUser!.oneSignalPlayerId).catchError(log);
    }
    messageCont.clear();

    ChatRequestModel chatReq = ChatRequestModel();
    chatReq.uid = data.senderId;
    chatReq.userName = "";
    chatReq.profilePic = "";
    chatReq.requestStatus = RequestStatus.Pending.index;
    chatReq.senderIdRef = userService.ref!.doc(sender.uid);
    chatReq.createdAt = DateTime.now().millisecondsSinceEpoch;
    chatReq.updatedAt = DateTime.now().millisecondsSinceEpoch;

    if (await chatRequestService.isRequestUserExist(sender.uid!, widget.receiverUser!.uid.validate())) {
      chatMessageService.addMessage(data).then((value) async {
        if (result != null) {
          FileModel fileModel = FileModel();
          fileModel.id = value.id;
          fileModel.file = File(result.files.single.path!);
          fileList.add(fileModel);

          setState(() {});
        }

        await chatMessageService.addMessageToDb(senderDoc: value, data: data, sender: sender, user: widget.receiverUser, image: result != null ? File(result.files.single.path!) : null, isRequest: true).then((value) {
          //
        });
      });
    } else {
      chatRequestService.addChatWithCustomId(sender.uid!, chatReq.toJson(), widget.receiverUser!.uid.validate()).then((value) {
        // toast("Chat requested to ${widget.user!.name.validate()}");
      }).catchError((e) {
        //
      });
      chatMessageService.addMessage(data).then((value) async {
        if (result != null) {
          FileModel fileModel = FileModel();
          fileModel.id = value.id;
          fileModel.file = File(result.files.single.path!);
          fileList.add(fileModel);

          setState(() {});
        }

        await chatMessageService.addMessageToDb(senderDoc: value, data: data, sender: sender, user: widget.receiverUser, image: result != null ? File(result.files.single.path!) : null, isRequest: true).then((value) {
          //
        });
        userService.fireStore.collection(USER_COLLECTION).doc(getStringAsync(userId)).collection(CONTACT_COLLECTION).doc(widget.receiverUser!.uid).update({'lastMessageTime': DateTime.now().millisecondsSinceEpoch}).catchError((e) {
          log(e);
        });
      });
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached) {
      oneSignal.disablePush(false);
    }

    if (state == AppLifecycleState.paused) {
      oneSignal.disablePush(false);
    }
    if (state == AppLifecycleState.resumed) {
      oneSignal.disablePush(true);
    }
  }

  @override
  void dispose() async {
    myInterstitial?.show();
    if (appStore.isDarkMode) {
      setStatusBarColor(scaffoldSecondaryDark, statusBarBrightness: Brightness.light, statusBarIconBrightness: Brightness.light);
    } else {
      setStatusBarColor(primaryColor);
    }
    oneSignal.disablePush(false);
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  Widget getRequestedWidget(bool isRequested) {
    if (isRequested) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          decoration: BoxDecoration(
            color: context.primaryColor,
            borderRadius: radiusOnly(
              topLeft: defaultRadius,
              topRight: defaultRadius,
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Message Request', style: boldTextStyle(color: Colors.white)),
              8.height,
              Text('if you accept the invite, ${widget.receiverUser!.name.validate()} can message you.', style: primaryTextStyle(color: Colors.white70)),
              16.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: "Cancel",
                    color: context.primaryColor,
                    shapeBorder: OutlineInputBorder(borderRadius: radius(), borderSide: BorderSide(color: Colors.white)),
                    onTap: () {
                      chatRequestService.removeDocument(widget.receiverUser!.uid.validate()).then((value) {
                        chatMessageService.deleteChat(senderId: getStringAsync(userId), receiverId: widget.receiverUser!.uid.validate()).then((value) {
                          finish(context);
                          finish(context);
                        }).catchError((e) {
                          log(e.toString());
                        });
                      }).catchError(
                        (e) {
                          log(e.toString());
                        },
                      );
                    },
                  ),
                  16.width,
                  AppButton(
                    text: "Accept",
                    textStyle: boldTextStyle(),
                    shapeBorder: OutlineInputBorder(borderRadius: radius(), borderSide: BorderSide(color: Colors.white)),
                    onTap: () async {
                      ContactModel data = ContactModel();
                      data.uid = widget.receiverUser!.uid;
                      data.addedOn = Timestamp.now();
                      data.lastMessageTime = DateTime.now().millisecondsSinceEpoch;

                      chatMessageService.getContactsDocument(of: getStringAsync(userId), forContact: widget.receiverUser!.uid).set(data.toJson()).then((value) {
                        finish(context);
                        finish(context);
                        toast("Invitation Accepted");
                      }).catchError((e) {
                        log(e);
                      });

                      chatRequestService.updateDocument({"requestStatus": RequestStatus.Accepted.index}, widget.receiverUser!.uid).then((value) => null).catchError(
                            (e) {
                              log(e.toString());
                            },
                          );
                    },
                  ),
                  8.width,
                ],
              )
            ],
          ),
        ),
      );
    }
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          Container(
            decoration: boxDecorationWithShadow(borderRadius: BorderRadius.circular(30), spreadRadius: 0, blurRadius: 0, backgroundColor: context.cardColor),
            padding: EdgeInsets.only(left: 0, right: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(LineIcons.smiling_face_with_heart_eyes),
                  iconSize: 24.0,
                  padding: EdgeInsets.all(2),
                  color: Colors.grey,
                  onPressed: () {
                    if (isBlocked) {
                      unblockDialog(context, receiver: widget.receiverUser!);
                      return;
                    }

                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return SingleChildScrollView(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            runSpacing: 16,
                            children: StickerModel().stickerList().map((e) {
                              return cachedImage(e.path, height: 110, width: 110, fit: BoxFit.cover).paddingAll(8).onTap(() {
                                hideKeyboard(context);
                                sendMessage(stickerPath: e.path);

                                finish(context);
                              });
                            }).toList(),
                          ),
                        );
                      },
                    );
                  },
                ),
                AppTextField(
                  controller: messageCont,
                  textFieldType: TextFieldType.OTHER,
                  cursorColor: appStore.isDarkMode ? Colors.white : Colors.black,
                  focus: messageFocus,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: mIsEnterKey ? TextInputAction.send : TextInputAction.newline,
                  onFieldSubmitted: (p0) {
                    sendMessage();
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Message',
                    hintStyle: secondaryTextStyle(size: 16),
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                  ),
                ).expand(),
                IconButton(
                  visualDensity: VisualDensity(horizontal: 0, vertical: 1),
                  icon: Icon(Icons.attach_file),
                  iconSize: 25.0,
                  padding: EdgeInsets.all(2),
                  color: Colors.grey,
                  onPressed: () {
                    if (isBlocked.validate(value: false)) {
                      unblockDialog(context, receiver: widget.receiverUser!);
                      return;
                    }
                    _showAttachmentDialog();

                    hideKeyboard(context);
                  },
                ),
              ],
            ),
            width: context.width(),
          ).expand(),
          8.width,
          GestureDetector(
            onTap: () {
              sendMessage();
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white, size: 22),
                onPressed: null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _showAttachmentDialog() {
    return showDialog(
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: EdgeInsets.only(top: 16, bottom: 16, left: 12, right: 12),
            margin: EdgeInsets.only(bottom: 86, left: 12, right: 12),
            decoration: BoxDecoration(
              color: context.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Material(
              color: context.scaffoldBackgroundColor,
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  Container(
                    width: context.width() / 3 - 32,
                    color: context.scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        CircleAvatar(child: Icon(Icons.panorama, size: 30, color: Colors.white), backgroundColor: Colors.purple, radius: 30),
                        8.height,
                        Text("Gallery", style: boldTextStyle()),
                      ],
                    ),
                  ).onTap(() async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                    if (result != null) {
                      File file = File(result.files.single.path!);
                      finish(context);
                      bool res = await (SelectedAttachmentComponent(file: file, userModel: widget.receiverUser).launch(context));
                      if (res) {
                        sendMessage(result: result);
                      }
                    } else {
                      // User canceled the picker
                    }
                  }),
                  Container(
                    width: context.width() / 3 - 32,
                    color: context.scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        CircleAvatar(child: Icon(Icons.videocam, size: 30, color: Colors.white), backgroundColor: Colors.pink[800], radius: 30),
                        8.height,
                        Text("Video", style: boldTextStyle()),
                      ],
                    ),
                  ).onTap(() async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
                    if (result != null) {
                      File file = File(result.files.single.path!);
                      finish(context);
                      bool res = await (SelectedAttachmentComponent(file: file, userModel: widget.receiverUser, isVideo: true).launch(context));
                      if (res) {
                        sendMessage(result: result);
                      }
                    } else {
                      // User canceled the picker
                    }
                  }),
                  Container(
                    width: context.width() / 3 - 32,
                    color: context.scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        CircleAvatar(child: Icon(Icons.videocam, size: 30, color: Colors.white), backgroundColor: Colors.green[800], radius: 30),
                        8.height,
                        Text("Audio", style: boldTextStyle()),
                      ],
                    ),
                  ).onTap(() async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
                    if (result != null) {
                      File file = File(result.files.single.path!);
                      finish(context);
                      bool res = await (SelectedAttachmentComponent(file: file, userModel: widget.receiverUser, isAudio: true).launch(context));
                      if (res) {
                        sendMessage(result: result);
                      }
                    } else {
                      // User canceled the picker
                    }
                  }),
                  Container(
                    width: context.width() / 3 - 32,
                    color: context.scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        CircleAvatar(child: Icon(Icons.location_on, size: 30, color: Colors.white), backgroundColor: Colors.green[700], radius: 30),
                        8.height,
                        Text("Location", style: boldTextStyle()),
                      ],
                    ),
                  ).onTap(
                    () async {
                      //TODO
                      toast(COMING_SOON);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget buildChatRequestWidget(AsyncSnapshot<bool> snap) {
      if (snap.hasData) {
        return getRequestedWidget(snap.data!);
      } else if (snap.hasError) {
        return getRequestedWidget(false);
      } else {
        return getRequestedWidget(false);
      }
    }

    return PickupLayout(
      child: SafeArea(
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size(context.width(), kToolbarHeight),
            child: ChatAppBarWidget(receiverUser: widget.receiverUser!),
          ),
          body: Container(
            child: FutureBuilder<bool>(
              future: chatRequestService.isRequestsUserExist(widget.receiverUser!.uid!),
              builder: (context, snap) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: Image.asset(mSelectedImage).image,
                          fit: BoxFit.cover,
                          colorFilter: appStore.isDarkMode ? ColorFilter.mode(Colors.black54, BlendMode.luminosity) : null,
                        ),
                      ),
                    ),
                    PaginateFirestore(
                      reverse: true,
                      isLive: true,
                      padding: EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 0),
                      physics: BouncingScrollPhysics(),
                      query: chatMessageService.chatMessagesWithPagination(currentUserId: getStringAsync(userId), receiverUserId: widget.receiverUser!.uid!),
                      itemsPerPage: PER_PAGE_CHAT_COUNT,
                      shrinkWrap: true,
                      onLoaded: (page) {
                        isFirstMsg = page.documentSnapshots.isEmpty;
                      },
                      emptyDisplay: Offstage(),
                      itemBuilderType: PaginateBuilderType.listView,
                      itemBuilder: (index, context, snap) {
                        ChatMessageModel data = ChatMessageModel.fromJson(snap.data() as Map<String, dynamic>);

                        data.isMe = data.senderId == id;

                        return ChatItemWidget(data: data);
                      },
                    ).paddingBottom(snap.hasData ? (snap.data! ? 176 : 76) : 76),
                    buildChatRequestWidget(snap),
                    if (isBlocked)
                      Positioned(
                        top: 16,
                        left: 56,
                        right: 56,
                        child: Container(
                          decoration: boxDecorationDefault(color: Colors.red.shade100),
                          child: TextButton(
                            onPressed: () {
                              unblockDialog(context, receiver: widget.receiverUser!);
                            },
                            child: Text('You Blocked this contact. Tap to Unblock.', style: secondaryTextStyle(color: Colors.red)),
                          ),
                        ),
                      )
                  ],
                );
              },
            ),
          ).onTap(
            () {
              hideKeyboard(context);
            },
          ),
        ),
      ),
    );
  }
}
