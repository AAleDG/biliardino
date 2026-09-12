import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// One cached image handle for the profile's hero and footer; never owns storage.
class ProfileScene extends StatefulWidget {
  const ProfileScene({super.key, required this.builder});
  final Widget Function(BuildContext context, ui.Image? scene) builder;
  static const asset = 'design/south-africa-2010/assets/live-r1/live-scene.png';

  @override
  State<ProfileScene> createState() => _ProfileSceneState();
}

class _ProfileSceneState extends State<ProfileScene> {
  ImageStream? _stream;
  ImageInfo? _image;
  late final _listener = ImageStreamListener((image, _) {
    if (!mounted) {
      image.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = image;
    });
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage(
      ProfileScene.asset,
    ).resolve(createLocalImageConfiguration(context));
    if (_stream?.key != stream.key) {
      _stream?.removeListener(_listener);
      _stream = stream..addListener(_listener);
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _image?.image);
}
