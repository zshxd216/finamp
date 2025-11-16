import 'dart:async';

import 'package:finamp/components/choice_menu.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/services/audio_service_helper.dart';
import 'package:finamp/services/downloads_service.dart';
import 'package:finamp/services/feedback_helper.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/queue_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';

List<ChoiceMenuOption> getRadioChoices(BuildContext context, WidgetRef ref) {
  final queueService = GetIt.instance<QueueService>();
  final queueSource = queueService.getQueue().source.item;

  final radioEnabled = ref.watch(finampSettingsProvider.radioEnabled);
  final radioMode = ref.watch(finampSettingsProvider.radioMode);
  final randomModeAvailable = ref.watch(isRandomRadioModeAvailableProvider(queueSource));
  final currentModeAvailable = ref.watch(isRadioModeAvailableProvider((radioMode, queueSource)));

  return RadioMode.values
      .map((radioModeOption) {
        final radioModeOptionEnabled = ref.watch(isRadioModeAvailableProvider((radioModeOption, queueSource)));
        return ChoiceMenuOption(
          title: AppLocalizations.of(context)!.radioModeOptionName(radioModeOption.name),
          description: radioModeOptionEnabled
              ? AppLocalizations.of(context)!.radioModeDescription(radioModeOption.name)
              : (radioModeOption == RadioMode.random && !randomModeAvailable)
              ? AppLocalizations.of(context)!.radioModeRandomUnavailableNotDownloaded(queueSource?.name ?? "")
              : AppLocalizations.of(context)!.radioModeUnavailableWhileOffline,
          enabled: radioModeOptionEnabled,
          icon: radioModeOption.icon,
          isSelected: radioEnabled && currentModeAvailable && radioMode == radioModeOption,
          onSelect: () {
            FinampSetters.setRadioMode(radioModeOption);
            FinampSetters.setRadioEnabled(true);
            unawaited(queueService.clearRadioTracks());
            FeedbackHelper.feedback(FeedbackType.selection);
            Navigator.of(context).pop();
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
  var radioMode = FinampSettingsHelper.finampSettings.radioMode;
  var currentRadioModeAvailable = ref.read(isRadioModeAvailableProvider((radioMode, baseItem)));
  if (!currentRadioModeAvailable) {
    await showRadioMenu(context, ref);
  }
  radioMode = FinampSettingsHelper.finampSettings.radioMode;
  currentRadioModeAvailable = ref.read(isRadioModeAvailableProvider((radioMode, baseItem)));
  if (!currentRadioModeAvailable) {
    return;
  }
  var audioServiceHelper = GetIt.instance<AudioServiceHelper>();
  await audioServiceHelper.startRadioPlayback(QueueItemSource.fromBaseItem(baseItem));
}

final isRadioModeAvailableProvider = ProviderFamily<bool, (RadioMode, BaseItemDto?)>((
  ref,
  (RadioMode radioMode, BaseItemDto? baseItem) arguments,
) {
  final radioMode = arguments.$1;
  final source = arguments.$2;

  final randomModeAvailable = ref.watch(isRandomRadioModeAvailableProvider(source));
  final albumMixModeAvailable = ref.watch(isAlbumMixRadioModeAvailableProvider(source));
  final currentModeAvailable =
      (radioMode.availableOffline &&
          (radioMode != RadioMode.random || randomModeAvailable) &&
          (radioMode != RadioMode.albumMix || albumMixModeAvailable)) ||
      !ref.watch(finampSettingsProvider.isOffline);
  return currentModeAvailable;
});

final isRandomRadioModeAvailableProvider = ProviderFamily<bool, BaseItemDto?>((ref, BaseItemDto? baseItem) {
  final downloadsService = GetIt.instance<DownloadsService>();

  final randomModeAvailable =
      (RadioMode.random.availableOffline && ref.watch(finampSettingsProvider.isOffline)) &&
      (baseItem != null &&
          ref
              .watch(
                downloadsService.statusProvider((
                  DownloadStub.fromItem(type: baseItem.downloadType, item: baseItem),
                  null,
                )),
              )
              .isDownloaded);
  return randomModeAvailable;
});

final isAlbumMixRadioModeAvailableProvider = ProviderFamily<bool, BaseItemDto?>((ref, BaseItemDto? baseItem) {
  final albumMixModeAvailable =
      (RadioMode.albumMix.availableOffline && !ref.watch(finampSettingsProvider.isOffline)) &&
      baseItem != null &&
      BaseItemDtoType.fromItem(baseItem) == BaseItemDtoType.album;
  return albumMixModeAvailable;
});
