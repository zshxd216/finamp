import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeAirPlayButton extends StatelessWidget {
  const NativeAirPlayButton({
    Key? key,
    this.size = 28,
    this.tintColor,
  }) : super(key: key);

  final double size;
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: size,
      height: size,
      child: UiKitView(
        viewType: "airplay_route_picker",
        creationParams: {
          if (tintColor != null) "tintColor": tintColor!.value,
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}
