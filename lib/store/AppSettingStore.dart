import 'package:chat/utils/AppConstants.dart';
import 'package:mobx/mobx.dart';
import 'package:nb_utils/nb_utils.dart';

part 'AppSettingStore.g.dart';

class AppSettingStore = AppSettingStoreBase with _$AppSettingStore;

abstract class AppSettingStoreBase with Store {
  @observable
  int? mFontSize = -1;

  @observable
  int mReportCount = 10;

  @observable
  bool? mEnterKey = false;

  @action
  void setFontSize({int? aFontSize}) => mFontSize = aFontSize;

  @action
  void setReportCount({required int aReportCount, bool isInitialize = false}) {
    mReportCount = aReportCount;
    if (isInitialize) setValue(reportCount, aReportCount);
  }

  @action
  void setEnterKey({bool? aEnterKey}) => mEnterKey = aEnterKey;
}
