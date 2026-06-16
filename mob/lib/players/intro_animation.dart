import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class IntroAnimation extends StatefulWidget {
  const IntroAnimation({super.key});

  @override
  State<IntroAnimation> createState() => _IntroAnimationState();
}

class _IntroAnimationState extends State<IntroAnimation> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.asset('assets/animations/intro.mp4')
      ..initialize().then((_) {
        setState(() {});
        controller.setVolume(0);
        controller.play();
        controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    controller.dispose();
    controller.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    );
  }
}
