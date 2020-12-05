import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HlsTracksPage extends StatefulWidget {
  @override
  _HlsTracksPageState createState() => _HlsTracksPageState();
}

class _HlsTracksPageState extends State<HlsTracksPage> {
  BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      controlsConfiguration: BetterPlayerControlsConfiguration(
          rotateWidget: SvgPicture.asset(
            'assets/rotate_video.svg',
          ),
          qualityIcon: SvgPicture.asset(
            'assets/video_quality.svg',
            height: 20,
            width: 20,
          ),
          textStyle: TextStyle(
              color: Colors.white, fontFamily: 'Avenir', fontSize: 15),
          customTopBarWidget: Text(
            'tetxt',
            style: TextStyle(fontSize: 16, color: Colors.white),
          )),
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.NETWORK,
        'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8',
        useHlsSubtitles: true);
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BetterPlayer(controller: _betterPlayerController),
        ],
      ),
    );
  }
}
