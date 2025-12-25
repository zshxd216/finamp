import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/screens/player_screen.dart';
import 'package:finamp/utils/platform_helper.dart';
import 'package:flutter/material.dart';

import 'feature_chips.dart';
import 'player_buttons.dart';
import 'progress_slider.dart';

class ControlArea extends StatelessWidget {
  const ControlArea(this.controller, {super.key});

  final PlayerHideableController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller.shouldShow(PlayerHideable.features)) const FeatureChips(),
        if (controller.shouldShow(PlayerHideable.progressSlider))
          Tooltip(
            message: AppLocalizations.of(context)!.seekControlHint(ShortcutKeyDisplay.primaryModifier),
            triggerMode: TooltipTriggerMode.tap,
            child: const ProgressSlider(),
          ),
        PlayerButtons(controller),
      ],
    );
  }
}
