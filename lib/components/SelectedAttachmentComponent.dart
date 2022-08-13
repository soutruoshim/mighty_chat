import 'dart:io';

import 'package:cached_video_player/cached_video_player.dart';
import 'package:chat/models/StoryModel.dart';
import 'package:chat/models/UserModel.dart';
import 'package:chat/utils/AppColors.dart';
import 'package:chat/utils/AppCommon.dart';
import 'package:chat/utils/AppConstants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path/path.dart' as path;

import '../main.dart';

class SelectedAttachmentComponent extends StatefulWidget {
  final File? file;
  final bool isVideo;
  final bool isAudio;
  final UserModel? userModel;
  final bool isStory;

  SelectedAttachmentComponent({this.file, this.isVideo = false, this.isAudio = false, this.userModel, this.isStory = false});

  @override
  _SelectedAttachmentComponentState createState() => _SelectedAttachmentComponentState();
}

class _SelectedAttachmentComponentState extends State<SelectedAttachmentComponent> {
  TextEditingController imageMessage = TextEditingController();
  late VideoPlayerController _controller;
  AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    if (widget.isVideo) {
      _controller = VideoPlayerController.file(widget.file!)
        ..initialize().then((_) {
          setState(() {});
        });
    } else if (widget.isAudio) {
      await _player.setFilePath(widget.file!.path, preload: true);
      setState(() {});
    }
  }

  Future<void> uploadStory() async {
    appStore.setLoading(true);
    await storyService.uploadImage(widget.file!).then((value) async {

      if (widget.isStory) {
        StoryModel data = StoryModel();
        data.userId = getStringAsync(userId);
        data.caption = '';
        data.createAt = Timestamp.now();
        data.updatedAt = Timestamp.now();
        data.imagePath = value;
        data.userImgPath = loginStore.mPhotoUrl;
        data.userName = loginStore.mDisplayName;

        // data.userImgPath = getStringAsync(USER_PROFILE_IMAGE);

        await storyService.addStory(data, userId: getStringAsync(userId)).then((value) {
          _controller.pause();
          appStore.setLoading(false);
          toast('status_uploaded'.translate);
        }).catchError((e) {
          appStore.setLoading(false);
          toast(e.toString(), print: true);
        });
      }
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
    finish(context, true);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.isVideo) {
      _player.dispose();
      _controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget showWidget() {
      if (widget.isAudio) {
        return Container(
          height: context.height() * 0.8,
          width: context.width(),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${path.basename(widget.file!.path)}', style: boldTextStyle(color: Colors.white)),
                  16.height,
                  StreamBuilder<Duration?>(
                    stream: _player.durationStream,
                    builder: (context, snapshot) {
                      final duration = snapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration>(
                        stream: _player.positionStream,
                        builder: (context, snap) {
                          var position = snap.data ?? Duration.zero;
                          if (position > duration) {
                            position = duration;
                          }
                          return SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3.0,
                              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
                              overlayColor: Colors.purple.withAlpha(32),
                              overlayShape: RoundSliderOverlayShape(overlayRadius: 14.0),
                            ),
                            child: Slider(
                              min: 0.0,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white12,
                              max: duration.inSeconds.toDouble(),
                              value: position.inSeconds.toDouble(),
                              onChanged: (value) {
                                _player.seek(Duration(seconds: value.toInt()));
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _player.playing ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ).center(),
                    ),
                    onPressed: () {
                      _player.playing ? _player.pause() : _player.play();
                      setState(() {});
                    },
                  ),
                ],
              ).withWidth(context.width()),
            ],
          ),
        );
      } else if (widget.isVideo) {
        return Container(
          height: context.height() * 0.8,
          width: context.width(),
          child: Stack(
            children: [
              VideoPlayer(_controller),
              IconButton(
                icon: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black38,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ).center(),
                ),
                onPressed: () {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                  setState(() {});
                },
              ).center(),
            ],
          ),
        );
      } else {
        return Container(
          height: context.height(),
          width: context.width(),
          child: Image.file(widget.file!, fit: BoxFit.cover),
        );
      }
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: !widget.isStory ? appBarWidget("Sent to ${widget.userModel!.name.validate()}", textColor: Colors.white) : null,
        body: Container(
          height: context.height(),
          child: Stack(
            children: [
              showWidget(),
              Observer(builder: (_) => Loader().visible(appStore.isLoading)),
              if (widget.isStory)
                Positioned(
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      finish(context);
                    },
                  ),
                ),
              Positioned(
                bottom: 50,
                right: 16,
                child: Container(
                  height: 60,
                  width: 60,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor),
                  child: Icon(Icons.send, color: Colors.white),
                ).onTap(() {
                  uploadStory();
                }, borderRadius: BorderRadius.circular(50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
