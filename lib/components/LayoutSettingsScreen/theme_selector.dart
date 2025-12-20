import 'package:finamp/components/SettingsScreen/finamp_settings_dropdown.dart';
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
      subtitle: FinampSettingsDropdown<ThemeMode>(
        dropdownItems: ThemeMode.values
            .map((e) => DropdownMenuEntry<ThemeMode>(value: e, label: e.toLocalisedString(context)))
            .toList(),
        selectedValue: themeMode,
        onSelected: (value) {
          if (value != null) {
            FinampSetters.setThemeMode(value);
          }
        },
      ),
    );
  }
}
