import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../models/finamp_models.dart';
import '../../services/finamp_settings_helper.dart';

class UniversalSearchToggle extends StatelessWidget {
  const UniversalSearchToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<FinampSettings>>(
      valueListenable: FinampSettingsHelper.finampSettingsListener,
      builder: (context, box, _) {
        final useUniversalSearch =
            box.get("FinampSettings")?.useUniversalSearch ?? true;

        return SwitchListTile.adaptive(
          title: Text(AppLocalizations.of(context)!.universalSearch),
          subtitle: Text(
              AppLocalizations.of(context)!.universalSearchDescription),
          value: useUniversalSearch,
          onChanged: (value) {
            FinampSettingsHelper.setUseUniversalSearch(value);
          },
        );
      },
    );
  }
}
