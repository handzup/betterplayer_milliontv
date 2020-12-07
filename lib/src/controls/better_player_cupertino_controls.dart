import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:better_player/src/controls/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_controls_state.dart';
import 'package:better_player/src/controls/better_player_cupertino_progress_bar.dart';
import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:better_player/src/controls/widgets/blured_card.dart';
import 'package:better_player/src/controls/widgets/menu.dart';
import 'package:better_player/src/controls/widgets/quality.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/core/constants.dart';
import 'package:better_player/src/hls/better_player_hls_track.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:marquee_text/marquee_text.dart';

import 'better_player_clickable_widget.dart';
import 'widgets/resolution_card.dart';

class BetterPlayerCupertinoControls extends StatefulWidget {
  ///Callback used to send information if player bar is hidden or not
  final Function(bool visbility) onControlsVisibilityChanged;

  ///Controls config
  final BetterPlayerControlsConfiguration controlsConfiguration;

  const BetterPlayerCupertinoControls({
    this.onControlsVisibilityChanged,
    this.controlsConfiguration,
  })  : assert(onControlsVisibilityChanged != null),
        assert(controlsConfiguration != null);

  @override
  State<StatefulWidget> createState() {
    return _BetterPlayerCupertinoControlsState();
  }
}

class _BetterPlayerCupertinoControlsState
    extends BetterPlayerControlsState<BetterPlayerCupertinoControls>
    with SingleTickerProviderStateMixin {
  final marginSize = 5.0;
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _expandCollapseTimer;
  Timer _initTimer;
  bool _displayTapped = false;
  bool _dragging = false;

  bool _wasLoading = false;
  AnimationController playPauseIconAnimationController;

  VideoPlayerController _controller;
  BetterPlayerController _betterPlayerController;
  StreamSubscription _controlsVisibilityStreamSubscription;

  BetterPlayerControlsConfiguration get _controlsConfiguration =>
      widget.controlsConfiguration;

  @override
  VideoPlayerValue get latestValue => _latestValue;

  @override
  BetterPlayerController get betterPlayerController => _betterPlayerController;

  @override
  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      _controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    _betterPlayerController = BetterPlayerController.of(context);

    if (_latestValue?.hasError == true) {
      return _buildErrorWidget();
    }

    final backgroundColor = _controlsConfiguration.controlBarColor;
    final iconColor = _controlsConfiguration.iconsColor;
    _betterPlayerController = BetterPlayerController.of(context);
    _controller = _betterPlayerController.videoPlayerController;
    final orientation = MediaQuery.of(context).orientation;
    final barHeight = orientation == Orientation.portrait
        ? _controlsConfiguration.controlBarHeight
        : _controlsConfiguration.controlBarHeight + 17;
    final buttonPadding = orientation == Orientation.portrait ? 16.0 : 24.0;
    _wasLoading = isLoading(_latestValue);
    return MouseRegion(
      onHover: (_) {
        cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () => cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Stack(
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Container(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            _wasLoading
                                ? Expanded(
                                    child: Center(child: _buildLoadingWidget()))
                                : SizedBox.shrink(),
                          ],
                        ),
                        Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  _buildHitBackwardArea(),
                                  _buildHitArea(),
                                  _buildHitForwardArea()
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildNextVideoWidget(),
                  Positioned(
                      left: 16,
                      right: 16,
                      bottom: _betterPlayerController.isFullScreen ? 30 : 40,
                      child: Container(
                        child: SizedBox(
                            height:
                                betterPlayerController.isFullScreen ? 80 : 145,
                            child: _buildBottomBar(
                              backgroundColor,
                              iconColor,
                            )),
                      )),
                ],
              ),
              _buildTopBar(
                  backgroundColor, iconColor, barHeight, buttonPadding),
            ],
          ),
        ),
      ),

      // Stack(
      //   children: [
      //     _buildTopBar(backgroundColor, iconColor, barHeight, buttonPadding),
      //     GestureDetector(
      //       onTap: cancelAndRestartTimer,
      //       onDoubleTap: () {
      //         cancelAndRestartTimer();
      //         _playPause();
      //       },
      //       child: AbsorbPointer(
      //         absorbing: _hideStuff,
      //         child: Stack(
      //           children: <Widget>[
      //             Column(
      //               children: [
      //                 _wasLoading
      //                     ? Expanded(
      //                         child: Center(child: _buildLoadingWidget()))
      //                     : _buildHitArea(),
      //               ],
      //             ),
      //             _buildNextVideoWidget(),
      //             Positioned(
      //                 left: 16,
      //                 right: 16,
      //                 bottom: _betterPlayerController.isFullScreen ? 30 : 40,
      //                 child: SizedBox(
      //                     height:
      //                         betterPlayerController.isFullScreen ? 80 : 145,
      //                     child: _buildBottomBar(
      //                       backgroundColor,
      //                       iconColor,
      //                     ))),
      //           ],
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
    );
  }

  bool backwardAnimate = false;
  bool forwardAnimate = false;
  Expanded _buildHitForwardArea() {
    var isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: () {
          print('tap');
          setState(() {
            _hideStuff = true;
            forwardAnimate = true;
          });
          print(forwardAnimate);
          skipForward();
          Future.delayed(Duration(milliseconds: 500))
              .then((value) => setState(() => forwardAnimate = false));
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedOpacity(
                opacity: forwardAnimate ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: Container(
                  width: isLandscape ? 200 : 100,
                  height: isLandscape ? 200 : 100,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: Colors.white.withOpacity(.5)),
                  child: Icon(CupertinoIcons.forward_fill,
                      size: 30, color: Colors.white),
                )),
          ),
        ),
      ),
    );
  }

  Expanded _buildHitBackwardArea() {
    var isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Expanded(
      child: GestureDetector(
        onDoubleTap: () {
          if (_displayTapped) {
            setState(() {
              _hideStuff = true;
              backwardAnimate = true;
            });
            skipBack();
            Future.delayed(Duration(milliseconds: 500))
                .then((value) => setState(() => backwardAnimate = false));
          } else
            cancelAndRestartTimer();
        },
        child: Container(
          child: Center(
            child: AnimatedOpacity(
                opacity: backwardAnimate ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: Container(
                  width: isLandscape ? 200 : 100,
                  height: isLandscape ? 200 : 100,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: Colors.white.withOpacity(.5)),
                  child: Icon(CupertinoIcons.backward_fill,
                      size: 30, color: Colors.white),
                )),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildSkipBack() {
    return GestureDetector(
      onTap: skipBack,
      child: Container(
        color: Colors.transparent,
        child: Icon(
          CupertinoIcons.gobackward_15,
          color: Colors.white,
          size: 18.0,
        ),
      ),
    );
  }

  GestureDetector _buildSkipForward() {
    return GestureDetector(
      onTap: skipForward,
      child: Container(
        child: Icon(
          CupertinoIcons.goforward_15,
          color: Colors.white,
          size: 18.0,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    _controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _expandCollapseTimer?.cancel();
    _initTimer?.cancel();
    _controlsVisibilityStreamSubscription?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = _betterPlayerController;
    _betterPlayerController = BetterPlayerController.of(context);
    _controller = _betterPlayerController.videoPlayerController;

    if (_oldController != _betterPlayerController) {
      _dispose();
      _initialize();
    }
    if (playPauseIconAnimationController == null) {
      playPauseIconAnimationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400),
        reverseDuration: Duration(milliseconds: 400),
      );
    }
    super.didChangeDependencies();
  }

  AnimatedOpacity _buildBottomBar(
    Color backgroundColor,
    Color iconColor,
  ) {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: _controlsConfiguration.controlsHideTime,
      onEnd: _onPlayerHide,
      child: Column(
        children: [
          _betterPlayerController.isFullScreen
              ? Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMoreButton(
                          _controller,
                        ),
                        GestureDetector(
                            onTap: () => _onExpandCollapse(),
                            child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(
                                    _betterPlayerController.isFullScreen
                                        ? 0
                                        : pi),
                                child: _controlsConfiguration.rotateWidget))
                      ],
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 12, left: 12, top: 12),
                      child: Column(
                        children: [
                          Row(
                            children: <Widget>[
                              _controlsConfiguration.enableProgressBar
                                  ? Expanded(
                                      child: Row(
                                        children: [
                                          _buildPositionOnly(),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          _buildProgressBar(),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          _buildDurationOnly()
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMoreButton(
                          _controller,
                        ),
                        GestureDetector(
                            onTap: () => _onExpandCollapse(),
                            child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(
                                    _betterPlayerController.isFullScreen
                                        ? 0
                                        : pi),
                                child: _controlsConfiguration.rotateWidget))
                      ],
                    ),
                    BluredCard(
                      borderRadius: 8,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(right: 12, left: 12, top: 12),
                        child: Column(
                          children: [
                            Row(
                              children: <Widget>[
                                _controlsConfiguration.enableProgressBar
                                    ? _buildProgressBar()
                                    : const SizedBox.shrink(),
                              ],
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildPositionOnly(),
                                _buildDurationOnly()
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSkipBack(),
                                playPause(),
                                _buildSkipForward()
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildLiveWidget() {
    return Expanded(
      child: Text(
        _betterPlayerController.translations.controlsLive,
        style: TextStyle(
            color: _controlsConfiguration.liveTextColor,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  GestureDetector _buildExpandButton(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10),
            child: Container(
              height: barHeight,
              padding: EdgeInsets.only(
                left: buttonPadding,
                right: buttonPadding,
              ),
              color: backgroundColor,
              child: Center(
                child: Icon(
                  _betterPlayerController.isFullScreen
                      ? _controlsConfiguration.fullscreenDisableIcon
                      : _controlsConfiguration.fullscreenEnableIcon,
                  color: iconColor,
                  size: 12.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Expanded _buildHitArea() {
  //   return Expanded(
  //     child: GestureDetector(
  //       onTap: _latestValue != null && _latestValue.isPlaying
  //           ? () {
  //               if (_hideStuff == true) {
  //                 cancelAndRestartTimer();
  //               } else {
  //                 _hideTimer?.cancel();

  //                 setState(() {
  //                   _hideStuff = true;
  //                 });
  //               }
  //             }
  //           : () {
  //               _hideTimer?.cancel();

  //               setState(() {
  //                 _hideStuff = false;
  //               });
  //             },
  //       child: Container(
  //         color: Colors.transparent,
  //       ),
  //     ),
  //   );
  // }

  Expanded _buildHitArea() {
    bool isFinished = _latestValue == null
        ? false
        : _latestValue.position >=
            (_latestValue.duration != null
                ? _latestValue.duration
                : Duration(seconds: 1));

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: () => () {
          cancelAndRestartTimer();
          _playPause();
        },
        onTap: () {
          if (_betterPlayerController.videoPlayerController.value.isPlaying) {
            if (_displayTapped) {
              setState(() {
                _hideStuff = true;
              });
              _playPause();
            } else
              cancelAndRestartTimer();
          } else {
            _playPause();

            setState(() {
              _hideStuff = true;
            });
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedOpacity(
              opacity:
                  _latestValue != null && !_latestValue.isPlaying && !_dragging
                      ? 1.0
                      : 0.0,
              duration: Duration(milliseconds: 300),
              child: GestureDetector(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).dialogBackgroundColor,
                    borderRadius: BorderRadius.circular(48.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(5.0),
                    child: IconButton(
                        padding: const EdgeInsets.all(0),
                        icon: isFinished
                            ? Icon(
                                Icons.replay,
                                size: 35.0,
                                color: Colors.grey,
                              )
                            : Stack(
                                children: [
                                  !_betterPlayerController.isVideoInitialized()
                                      ? _buildLoadingWidget()
                                      : AnimatedIcon(
                                          icon: AnimatedIcons.play_pause,
                                          progress:
                                              playPauseIconAnimationController,
                                          size: 35.0,
                                          color: Colors.grey,
                                        ),
                                ],
                              ),
                        onPressed: () {
                          _playPause();
                        }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget playPause() {
    bool isFinished = _latestValue == null
        ? false
        : _latestValue.position >=
            (_latestValue.duration ?? Duration(seconds: 1));

    return GestureDetector(
      onTap: () {
        if (_latestValue != null && _latestValue.isPlaying) {
          if (_displayTapped) {
            setState(() {
              _hideStuff = true;
            });
          } else
            cancelAndRestartTimer();
        } else {
          _playPause();

          setState(() {
            _hideStuff = true;
          });
        }
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: AnimatedOpacity(
            opacity: 1,
            duration: Duration(milliseconds: 300),
            child: GestureDetector(
              child: Container(
                child: IconButton(
                    icon: isFinished
                        ? Icon(Icons.replay, size: 35.0, color: Colors.white)
                        : AnimatedIcon(
                            icon: AnimatedIcons.play_pause,
                            progress: playPauseIconAnimationController,
                            size: 35.0,
                            color: Colors.white),
                    onPressed: () {
                      _playPause();
                    }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _playPause() {
    bool isFinished = _latestValue == null
        ? false
        : _latestValue.position >=
            (_latestValue.duration ?? Duration(seconds: 1));

    setState(() {
      if (_betterPlayerController.videoPlayerController.value.isPlaying) {
        playPauseIconAnimationController.reverse();
        _hideStuff = false;
        _hideTimer?.cancel();
        _betterPlayerController.pause();
      } else {
        cancelAndRestartTimer();

        if (!_betterPlayerController.videoPlayerController.value.initialized) {
          _betterPlayerController.play();
          playPauseIconAnimationController.forward();
        } else {
          if (isFinished) {
            _betterPlayerController.seekTo(Duration(seconds: 0));
          }
          playPauseIconAnimationController.forward();
          _betterPlayerController.play();
        }
      }
    });
  }

  Widget _buildResolutionSelectionRow(String name, String url) {
    bool isSelected = url == betterPlayerController.betterPlayerDataSource.url;
    return BetterPlayerMaterialClickableWidget(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              "$name",
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController.setResolution(url);
      },
    );
  }

  Widget _buildTrackRow(BetterPlayerHlsTrack track, String preferredName) {
    assert(track != null, "Track can't be null");

    String trackName = preferredName ??
        track.width.toString() +
            "x" +
            track.height.toString() +
            " " +
            BetterPlayerUtils.formatBitrate(track.bitrate);

    var selectedTrack = betterPlayerController.betterPlayerTrack;
    bool isSelected = selectedTrack != null && selectedTrack == track;

    return BetterPlayerMaterialClickableWidget(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              "$trackName",
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController.setTrack(track);
      },
    );
  }

  BetterPlayerHlsTrack selectedTrack;
  Resolution selectedResolution;
  bool _showMenu = false;
  void drDownTap() {
    setState(() => _showMenu = true);
  }

  builQuality() {
    List<String> trackNames =
        betterPlayerController.betterPlayerDataSource.hlsTrackNames ?? List();
    List<BetterPlayerHlsTrack> tracks =
        betterPlayerController.betterPlayerTracks;
    var children = List<Widget>();
    for (var index = 0; index < tracks.length; index++) {
      var preferredName = trackNames.length > index ? trackNames[index] : null;
      children.add(_buildTrackRow(tracks[index], preferredName));
    }
    var resolutions = betterPlayerController.betterPlayerDataSource.resolutions;
    resolutions?.forEach((key, value) {
      children.add(_buildResolutionSelectionRow(key, value));
    });
  }

  GestureDetector _buildMoreButton(
    VideoPlayerController controller,
  ) {
    List<String> trackNames =
        betterPlayerController.betterPlayerDataSource.hlsTrackNames ?? List();
    List<BetterPlayerHlsTrack> tracks =
        betterPlayerController.betterPlayerTracks;
    var children = List<Resolution>();
    // for (var index = 0; index < tracks.length; index++) {
    //   var preferredName = trackNames.length > index ? trackNames[index] : null;
    //   children.add(_buildTrackRow(tracks[index], preferredName));
    // }
    var resolutions = betterPlayerController.betterPlayerDataSource.resolutions;
    resolutions?.forEach((key, value) {
      children.add(Resolution(name: key, url: value));
    });

    // if (children.isEmpty) {
    //   children.add(_buildTrackRow(BetterPlayerHlsTrack(0, 0, 0),
    //       betterPlayerController.translations.generalDefault));
    // }

    return GestureDetector(
      onTap: () {
        onShowMoreClicked();
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: ModalEntry(
              visible: _showMenu,
              onClose: () => setState(() => _showMenu = false),
              childAnchor: Alignment.topCenter,
              menuAnchor: Alignment.bottomCenter,
              menu: Menu(
                  children: children.isEmpty
                      ? List.generate(
                          tracks.length,
                          (index) => ItemCard(
                                track: tracks[index],
                                onTap: (track) => {
                                  betterPlayerController.setTrack(track),
                                  setState(() => selectedTrack = track)
                                },
                                isSelected: tracks[index] == selectedTrack,
                              ))
                      : List.generate(
                          children.length,
                          (index) => ResolutionCard(
                            track: children[index],
                            onTap: (track) => {
                              betterPlayerController.setResolution(track.url),
                              setState(() => selectedResolution = track)
                            },
                            isSelected: children[index].name ==
                                selectedResolution?.name,
                          ),
                        )),
              child: GestureDetector(
                onTap: () => drDownTap(),
                child: Container(
                  width: 80,
                  height: 30,
                  child: Container(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 0, bottom: 10),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [_controlsConfiguration.qualityIcon],
                            // SvgPicture.asset(
                            //     'assets/video_quality.svg',
                            //     height: 30,
                            //     width: 30,
                            //     color: Colors.white,
                            //   ),
                          ),
                          Positioned(
                              left: 12,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: <Widget>[
                                  // Stroked text as border.
                                  Text(
                                    selectedTrack != null
                                        ? '${selectedTrack.width}p'
                                        : 'Auto',
                                    style: TextStyle(
                                      fontSize: 15,
                                      foreground: Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth = 6
                                        ..color = AppTheme.backgroundColor,
                                    ),
                                  ),
                                  // Solid text as fill.
                                  Text(
                                    selectedTrack != null
                                        ? '${selectedTrack.width}p'
                                        : 'Auto',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppTheme.activeButtonColor,
                                    ),
                                  ),
                                ],
                              ))
                        ],
                      ),
                    ),
                  ),
                ),
              )),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: () {
        cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0),
            child: Container(
              color: backgroundColor,
              child: Container(
                height: barHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: buttonPadding,
                ),
                child: Icon(
                  (_latestValue != null && _latestValue.volume > 0)
                      ? _controlsConfiguration.muteIcon
                      : _controlsConfiguration.unMuteIcon,
                  color: iconColor,
                  size: 16.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(
    VideoPlayerController controller,
    Color iconColor,
  ) {
    return GestureDetector(
      onTap: _onPlayPause,
      child: Icon(
        controller.value.isPlaying
            ? _controlsConfiguration.pauseIcon
            : _controlsConfiguration.playIcon,
        color: iconColor,
        size: 16.0,
      ),
    );
  }

  Widget _buildPositionOnly() {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    return Text(
      '${BetterPlayerUtils.formatDuration(position)}',
      style: _controlsConfiguration.textStyle,
    );
  }

  Widget _buildDurationOnly() {
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;
    return Text(
      '${BetterPlayerUtils.formatDuration(duration)}',
      style: _controlsConfiguration.textStyle,
    );
  }

  Widget _buildRemaining() {
    final position = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration - _latestValue.position
        : Duration(seconds: 0);

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        '-${BetterPlayerUtils.formatDuration(position)}',
        style: TextStyle(color: Colors.white, fontSize: 12.0),
      ),
    );
  }

  void back() {
    if (!betterPlayerController.isFullScreen) {
      _controlsConfiguration.exitCallBack();
    }
    Navigator.of(context).pop();
  }

  AnimatedOpacity _buildTopBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: _controlsConfiguration.controlsHideTime,
      onEnd: _onPlayerHide,
      child: SafeArea(
        child: Container(
          height: barHeight,
          child: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => back(),
                  child: Container(
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: MarqueeText(
                            text: _controlsConfiguration.text,
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                            speed: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _betterPlayerController.isLiveStream()
                    ? _controlsConfiguration.customTopBarWidget
                    : SizedBox.shrink()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextVideoWidget() {
    return StreamBuilder<int>(
      stream: _betterPlayerController.nextVideoTimeStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          return InkWell(
            onTap: () {
              _betterPlayerController.playNextVideo();
            },
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 4, right: 8),
                decoration: BoxDecoration(
                  color: _controlsConfiguration.controlBarColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    "${_betterPlayerController.translations.controlsNextVideoIn} ${snapshot.data} ...",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  @override
  void cancelAndRestartTimer() {
    _hideTimer?.cancel();

    setState(() {
      _hideStuff = false;

      _startHideTimer();
    });
    setState(() {
      _hideStuff = false;
      _displayTapped = true;
    });
  }

  Future<Null> _initialize() async {
    _controller.addListener(_updateState);

    _updateState();

    if ((_controller.value != null && _controller.value.isPlaying) ||
        _betterPlayerController.autoPlay) {
      _startHideTimer();
    }

    if (_controlsConfiguration.showControlsOnInitialize) {
      _initTimer = Timer(Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }
    _controlsVisibilityStreamSubscription =
        _betterPlayerController.controlsVisibilityStream.listen((state) {
      setState(() {
        _hideStuff = !state;
      });
      if (!_hideStuff) {
        cancelAndRestartTimer();
      }
    });
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      _betterPlayerController.toggleFullScreen();
      _expandCollapseTimer = Timer(_controlsConfiguration.controlsHideTime, () {
        setState(() {
          cancelAndRestartTimer();
        });
      });
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: SizedBox(
        height: 10,
        child: BetterPlayerCupertinoVideoProgressBar(
          _controller,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });

            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });
            _startHideTimer();
          },
          colors: BetterPlayerProgressColors(
              playedColor: _controlsConfiguration.progressBarPlayedColor,
              handleColor: _controlsConfiguration.progressBarHandleColor,
              bufferedColor: _controlsConfiguration.progressBarBufferedColor,
              backgroundColor:
                  _controlsConfiguration.progressBarBackgroundColor),
        ),
      ),
    );
  }

  void _onPlayPause() {
    bool isFinished = false;

    if (_latestValue?.position != null && _latestValue?.duration != null) {
      isFinished = _latestValue.position >= _latestValue.duration;
    }

    setState(() {
      if (_controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        _betterPlayerController.pause();
      } else {
        cancelAndRestartTimer();

        if (!_controller.value.initialized) {
          if (_betterPlayerController.betterPlayerDataSource?.liveStream ==
              true) {
            _betterPlayerController.play();
            _betterPlayerController.cancelNextVideoTimer();
          }
        } else {
          if (isFinished) {
            _betterPlayerController.seekTo(Duration(seconds: 0));
          }
          _betterPlayerController.play();
          _betterPlayerController.cancelNextVideoTimer();
        }
      }
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    if (this.mounted) {
      if (!this._hideStuff ||
          isVideoFinished(_controller.value) ||
          _wasLoading ||
          isLoading(_controller.value)) {
        setState(() {
          _latestValue = _controller.value;
          if (isVideoFinished(_latestValue)) {
            _hideStuff = false;
          }
        });
      }
    }
  }

  void _onPlayerHide() {
    _betterPlayerController.toggleControlsVisibility(!_hideStuff);
    widget.onControlsVisibilityChanged(!_hideStuff);
  }

  Widget _buildErrorWidget() {
    if (_betterPlayerController.errorBuilder != null) {
      return _betterPlayerController.errorBuilder(context,
          _betterPlayerController.videoPlayerController.value.errorDescription);
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              color: _controlsConfiguration.iconsColor,
              size: 42,
            ),
            Text(
              _betterPlayerController.translations.generalDefaultError,
              style: TextStyle(color: _controlsConfiguration.textColor),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLoadingWidget() {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(
        AppTheme.activeButtonColor,
      ),
    );
  }
}
