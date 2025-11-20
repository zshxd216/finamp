import 'package:finamp/menus/components/radio_mode_menu.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/services/feedback_helper.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/media_state_stream.dart';
import 'package:finamp/services/music_player_background_task.dart';
import 'package:finamp/services/queue_service.dart';
import 'package:finamp/services/radio_service_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:finamp/l10n/app_localizations.dart';

class PlayerButtonsLoopMode extends ConsumerWidget {
  final audioHandler = GetIt.instance<MusicPlayerBackgroundTask>();
  final queueService = GetIt.instance<QueueService>();

  PlayerButtonsLoopMode({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueService = GetIt.instance<QueueService>();
    final queueSource = queueService.getQueue().source.item;
    final radioSeedItem = getRadioSeedItem(queueSource);

    final radioMode = ref.watch(finampSettingsProvider.radioMode);
    final radioActive = ref.watch(isRadioCurrentlyActiveProvider(radioSeedItem));

    IconData getRepeatingIcon(FinampLoopMode loopMode) {
      if (radioActive) {
        return TablerIcons.radio;
      }
      if (loopMode == FinampLoopMode.all) {
        return TablerIcons.repeat;
      } else if (loopMode == FinampLoopMode.one) {
        return TablerIcons.repeat_once;
      } else {
        return TablerIcons.repeat_off;
      }
    }

    String getLocalizedLoopMode(BuildContext context, FinampLoopMode loopMode) {
      if (radioActive) {
        return AppLocalizations.of(context)!.radioModeOptionTitle(radioMode.name);
      }
      switch (loopMode) {
        case FinampLoopMode.all:
          return AppLocalizations.of(context)!.loopModeAllButtonLabel;
        case FinampLoopMode.one:
          return AppLocalizations.of(context)!.loopModeOneButtonLabel;
        case FinampLoopMode.none:
          return AppLocalizations.of(context)!.loopModeNoneButtonLabel;
      }
    }

    return StreamBuilder(
      stream: queueService.getLoopModeStream(),
      initialData: queueService.loopMode,
      builder: (BuildContext context, snapshot) {
        return IconButton(
          tooltip:
              "${getLocalizedLoopMode(context, snapshot.data!)}. ${AppLocalizations.of(context)!.genericToggleButtonTooltip}",
          onPressed: () async {
            FeedbackHelper.feedback(FeedbackType.light);
            queueService.toggleLoopMode();
          },
          onLongPress: radioActive ? () => showRadioMenu(context) : null,
          icon: Icon(getRepeatingIcon(snapshot.data!)),
        );
      },
    );
  }
}
