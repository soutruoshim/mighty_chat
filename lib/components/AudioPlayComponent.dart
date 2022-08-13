import 'package:chat/models/ChatMessageModel.dart';
import 'package:chat/utils/AppColors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:nb_utils/nb_utils.dart';

class AudioPlayComponent extends StatefulWidget {
  final ChatMessageModel? data;
  final String? time;

  AudioPlayComponent({this.data, this.time});

  @override
  _AudioPlayComponentState createState() => _AudioPlayComponentState();
}

class _AudioPlayComponentState extends State<AudioPlayComponent> {
  // AudioPlayer audioPlayer = AudioPlayer();
  ja.AudioPlayer _player = ja.AudioPlayer();

  Duration duration = Duration();
  Duration position = Duration();
  double minValue = 0.0;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    await _player.setUrl(widget.data!.photoUrl.validate(), preload: true).then((value) {
      log(value);
    }).catchError((e) {
      log(e.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 50,
                decoration: boxDecorationWithShadow(backgroundColor: chatColor.withOpacity(0.8), borderRadius: BorderRadius.all(Radius.circular(8))),
                margin: EdgeInsets.all(2),
                width: 50,
                child: Icon(Icons.headset_outlined, color: Colors.white54),
              ),
              if (widget.data!.photoUrl == null)
                CircularProgressIndicator().withHeight(25).withWidth(25).paddingAll(8)
              else
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: !widget.data!.isMe! ? chatColor : Colors.white,
                  ).center(),
                  onPressed: () async {
                    if (isPlaying) {
                      isPlaying = false;
                      setState(() {});
                      await _player.pause().catchError((e) {
                        toast(e.toString());
                      });
                    } else {
                      isPlaying = true;
                      setState(() {});
                      await _player.play().catchError(
                        (e) {
                          toast(e.toString());
                        },
                      );
                    }
                  },
                ),
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
              ).expand(),
            ],
          ),
          Positioned(
            bottom: 2,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.time.validate(),
                  style: primaryTextStyle(color: !widget.data!.isMe.validate() ? Colors.blueGrey.withOpacity(0.6) : whiteColor.withOpacity(0.6), size: 10),
                ),
                2.width,
                widget.data!.isMe!
                    ? !widget.data!.isMessageRead!
                        ? Icon(Icons.done, size: 12, color: Colors.white60)
                        : Icon(Icons.done_all, size: 12, color: Colors.white60)
                    : Offstage()
              ],
            ),
          )
        ],
      ),
    );
  }
}
