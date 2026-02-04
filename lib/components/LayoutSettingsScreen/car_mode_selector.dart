import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import '../../services/car_mode_helper.dart';
import '../../services/finamp_settings_helper.dart';

class CarModeSelector extends StatelessWidget {
  const CarModeSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final carModeHelper = GetIt.instance<CarModeHelper>();

    return SwitchListTile(
      title: const Text('Car Mode'),
      subtitle: const Text('Enable larger UI elements optimized for car displays'),
      value: FinampSettingsHelper.finampSettings.enableCarMode,
      onChanged: (value) {
        FinampSettingsHelper.setEnableCarMode(value);
        carModeHelper.toggleCarMode(value);
      },
    );
  }
}
