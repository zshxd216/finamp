import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:flutter/material.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension LocalisedName on ThemeMode {
  String toLocalisedString(BuildContext context) => _humanReadableLocalisedName(this, context);

  String _humanReadableLocalisedName(ThemeMode themeMode, BuildContext context) {
    switch (themeMode) {
      case ThemeMode.system:
        return AppLocalizations.of(context)!.system;
      case ThemeMode.light:
        return AppLocalizations.of(context)!.light;
      case ThemeMode.dark:
        return AppLocalizations.of(context)!.dark;
    }
  }
}

class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(finampSettingsProvider.themeMode);
    return ListTile(
      title: Text(AppLocalizations.of(context)!.theme),
      trailing: DropdownButton<ThemeMode>(
        value: themeMode,
        items: ThemeMode.values
            .map((e) => DropdownMenuItem<ThemeMode>(value: e, child: Text(e.toLocalisedString(context))))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            FinampSetters.setThemeMode(value);
          }
        },
      ),
    );
  }
}
