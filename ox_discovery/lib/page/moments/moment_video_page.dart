import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:chewie/chewie.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:ox_common/widgets/common_toast.dart';

class MomentVideoPage extends StatefulWidget {
  final String videoUrl;
  const MomentVideoPage({Key? key, required this.videoUrl})
      : super(key: key);

  @override
  State<MomentVideoPage> createState() => _MomentVideoPageState();
}

class _MomentVideoPageState extends State<MomentVideoPage> {
  final GlobalKey<_CustomControlsState> _customControlsKey =
      GlobalKey<_CustomControlsState>();
  ChewieController? _chewieController;
  late VideoPlayerController _videoPlayerController;
  int? bufferDelay;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializePlayer();
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _onVideoTap() {
    setState(() {
      if (_videoPlayerController.value.isPlaying) {
        _videoPlayerController.pause();
        _customControlsKey.currentState?.showControls();
      } else {
        _videoPlayerController.play();
        _customControlsKey.currentState?.showControls();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _chewieController != null &&
            _chewieController!.videoPlayerController.value.isInitialized
        ?  Container(
              color: ThemeColor.color180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: _onVideoTap,
                    child: SafeArea(
                      child: Chewie(
                        controller: _chewieController!,
                      ),
                    ),
                  )
                ],
            ),
          )
        : Container();
  }

  Future<void> initializePlayer() async {
    final file = await DefaultCacheManager().getSingleFile(widget.videoUrl);

    try {
      _videoPlayerController = VideoPlayerController.file(file);
      await Future.wait([
        _videoPlayerController.initialize(),
      ]);
      _createChewieController();
      setState(() {});
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      customControls: CustomControls(
        key: _customControlsKey,
        videoPlayerController: _videoPlayerController,
        videoUrl: widget.videoUrl,
      ),
      showControls: true,
      videoPlayerController: _videoPlayerController,
      hideControlsTimer: Duration(seconds: 3),
      autoPlay: true,
      looping: false,
      progressIndicatorDelay:
          bufferDelay != null ? Duration(milliseconds: bufferDelay!) : null,
      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
            iconData: Icons.live_tv_sharp,
            title: 'Toggle Video Src',
            onTap: () async {
              await _videoPlayerController.pause();
            },
          ),
        ];
      },
    );
  }
}

class CustomControlsOption {
  bool isDragging;
  bool isVisible;
  CustomControlsOption({required this.isDragging, required this.isVisible});
}

class CustomControls extends StatefulWidget {
  final VideoPlayerController videoPlayerController;
  final String videoUrl;
  CustomControls(
      {Key? key, required this.videoPlayerController, required this.videoUrl})
      : super(key: key);

  @override
  _CustomControlsState createState() => _CustomControlsState();
}

class _CustomControlsState extends State<CustomControls> {
  ValueNotifier<CustomControlsOption> customControlsStatus =
      ValueNotifier(CustomControlsOption(
    isVisible: true,
    isDragging: false,
  ));

  Timer? _hideTimer;
  List<double> speekList = [0.5, 1.0, 1.5, 2.0];
  ValueNotifier<double> speekNotifier = ValueNotifier(1.0);

  @override
  void initState() {
    super.initState();
    widget.videoPlayerController.addListener(() {
      if(!widget.videoPlayerController.value.isPlaying && !customControlsStatus.value.isDragging){
        customControlsStatus.value = CustomControlsOption(
          isVisible: true,
          isDragging: false,
        );
      }
      setState(() {});
    });
    hideControlsAfterDelay();
  }

