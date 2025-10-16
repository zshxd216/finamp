import 'package:finamp/services/finamp_settings_helper.dart';

String? getLocaleString() {
  final locale = FinampSettingsHelper.finampSettings.locale;
  return locale != null
      ? (locale.countryCode != null
            ? "${locale.languageCode.toLowerCase()}_${locale.countryCode?.toUpperCase()}"
            : locale.toString())
      : null;
}
