import 'package:finamp/models/jellyfin_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';

import '../../components/menu_shower_toggleable_list_tile.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finamp_models.dart';
import '../../services/audio_service_helper.dart';
import '../../services/feedback_helper.dart';
import '../../services/finamp_settings_helper.dart';

List<ChoiceListTile> getRadioChoices(BuildContext context, WidgetRef ref) {
  final radioEnabled = ref.watch(finampSettingsProvider.radioEnabled);
  final radioMode = ref.watch(finampSettingsProvider.radioMode);
  return RadioMode.values
      .map((radioModeOption) {
        final disabled = !radioModeOption.availableOffline && FinampSettingsHelper.finampSettings.isOffline;
        return ChoiceListTile(
          title: AppLocalizations.of(context)!.radioModeOptionName(radioModeOption.name),
          description: disabled
              ? AppLocalizations.of(context)!.radioModeUnavailableWhileOffline
              : AppLocalizations.of(context)!.radioModeDescription(radioModeOption.name),
          disabled: disabled,
          icon: radioModeOption.icon,
          isSelected: radioEnabled && radioMode == radioModeOption,
          onSelect: () async {
            if (!disabled) {
              FinampSetters.setRadioMode(radioModeOption);
              FinampSetters.setRadioEnabled(true);
              FeedbackHelper.feedback(FeedbackType.selection);
              Navigator.of(context).pop();
              // GlobalSnackbar.message(
              //   (context) => AppLocalizations.of(context)!.radioModeOptionConfirmation(radioModeOption.name),
              //   isConfirmation: true,
              // );
            }
          },
        );
      })
      .followedBy(<ChoiceListTile>[
        ChoiceListTile(
          title: AppLocalizations.of(context)!.radioModeDisabledButtonTitle,
          icon: TablerIcons.radio_off,
          isSelected: !radioEnabled,
          disabled: false,
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

Future<void> userStartRadioPlayback(BuildContext context, WidgetRef ref, BaseItemDto baseItem) async {
  var radioMode = ref.watch(finampSettingsProvider.radioMode);
  if (!radioMode.availableOffline && FinampSettingsHelper.finampSettings.isOffline) {
    await showRadioMenu(context, ref);
  }
  radioMode = ref.watch(finampSettingsProvider.radioMode);
  if (!radioMode.availableOffline && FinampSettingsHelper.finampSettings.isOffline) {
    return;
  }
  var audioServiceHelper = GetIt.instance<AudioServiceHelper>();
  await audioServiceHelper.startRadioPlayback(QueueItemSource.fromBaseItem(baseItem));
}
