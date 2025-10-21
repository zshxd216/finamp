import 'package:finamp/color_schemes.g.dart';
import 'package:finamp/extensions/color_extensions.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/widget_bindings_observer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class FinampIcon extends ConsumerWidget {
  final double height;
  final double width;
  const FinampIcon(this.width, this.height, {super.key});

  String _getColoredSvg(ColorScheme scheme) {
    Color c = scheme.primary;
    String cstr = c.toHex();

    return '''<svg width="1024" height="1024" viewBox="0 0 1024 1024" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M714.529 446.555C723.715 468.075 705.091 496.347 630.419 574.243C550.375 657.745 527.954 672.343 494.87 662.493C461.781 652.644 450.992 628.162 429.643 514.478C397.081 341.096 408.151 331.222 578.394 381.894C664.658 407.572 706.343 427.379 714.529 446.555Z" fill="$cstr" fill-opacity="0.97647"/>
<path d="M714.529 446.555C723.715 468.075 705.091 496.347 630.419 574.243C550.375 657.745 527.954 672.343 494.87 662.493C461.781 652.644 450.992 628.162 429.643 514.478C397.081 341.096 408.151 331.222 578.394 381.894C664.658 407.572 706.343 427.379 714.529 446.555Z" fill="url(#paint0_linear_2111_18575)"/>
<path d="M328.327 981.999C512.498 769.508 37.2345 154.135 515.922 233.788C574.611 242.892 624.828 246.977 710.922 238.42C830.701 166.298 817.98 145.145 895 72.3472C501.958 77.1111 650.674 101.298 434.486 64.238C362.004 51.8126 255.113 22.3151 186.481 62.0322C111.95 105.162 129.258 240.433 134.543 311.906C149.935 520.03 183.782 822.738 328.31 982" fill="$cstr"/>
<path d="M328.327 981.999C512.498 769.508 37.2345 154.135 515.922 233.788C574.611 242.892 624.828 246.977 710.922 238.42C830.701 166.298 817.98 145.145 895 72.3472C501.958 77.1111 650.674 101.298 434.486 64.238C362.004 51.8126 255.113 22.3151 186.481 62.0322C111.95 105.162 129.258 240.433 134.543 311.906C149.935 520.03 183.782 822.738 328.31 982" fill="url(#paint1_linear_2111_18575)"/>
<defs>
<linearGradient id="paint0_linear_2111_18575" x1="714.565" y1="446.537" x2="528.174" y2="481.259" gradientUnits="userSpaceOnUse">
<stop stop-color="$cstr"/>
<stop offset="1" stop-color="$cstr" stop-opacity="0"/>
</linearGradient>
<linearGradient id="paint1_linear_2111_18575" x1="783.228" y1="484.384" x2="278.88" y2="516.201" gradientUnits="userSpaceOnUse">
<stop stop-color="$cstr"/>
<stop offset="1" stop-color="$cstr" stop-opacity="0"/>
</linearGradient>
</defs>
</svg>''';
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(finampSettingsProvider.accentColor);

    if (accent==null) {
      return SvgPicture.asset(
        "images/finamp_cropped.svg",
        width: width,
        height: height
      );
    }

    final brightness = ref.watch(brightnessProvider);
    final colorScheme = getColorScheme(accent, brightness);

    return SvgPicture.string(
      _getColoredSvg(colorScheme),
      width: width,
      height: height,
    );

  }
}
