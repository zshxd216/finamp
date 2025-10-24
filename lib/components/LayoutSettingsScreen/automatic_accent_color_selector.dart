import 'dart:async';
import 'dart:io';
import 'package:finamp/color_schemes.g.dart';
import 'package:finamp/extensions/color_extensions.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutomaticAccentColorSelector extends ConsumerWidget {
  const AutomaticAccentColorSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sysColor = ref.watch(finampSettingsProvider.systemAccentColor);

    // Safe to assume that the System does not have Color Theme Support
    final supportsSystemTheme = Platform.isAndroid || Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    if (!supportsSystemTheme) return SizedBox.shrink();

    return ListTile(
      title: Text(AppLocalizations.of(context)!.systemAccentColor(Platform.operatingSystem)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            sysColor?.toHex() ?? "",
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 16),
          Switch.adaptive(
            value: ref.watch(finampSettingsProvider.useSystemAccentColor),
            inactiveThumbColor: sysColor,
            onChanged: (value) {
              FinampSetters.setUseSystemAccentColor(value);
              unawaited(fetchSystemPalette());
            },
          ),
        ],
      ),
    );
  }
}
