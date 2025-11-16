import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/menus/components/menuEntries/menu_entry.dart';
import 'package:finamp/menus/components/radio_mode_menu.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/services/downloads_service.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/queue_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';

class StartRadioMenuEntry extends ConsumerWidget implements HideableMenuEntry {
  final BaseItemDto baseItem;

  const StartRadioMenuEntry({super.key, required this.baseItem});

  bool get visible {
    final providers = GetIt.instance<ProviderContainer>();
    final radioMode = providers.read(finampSettingsProvider.radioMode);
    return providers.read(isRadioModeAvailableProvider((radioMode, baseItem)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioMode = ref.watch(finampSettingsProvider.radioMode);
    return Visibility(
      visible: ref.watch(isRadioModeAvailableProvider((radioMode, baseItem))),
      child: MenuEntry(
        icon: TablerIcons.radio,
        title: AppLocalizations.of(context)!.startRadio,
        onTap: () async {
          await userStartRadioPlayback(context, ref, baseItem);
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  bool get isVisible => visible;
}
