class StickerModel {
  String? path;
  String? name;
  bool? isSelected;

  StickerModel({this.path, this.name, this.isSelected});

  List<StickerModel> stickerList() {
    List<StickerModel> stickerList = [];
    stickerList.add(StickerModel(name: "Sticker_01", isSelected: false, path: "assets/sticker/sticker_1.jpeg"));
    stickerList.add(StickerModel(name: "Sticker_02", isSelected: false, path: "assets/sticker/sticker_2.jpeg"));
    stickerList.add(StickerModel(name: "Sticker_03", isSelected: false, path: "assets/sticker/sticker_3.jpeg"));
    stickerList.add(StickerModel(name: "Sticker_04", isSelected: false, path: "assets/sticker/sticker_4.jpeg"));
    stickerList.add(StickerModel(name: "Sticker_05", isSelected: false, path: "assets/sticker/sticker_5.png"));
    stickerList.add(StickerModel(name: "Sticker_06", isSelected: false, path: "assets/sticker/sticker_6.png"));
    stickerList.add(StickerModel(name: "Sticker_07", isSelected: false, path: "assets/sticker/sticker_7.png"));
    stickerList.add(StickerModel(name: "Sticker_08", isSelected: false, path: "assets/sticker/sticker_8.png"));
    stickerList.add(StickerModel(name: "Sticker_09", isSelected: false, path: "assets/sticker/sticker_9.jpeg"));
    stickerList.add(StickerModel(name: "Sticker_06", isSelected: false, path: "assets/sticker/sticker_6.png"));
    stickerList.add(StickerModel(name: "Sticker_07", isSelected: false, path: "assets/sticker/sticker_7.png"));
    stickerList.add(StickerModel(name: "Sticker_08", isSelected: false, path: "assets/sticker/sticker_8.png"));
    stickerList.add(StickerModel(name: "Sticker_09", isSelected: false, path: "assets/sticker/sticker_9.jpeg"));
    stickerList.add(StickerModel(name: "Sticker_06", isSelected: false, path: "assets/sticker/sticker_6.png"));
    stickerList.add(StickerModel(name: "Sticker_07", isSelected: false, path: "assets/sticker/sticker_7.png"));
    stickerList.add(StickerModel(name: "Sticker_08", isSelected: false, path: "assets/sticker/sticker_8.png"));
    stickerList.add(StickerModel(name: "Sticker_09", isSelected: false, path: "assets/sticker/sticker_9.jpeg"));
    return stickerList;
  }
}
