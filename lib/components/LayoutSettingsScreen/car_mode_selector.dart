import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../services/car_mode_helper.dart';
import '../../services/finamp_settings_helper.dart';

class CarModeSelector extends StatelessWidget {
  const CarModeSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final carModeHelper = GetIt.instance<CarModeHelper>();

    return SwitchListTile(
      title: Text(AppLocalizations.of(context)!.carMode),
      subtitle: Text(AppLocalizations.of(context)!.carModeDescription),
      value: FinampSettingsHelper.finampSettings.enableCarMode,
      onChanged: (value) {
        FinampSettingsHelper.setEnableCarMode(value);
        carModeHelper.toggleCarMode(value);
      },
    );
  }
}
