import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/menus/components/menuEntries/menu_entry.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/services/favorite_provider.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/item_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';

import '../../../services/audio_service_helper.dart';
import '../../../services/queue_service.dart';
import '../radio_mode_menu.dart';

class StartRadioMenuEntry extends ConsumerWidget implements HideableMenuEntry {
  final BaseItemDto baseItem;

  const StartRadioMenuEntry({super.key, required this.baseItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuEntry(
      icon: TablerIcons.radio,
      title: AppLocalizations.of(context)!.startRadio,
      onTap: () async {
        await userStartRadioPlayback(context, ref, baseItem);
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  bool get isVisible => !FinampSettingsHelper.finampSettings.isOffline;
}
