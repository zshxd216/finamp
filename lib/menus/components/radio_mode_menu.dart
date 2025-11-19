import 'dart:async';

import 'package:finamp/menus/choice_menu.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/services/audio_service_helper.dart';
import 'package:finamp/services/feedback_helper.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/queue_service.dart';
import 'package:finamp/services/radio_service_helper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';

List<ChoiceMenuOption> getRadioChoices(BuildContext context, WidgetRef ref) {
  final queueService = GetIt.instance<QueueService>();
  final queueSource = queueService.getQueue().source.item;
  final radioSeedItem = getRadioSeedItem(queueSource);

  final radioEnabled = ref.watch(finampSettingsProvider.radioEnabled);
  final radioMode = ref.watch(finampSettingsProvider.radioMode);
  final randomModeAvailable = ref.watch(isRandomRadioModeAvailableProvider(queueSource));
  final currentModeAvailable = ref.watch(isRadioModeAvailableProvider((radioMode, radioSeedItem)));

  return RadioMode.values
      .map((radioModeOption) {
        final radioModeOptionEnabled = ref.watch(isRadioModeAvailableProvider((radioModeOption, radioSeedItem)));
        return ChoiceMenuOption(
          title: AppLocalizations.of(context)!.radioModeOptionName(radioModeOption.name),
          description: radioModeOptionEnabled
              ? AppLocalizations.of(context)!.radioModeDescription(radioModeOption.name)
              : (radioModeOption == RadioMode.random && !randomModeAvailable)
              ? AppLocalizations.of(context)!.radioModeRandomUnavailableNotDownloaded(radioSeedItem.name ?? "")
              : AppLocalizations.of(context)!.radioModeUnavailableWhileOffline,
          badges: [
            // similar mode is recommended
            if (radioModeOption == RadioMode.similar) Icon(TablerIcons.star, size: 14.0),
          ],
          enabled: radioModeOptionEnabled,
          icon: getRadioModeIcon(radioModeOption),
          isSelected: radioEnabled && currentModeAvailable && radioMode == radioModeOption,
          onSelect: () async {
            FinampSetters.setRadioMode(radioModeOption);
            FinampSetters.setRadioEnabled(true);
            FeedbackHelper.feedback(FeedbackType.selection);
            Navigator.of(context).pop();
            unawaited(queueService.clearRadioTracks());
            // GlobalSnackbar.message(
            //   (context) => AppLocalizations.of(context)!.radioModeOptionConfirmation(radioModeOption.name),
            //   isConfirmation: true,
            // );
          },
        );
      })
      .followedBy(<ChoiceMenuOption>[
        ChoiceMenuOption(
          title: AppLocalizations.of(context)!.radioModeDisabledButtonTitle,
          icon: TablerIcons.radio_off,
          isSelected: !radioEnabled || !currentModeAvailable,
          enabled: true,
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

Future<void> showRadioMenu(BuildContext context, WidgetRef ref, {BaseItemDto? seedItem, String? subtitle}) async {
  await showChoiceMenu(
    context: context,
    routeName: "/radio-menu",
    title: AppLocalizations.of(context)!.radioModeMenuTitle,
    subtitle: subtitle,
    themeItem: seedItem,
    listEntries: getRadioChoices(context, ref),
    // listEntries: [],
  );
}

Future<void> userStartRadioPlayback(BuildContext context, WidgetRef ref, BaseItemDto baseItem) async {
  final radioMode = FinampSettingsHelper.finampSettings.radioMode;
  // await showRadioMenu(context, ref, seedItem: baseItem); //FIXME this throws an error when trying to dismiss
  final currentRadioModeAvailable = ref.read(isRadioModeAvailableProvider((radioMode, baseItem)));
  if (!currentRadioModeAvailable) {
    return;
  }
  var audioServiceHelper = GetIt.instance<AudioServiceHelper>();
  await audioServiceHelper.startRadioPlayback(baseItem);
}
