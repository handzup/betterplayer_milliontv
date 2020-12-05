import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/hls/better_player_hls_track.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/material.dart';

///Base class for both material and cupertino controls
abstract class BetterPlayerControlsState<T extends StatefulWidget>
    extends State<T> {
  ///Min. time of buffered video to hide loading timer (in milliseconds)
  static const int _bufferingInterval = 20000;

  BetterPlayerController get betterPlayerController;

  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration;

  VideoPlayerValue get latestValue;

  void cancelAndRestartTimer();

  bool isVideoFinished(VideoPlayerValue videoPlayerValue) {
    return videoPlayerValue?.position != null &&
        videoPlayerValue?.duration != null &&
        videoPlayerValue.position >= videoPlayerValue.duration;
  }

  void skipBack() {
    cancelAndRestartTimer();
    final beginning = Duration(seconds: 0).inMilliseconds;
    final skip = (latestValue.position -
            Duration(
                milliseconds:
                    betterPlayerControlsConfiguration.skipsTimeInMilliseconds))
        .inMilliseconds;
    betterPlayerController.seekTo(Duration(milliseconds: max(skip, beginning)));
  }

  void skipForward() {
    cancelAndRestartTimer();
    final end = latestValue.duration.inMilliseconds;
    final skip = (latestValue.position +
            Duration(
                milliseconds:
                    betterPlayerControlsConfiguration.skipsTimeInMilliseconds))
        .inMilliseconds;
    betterPlayerController.seekTo(Duration(milliseconds: min(skip, end)));
  }

  void onShowMoreClicked() {
    _showQualitiesSelectionWidget();
  }

  Widget _buildMoreOptionsList() {
    var translations = betterPlayerController.translations;
    return SingleChildScrollView(
      child: Container(
        child: Column(
          children: [
 
            if (betterPlayerControlsConfiguration.enableQualities)
              _buildMoreOptionsListRow(
                  betterPlayerControlsConfiguration.qualitiesIcon,
                  translations.overflowMenuQuality, () {
                Navigator.of(context).pop();
                _showQualitiesSelectionWidget();
              }),
            
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOptionsListRow(IconData icon, String name, Function onTap) {
    assert(icon != null, "Icon can't be null");
    assert(name != null, "Name can't be null");
    assert(onTap != null, "OnTap can't be null");
    return BetterPlayerMaterialClickableWidget(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: betterPlayerControlsConfiguration.overflowMenuIconsColor,
            ),
            const SizedBox(width: 16),
            Text(name),
          ],
        ),
      ),
    );
  }

  void _showSpeedChooserWidget() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            top: false,
            bottom: true,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSpeedRow(0.25),
                  _buildSpeedRow(0.5),
                  _buildSpeedRow(0.75),
                  _buildSpeedRow(1.0),
                  _buildSpeedRow(1.25),
                  _buildSpeedRow(1.5),
                  _buildSpeedRow(1.75),
                  _buildSpeedRow(2.0),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildSpeedRow(double value) {
    assert(value != null, "Value can't be null");
    return BetterPlayerMaterialClickableWidget(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              "$value x",
              style: TextStyle(
                  fontWeight: betterPlayerController
                              .videoPlayerController.value.speed ==
                          value
                      ? FontWeight.bold
                      : FontWeight.normal),
            )
          ],
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController.setSpeed(value);
      },
    );
  }

  ///Latest value can be null
  bool isLoading(VideoPlayerValue latestValue) {
    if (latestValue != null) {
      if (!latestValue.isPlaying && latestValue.duration == null) {
        return true;
      }

      Duration position = latestValue.position;

      Duration bufferedEndPosition;
      if (latestValue.buffered?.isNotEmpty == true) {
        bufferedEndPosition = latestValue.buffered.last.end;
      }

      if (position != null && bufferedEndPosition != null) {
        var difference = bufferedEndPosition - position;

        if (latestValue.isPlaying &&
            latestValue.isBuffering &&
            difference.inMilliseconds < _bufferingInterval) {
          return true;
        }
      }
    }
    return false;
  }

  void _showSubtitlesSelectionWidget() {
    var subtitles =
        List.of(betterPlayerController.betterPlayerSubtitlesSourceList);
    var noneSubtitlesElementExists = subtitles?.firstWhere(
            (source) => source.type == BetterPlayerSubtitlesSourceType.NONE,
            orElse: () => null) !=
        null;
    if (!noneSubtitlesElementExists) {
      subtitles?.add(BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.NONE));
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          top: false,
          bottom: true,
          child: SingleChildScrollView(
            child: Column(
              children: subtitles
                  .map((source) => _buildSubtitlesSourceRow(source))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitlesSourceRow(BetterPlayerSubtitlesSource subtitlesSource) {
    assert(subtitlesSource != null, "SubtitleSource can't be null");

    var selectedSourceType = betterPlayerController.betterPlayerSubtitlesSource;
    bool isSelected = (subtitlesSource == selectedSourceType) ||
        (subtitlesSource.type == BetterPlayerSubtitlesSourceType.NONE &&
            subtitlesSource?.type == selectedSourceType.type);

    return BetterPlayerMaterialClickableWidget(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              subtitlesSource.type == BetterPlayerSubtitlesSourceType.NONE
                  ? betterPlayerController.translations.generalNone
                  : subtitlesSource.name ??
                      betterPlayerController.translations.generalDefault,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController.setupSubtitleSource(subtitlesSource);
      },
    );
  }

  ///Build both track and resolution selection
  ///Track selection is used for HLS videos
  ///Resolution selection is used for normal videos
  void _showQualitiesSelectionWidget() {
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

    if (children.isEmpty) {
      children.add(_buildTrackRow(BetterPlayerHlsTrack(0, 0, 0),
          betterPlayerController.translations.generalDefault));
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          top: false,
          bottom: true,
          child: SingleChildScrollView(
            child: Column(
              children: children,
            ),
          ),
        );
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
}
