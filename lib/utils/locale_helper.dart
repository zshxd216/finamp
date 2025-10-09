import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

// Only to be used when you have no WidgetRef
Locale? getLocale() {
  return GetIt.instance<ProviderContainer>().read(finampSettingsProvider.locale);
}

String? getLocaleString() {
  final locale = getLocale();
  return locale != null
      ? (locale.countryCode != null
            ? "${locale.languageCode.toLowerCase()}_${locale.countryCode?.toUpperCase()}"
            : locale.toString())
      : null;
}