  void hideControlsAfterDelay() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      customControlsStatus.value = CustomControlsOption(
        isVisible: false,
        isDragging: customControlsStatus.value.isDragging,
      );
    });
  }

  void showControls() {
    customControlsStatus.value = CustomControlsOption(
      isVisible: true,
      isDragging: customControlsStatus.value.isDragging,
    );
    hideControlsAfterDelay();
  }

  void _toggleControls() {
    if (customControlsStatus.value.isVisible &&
        widget.videoPlayerController.value.isPlaying) {
      hideControlsAfterDelay();
    } else {
      customControlsStatus.value = CustomControlsOption(
        isVisible: false,
        isDragging: customControlsStatus.value.isDragging,
      );
      _hideTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child:     GestureDetector(
            onTap: _toggleControls,
            child: Container(
              height: size.height - 200,
              width: double.infinity,
            ),
          ),
        ),
        _buildPlayPause(),
        _buildProgressBar(),
        _buildBottomOption(),
      ],
    );
  }

  Widget _buildBottomOption() {
    return ValueListenableBuilder<CustomControlsOption>(
        valueListenable: customControlsStatus,
        builder: (context, value, child) {
          if (!value.isVisible) return Container();
          return Positioned(
            bottom: 10.0,
            left: 20.0,
            right: 20.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                    onTap: () {
                      OXNavigator.pop(context);
                    },
                    child: Container(
                        width: 26.px,
                        height: 26.px,
                        decoration: BoxDecoration(
                          color: ThemeColor.color120,
                          borderRadius: BorderRadius.all(Radius.circular(26)),
                        ),
                        child: Center(
                          child: CommonImage(
                            iconName: 'close_icon.png',
                            package: 'ox_discovery',
                            size: 16.px,
                            color: Colors.white,
                          ),
                        ))),
                GestureDetector(
                  onTap: () async {
                    await OXLoading.show();
                    if (RegExp(r'https?:\/\/').hasMatch(widget.videoUrl)) {
                      var appDocDir = await getTemporaryDirectory();
                      String savePath = appDocDir.path + "/temp.mp4";
                      await Dio().download(widget.videoUrl, savePath);
                      final result = await ImageGallerySaver.saveFile(savePath);
                      if (result['isSuccess'] == true) {
                        await OXLoading.dismiss();
                        CommonToast.instance.show(context, 'Save successful');
                      }
                    } else {
                      final result =
                          await ImageGallerySaver.saveFile(widget.videoUrl);
                      if (result['isSuccess'] == true) {
                        await OXLoading.dismiss();
                        CommonToast.instance.show(context, 'Save successful');
                      }
                    }
                  },
                  child: Container(
                    width: 26.px,
                    height: 26.px,
                    decoration: BoxDecoration(
                      color: ThemeColor.color120,
                      borderRadius: BorderRadius.all(Radius.circular(26)),
                    ),
                    child: Center(
                      child: CommonImage(
                        iconName: 'moment_more.png',
                        package: 'ox_discovery',
                        size: 16.px,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildPlayPause() {
    return ValueListenableBuilder<CustomControlsOption>(
      valueListenable: customControlsStatus,
      builder: (context, value, child) {
        if (widget.videoPlayerController.value.isPlaying || value.isDragging) {
          return Container();
        }
        if (!value.isVisible) {
          return Container();
        }
        Size size = MediaQuery.of(context).size;
        return Positioned(
          bottom: (size.height / 2) - 40,
          left: (size.width / 2) - 40,
          child: GestureDetector(
            onTap: () {
              if (widget.videoPlayerController.value.isPlaying) {
                widget.videoPlayerController.pause();

                showControls();
              } else {
                widget.videoPlayerController.play();

                hideControlsAfterDelay();
              }
            },
            child: CommonImage(
              iconName: 'play_moment_icon.png',
              package: 'ox_discovery',
              size: 80.0.px,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return ValueListenableBuilder<CustomControlsOption>(
        valueListenable: customControlsStatus,
        builder: (context, value, child) {
          if (!value.isVisible) return Container();
          return Positioned(
            bottom: 40.0,
            left: 20.0,
            right: 20.0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      child: Row(
                        children: [
                          Text(
                            _formatDuration(
                                widget.videoPlayerController.value.position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            ' / ',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _formatDuration(
                                widget.videoPlayerController.value.duration),
                            style: TextStyle(
                              color: ThemeColor.color100,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<double>(
                      valueListenable: speekNotifier,
                      builder: (context, value, child) {
                        return GestureDetector(
                            onTap: () {
                              int findIndex = speekList.indexOf(value);
                              double lastValue;
                              if (findIndex == speekList.length - 1) {
                                lastValue = speekList[0];
                              } else {
                                lastValue = speekList[findIndex + 1];
                              }
                              speekNotifier.value = lastValue;
                              widget.videoPlayerController
                                  .setPlaybackSpeed(lastValue);
                            },
                            child: Text(
                              value.toString(),
                              style: TextStyle(
                                  color: ThemeColor.white,
                                  fontWeight: FontWeight.w600),
                            ));
                      },
                    ),
                  ],
                ).setPaddingOnly(bottom: 10.px),
                CustomVideoProgressIndicator(
                  controller: widget.videoPlayerController,
                  callback: callback,
                ),
              ],
            ),
          );
        });
  }

  void callback(bool isStart) {
    if (isStart) {
      _hideTimer?.cancel();
      if (widget.videoPlayerController.value.isPlaying) {
        widget.videoPlayerController.pause();
      }
      customControlsStatus.value = CustomControlsOption(
        isDragging: true,
        isVisible: customControlsStatus.value.isVisible,
      );
    } else {
      if (!widget.videoPlayerController.value.isPlaying) {
        widget.videoPlayerController.play();
      }
      customControlsStatus.value = CustomControlsOption(
        isDragging: false,
        isVisible: customControlsStatus.value.isVisible,
      );
      hideControlsAfterDelay();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }
}

class CustomVideoProgressIndicator extends StatelessWidget {
  final VideoPlayerController controller;
  final Function callback;

  const CustomVideoProgressIndicator(
      {super.key, required this.controller, required this.callback});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: controller.position.asStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }
        Duration position = snapshot.data ?? Duration.zero;
        double progress =
            position.inMilliseconds / controller.value.duration.inMilliseconds;

        return LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (details) {
                callback(true);
                final RenderBox box = context.findRenderObject() as RenderBox;
                final Offset offset = box.globalToLocal(details.globalPosition);
                double newProgress = offset.dx / constraints.maxWidth;
                if (newProgress < 0) newProgress = 0;
                if (newProgress > 1) newProgress = 1;
                controller.seekTo(controller.value.duration * newProgress);
              },
              onHorizontalDragEnd: (details) {
                callback(false);
              },
              onHorizontalDragUpdate: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final Offset offset = box.globalToLocal(details.globalPosition);
                double newProgress = offset.dx / constraints.maxWidth;
                if (newProgress < 0) newProgress = 0;
                if (newProgress > 1) newProgress = 1;
                controller.seekTo(controller.value.duration * newProgress);
              },
              child: Container(
                height: 40,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        height: 5, // Thin progress bar
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: LinearProgressIndicator(
                          value: progress,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                    Positioned(
                      left: constraints.maxWidth * progress -
                          10, // Adjust for circle size
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          final RenderBox box =
                              context.findRenderObject() as RenderBox;
                          final Offset offset =
                              box.globalToLocal(details.globalPosition);
                          double newProgress = offset.dx / constraints.maxWidth;
                          if (newProgress < 0) newProgress = 0;
                          if (newProgress > 1) newProgress = 1;
                          controller
                              .seekTo(controller.value.duration * newProgress);
                        },
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}