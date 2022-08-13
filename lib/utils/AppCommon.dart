import 'package:chat/main.dart';
import 'package:chat/models/UserModel.dart';
import 'package:chat/utils/AppColors.dart';
import 'package:chat/utils/AppConstants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

Color getPrimaryColor() => appStore.isDarkMode ? scaffoldSecondaryDark : primaryColor;

extension SExt on String {
  String get translate => appLocalizations!.translate(this);
}

Future<void> launchUrl(String url, {bool forceWebView = false}) async {
  log(url);
  await launch(url, forceWebView: forceWebView, enableJavaScript: true, statusBarBrightness: Brightness.light).catchError((e) {
    log(e);
    toast('Invalid URL: $url');
  });
}

bool get isRTL => RTLLanguage.contains(appStore.selectedLanguageCode);

InputDecoration inputDecoration(BuildContext context, {required String labelText}) => InputDecoration(
      labelText: labelText,
      labelStyle: primaryTextStyle(),
      alignLabelWithHint: true,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: Colors.red, width: 1.0),
      ),
      errorMaxLines: 2,
      errorStyle: primaryTextStyle(color: Colors.red, size: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(width: 1.0, color: context.dividerColor),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(width: 1.0, color: context.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: context.dividerColor, width: 1.0),
      ),
    );

List<String> setSearchParam(String caseNumber) {
  List<String> caseSearchList = [];
  String temp = "";
  for (int i = 0; i < caseNumber.length; i++) {
    temp = temp + caseNumber[i];
    caseSearchList.add(temp.toLowerCase());
  }
  return caseSearchList;
}

String getThemeModeString(int value) {
  if (value == 0) {
    return 'Light Mode';
  } else if (value == 1) {
    return 'Dark Mode';
  } else if (value == 2) {
    return 'System Default';
  }
  return '';
}

String getFontSizeString(int value) {
  if (value == 0) {
    return 'Small';
  } else if (value == 1) {
    return 'Medium';
  } else if (value == 2) {
    return 'Large';
  }
  return '';
}

void appSetting() {
  mChatFontSize = getIntAsync(FONT_SIZE_PREF, defaultValue: 16);
  mIsEnterKey = getBoolAsync(IS_ENTER_KEY, defaultValue: false);
  mSelectedImage = getStringAsync(SELECTED_WALLPAPER, defaultValue: "assets/default_wallpaper.png");
  appSettingStore.setReportCount(aReportCount: getIntAsync(reportCount));
}

void loginData() {
  loginStore.setPhotoUrl(aPhotoUrl: getStringAsync(userPhotoUrl));
  loginStore.setDisplayName(aDisplayName: getStringAsync(userDisplayName));
  loginStore.setEmail(aEmail: getStringAsync(userEmail));
  loginStore.setMobileNumber(aMobileNumber: getStringAsync(userMobileNumber));
  loginStore.setId(aId: getStringAsync(userId));
  loginStore.setIsEmailLogin(aIsEmailLogin: getBoolAsync(isEmailLogin));
  loginStore.setStatus(aStatus: getStringAsync(userStatus));
}

getCallStatusIcon(String? callStatus) {
  Icon _icon;
  double _iconSize = 15;

  switch (callStatus) {
    case CALLED_STATUS_DIALLED:
      _icon = Icon(Icons.call_made, size: _iconSize, color: Colors.green);
      break;

    case CALLED_STATUS_MISSED:
      _icon = Icon(Icons.call_missed, size: _iconSize, color: Colors.red);
      break;

    default:
      _icon = Icon(Icons.call_received, size: _iconSize, color: Colors.grey);
      break;
  }

  return Container(margin: EdgeInsets.only(right: 5), child: _icon);
}

String formatDateString(String dateString) {
  DateTime dateTime = DateTime.parse(dateString);

  return dateTime.timeAgo;
}

UserModel sender = UserModel(
  name: getStringAsync(userDisplayName),
  photoUrl: getStringAsync(userPhotoUrl),
  uid: getStringAsync(userId),
  oneSignalPlayerId: getStringAsync(playerId),
);

void unblockDialog(BuildContext context, {required UserModel receiver}) async {
  return await showInDialog(
    context,
    title: Text('Unblock ${receiver.name} to send a message.', style: primaryTextStyle()),
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
          List<DocumentReference> temp = [];

          temp = await userService.userByEmail(getStringAsync(userEmail)).then((value) => value.blockedTo!);

          if (temp.contains(userService.getUserReference(uid: receiver.uid.validate()))) {
            temp.removeWhere((element) => element == userService.getUserReference(uid: receiver.uid.validate()));
          }

          userService.unBlockUser({"blockedTo": temp}).then((value) {
            finish(context);
            finish(context);
            finish(context);
          }).catchError((e) {
            //
          });
        },
        child: Text(
          "Unblock".toUpperCase(),
          style: TextStyle(color: secondaryColor),
        ),
      ),
    ],
  );
}
