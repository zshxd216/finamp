import 'dart:async';
import 'dart:io';

import 'package:finamp/components/themed_bottom_sheet.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/menus/choice_menu.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/services/feedback_helper.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/queue_service.dart';
import 'package:finamp/services/radio_service_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';

Future<void> showRadioMenu(BuildContext context, {BaseItemDto? seedItem, String? subtitle}) async {
  // await showChoiceMenu(
  //   context: context,
  //   routeName: "/radio-menu",
  //   title: AppLocalizations.of(context)!.radioModeMenuTitle,
  //   subtitle: subtitle,
  //   themeItem: seedItem,
  //   listEntries: getRadioChoices(context, ref),
  //   // listEntries: [],
  // );
  final queueService = GetIt.instance<QueueService>();

  final List<Widget> menuItems = RadioMode.values
      .map<Widget>((radioModeOption) {
        return Consumer(
          builder: (context, ref, child) {
            final currentRadioMode = ref.watch(finampSettingsProvider.radioMode);
            final modeSeed = seedItem ?? ref.watch(getActiveRadioSeedProvider(radioModeOption));
            final radioModeOptionEnabled = ref.watch(isRadioModeAvailableProvider((radioModeOption, modeSeed)));
            final radioCurrentlyActive = ref.watch(isRadioCurrentlyActiveProvider);
            return ChoiceMenuOption(
              title: AppLocalizations.of(context)!.radioModeOptionName(radioModeOption.name),
              description: radioModeOptionEnabled
                  ? AppLocalizations.of(context)!.radioModeDescription(radioModeOption.name)
                  : (radioModeOption == RadioMode.random && !radioModeOptionEnabled)
                  ? modeSeed?.name != null
                        ? AppLocalizations.of(context)!.radioModeRandomUnavailableNotDownloaded(modeSeed!.name!)
                        : AppLocalizations.of(context)!.radioModeRandomUnavailableNotDownloadedGeneric
                  : AppLocalizations.of(context)!.radioModeUnavailableWhileOffline,
              badges: [
                // similar mode is recommended
                if (radioModeOption == RadioMode.similar && radioModeOptionEnabled) Icon(TablerIcons.star, size: 14.0),
              ],
              enabled: radioModeOptionEnabled,
              icon: getRadioModeIcon(radioModeOption),
              isDisabled: !radioCurrentlyActive,
              isSelected: currentRadioMode == radioModeOption,
              onSelect: () async {
                FinampSetters.setRadioMode(radioModeOption);
                if (seedItem != null) {
                  unawaited(startRadioPlayback(seedItem));
                } else {
                  toggleRadio(true);
                }
                FeedbackHelper.feedback(FeedbackType.selection);
                await Future<void>.delayed(const Duration(milliseconds: 400));
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            );
          },
        );
      })
      .followedBy(<Widget>[
        Divider(height: 8.0, thickness: 1.5, indent: 20.0, endIndent: 20.0, radius: BorderRadius.circular(2.0)),
        Consumer(
          builder: (context, ref, child) {
            return ChoiceMenuOption(
              title: AppLocalizations.of(context)!.radioModeDisabledButtonTitle,
              icon: TablerIcons.radio_off,
              isSelected: !ref.watch(isRadioCurrentlyActiveProvider),
              enabled: true,
              onSelect: () async {
                toggleRadio(false);
                FeedbackHelper.feedback(FeedbackType.selection);
                await Future<void>.delayed(const Duration(milliseconds: 400));
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            );
          },
        ),
      ])
      .toList();

  await showThemedBottomSheet(
    context: context,
    item: seedItem ?? queueService.getCurrentTrack()?.baseItem,
    routeName: "/radio-menu",
    minDraggableHeight: 0.25,
    buildSlivers: (context) {
      var menu = [
        SliverStickyHeader(
          header: Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 8.0, left: 16.0, right: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2.0,
              children: [
                Text(AppLocalizations.of(context)!.radioModeMenuTitle, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null) Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          sliver: MenuMask(
            height: MenuMaskHeight(36.0),
            child: SliverList.list(children: menuItems),
          ),
        ),
      ];
      // header + menu entries
      var stackHeight = 42.0 + menuItems.length * ((Platform.isAndroid || Platform.isIOS) ? 72.0 : 64.0);
      return (stackHeight, menu);
    },
  );
}
