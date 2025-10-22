import 'dart:async';

import 'package:finamp/color_schemes.g.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutomaticAccentColorSelector extends ConsumerWidget {
  const AutomaticAccentColorSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sysColor = FinampSettingsHelper.finampSettings.systemAccentColor;

    // System does not have global color Theme Support
    if (sysColor == null) return SizedBox.shrink();

    return SwitchListTile.adaptive(
      title: Text("Use System Theme"),
      subtitle: Text("Material You"),
      value: ref.watch(finampSettingsProvider.useSystemAccentColor),
      onChanged: (value) {
        FinampSetters.setUseSystemAccentColor(value);
        unawaited(fetchSystemPalette());
      },
    );
  }
}
