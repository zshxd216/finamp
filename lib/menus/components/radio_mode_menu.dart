import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../components/choosable_toggleable_list_tile.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finamp_models.dart';
import '../../services/feedback_helper.dart';
import '../../services/finamp_settings_helper.dart';

List<ChoiceListTile> getRadioChoices(BuildContext context, WidgetRef ref) {
  final radioEnabled = ref.watch(finampSettingsProvider.radioEnabled);
  final radioMode = ref.watch(finampSettingsProvider.radioMode);
  return RadioMode.values
      .map(
        (radioModeOption) => ChoiceListTile(
      title: AppLocalizations.of(context)!.radioModeOptionName(radioModeOption.name),
      description: AppLocalizations.of(context)!.radioModeDescription(radioModeOption.name),
      icon: radioModeOption.icon,
      isSelected: radioEnabled && radioMode == radioModeOption,
      onSelect: () async {
        FinampSetters.setRadioMode(radioModeOption);
        FinampSetters.setRadioEnabled(true);
        FeedbackHelper.feedback(FeedbackType.selection);
        Navigator.of(context).pop();
        // GlobalSnackbar.message(
        //   (context) => AppLocalizations.of(context)!.radioModeOptionConfirmation(radioModeOption.name),
        //   isConfirmation: true,
        // );
      },
    ),
  )
      .followedBy(<ChoiceListTile>[
    ChoiceListTile(
      title: AppLocalizations.of(context)!.radioModeDisabledButtonTitle,
      icon: TablerIcons.radio_off,
      isSelected: !radioEnabled,
      onSelect: () async {
        FinampSetters.setRadioEnabled(false);
        FeedbackHelper.feedback(FeedbackType.selection);
        Navigator.of(context).pop();
        // GlobalSnackbar.message(
        //   (context) => AppLocalizations.of(context)!.radioModeDisabledTitle,
        //   isConfirmation: true,
        // );
      },
    ),
  ])
      .toList();
}

Future<void> showRadioMenu(BuildContext context, WidgetRef ref, [String? subtitle]) async {
  FeedbackHelper.feedback(FeedbackType.selection);
  await showChoiceMenu(
    context: context,
    title: AppLocalizations.of(context)!.radioModeMenuTitle,
    subtitle: subtitle,
    usePlayerTheme: true,
    listEntries: getRadioChoices(context, ref),
  );
}