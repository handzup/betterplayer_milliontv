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
      autoPlay: false,
      controlsConfiguration: BetterPlayerControlsConfiguration(
          exitCallBack: exit,
          skipAheadIcon: SvgPicture.asset(
            'assets/skip_15_seconds_back.svg',
          ),
          skipIcon: SvgPicture.asset(
            'assets/skip_ahead_15_seconds.svg',
          ),
          fullScreenWidget: SvgPicture.asset(
            'assets/full_screen.svg',
          ),
          exitFullScreenWidget: SvgPicture.asset(
            'assets/exit_full_screen.svg',
          ),
          qualityIcon: SvgPicture.asset(
            'assets/video_quality.svg',
            height: 20,
            width: 20,
          ),
          textStyle: TextStyle(
              color: Colors.white, fontFamily: 'Avenir', fontSize: 15),
          text: 'Text sadasd some long long long long long long text',
          customTopBarWidget: Text(
            'tetxt',
            style: TextStyle(fontSize: 16, color: Colors.white),
          )),
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.NETWORK,

      // Constants.exampleResolutionsUrls.values.first,
      // resolutions: Constants.exampleResolutionsUrls,
      //'http://sample.vodobox.com/skate_phantom_flex_4k/skate_phantom_flex_4k.m3u8',
      '',
      liveStream: true,
      //  useHlsSubtitles: true
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  void exit() {
    print(
        _betterPlayerController.videoPlayerController.value.position.inSeconds);
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
