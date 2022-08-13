import 'package:chat/models/FileModel.dart';
import 'package:chat/models/Language.dart';
import 'package:chat/screens/SplashScreen.dart';
import 'package:chat/services/AuthService.dart';
import 'package:chat/services/CallService.dart';
import 'package:chat/services/ChatMessageService.dart';
import 'package:chat/services/ChatRequestService.dart';
import 'package:chat/services/NotificationService.dart';
import 'package:chat/services/StoryService.dart';
import 'package:chat/services/UserService.dart';
import 'package:chat/store/AppSettingStore.dart';
import 'package:chat/store/AppStore.dart';
import 'package:chat/store/LoginStore.dart';
import 'package:chat/store/MessageRequestStore.dart';
import 'package:chat/utils/AppColors.dart';
import 'package:chat/utils/AppCommon.dart';
import 'package:chat/utils/AppConstants.dart';
import 'package:chat/utils/AppLocalizations.dart';
import 'package:chat/utils/AppTheme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:sqflite/sqflite.dart';

//region Services Objects
UserService userService = UserService();
AuthService authService = AuthService();
ChatMessageService chatMessageService = ChatMessageService();
CallService callService = CallService();
NotificationService notificationService = NotificationService();
StoryService storyService = StoryService();

ChatRequestService chatRequestService = ChatRequestService();
FirebaseFirestore fireStore = FirebaseFirestore.instance;

//endregion
late AppLocalizations? appLocalizations;
late Language? language;
List<Language> languages = Language.getLanguages();
late List<FileModel> fileList = [];
OneSignal oneSignal = OneSignal();

//region MobX Objects
AppStore appStore = AppStore();
LoginStore loginStore = LoginStore();
AppSettingStore appSettingStore = AppSettingStore();
MessageRequestStore messageRequestStore = MessageRequestStore();
//endregion

late MessageType? messageType;

//region Default Settings
int mChatFontSize = 16;
int mAdShowCount = 0;

String mSelectedImage = "assets/default_wallpaper.png";

bool mIsEnterKey = false;
List<String?> postViewedList = [];

Database? localDbInstance;
//endregion

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  Function? originalOnError = FlutterError.onError;

  FlutterError.onError = (FlutterErrorDetails errorDetails) async {
    await FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    originalOnError!(errorDetails);
  };
  await initialize();

  appSetting();

  appButtonBackgroundColorGlobal = primaryColor;
  defaultAppButtonTextColorGlobal = Colors.white;
  appBarBackgroundColorGlobal = primaryColor;
  defaultLoaderBgColorGlobal = chatColor;
  appStore.setLanguage(getStringAsync(LANGUAGE, defaultValue: defaultLanguage));

  int themeModeIndex = getIntAsync(THEME_MODE_INDEX);
  if (themeModeIndex == ThemeModeLight) {
    appStore.setDarkMode(false);
  } else if (themeModeIndex == ThemeModeDark) {
    appStore.setDarkMode(true);
  }

  OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

  OneSignal.shared.setAppId(mOneSignalAppId).then((value) {
    OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
      print("Accepted permission: $accepted");
    });

    OneSignal.shared.setNotificationWillShowInForegroundHandler((OSNotificationReceivedEvent? event) {
      return event?.complete(event.notification);
    });

    OneSignal.shared.getDeviceState().then((value) async {
      await setValue(playerId.validate(), value!.userId.validate());
    });

    OneSignal.shared.disablePush(false);

    OneSignal.shared.consentGranted(true);
    OneSignal.shared.requiresUserPrivacyConsent();

    OneSignal.shared.setSubscriptionObserver((changes) async {
      if (getBoolAsync(IS_LOGGED_IN)) {
        userService.updateDocument({
          'oneSignalPlayerId': changes.to.userId,
          'updatedAt': Timestamp.now(),
        }, getStringAsync(userId)).then((value) {
          log("Updated");
        }).catchError((e) {
          log(e.toString());
        });
      }
      if (!changes.to.userId.isEmptyOrNull) await setValue(playerId.validate(), changes.to.userId);
    });
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: appStore.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        supportedLocales: Language.languagesLocale(),
        localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        localeResolutionCallback: (locale, supportedLocales) => locale,
        locale: Locale(appStore.selectedLanguageCode),
        home: SplashScreen(),
        builder: scrollBehaviour(),
      ),
    );
  }
}
