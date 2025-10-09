import 'dart:collection';

import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:flutter/material.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locale_names/locale_names.dart';

import '../padded_custom_scrollview.dart';

class LanguageList extends ConsumerStatefulWidget {
  const LanguageList({super.key});

  @override
  ConsumerState<LanguageList> createState() => _LanguageListState();
}

class _LanguageListState extends ConsumerState<LanguageList> {
  // yeah I'm a computer science student how could you tell
  // (sorts locales without having to copy them into a list first)
  final locales = SplayTreeMap<String?, Locale>.fromIterable(
    AppLocalizations.supportedLocales,
    key: (element) => (element as Locale).toLanguageTag(),
    value: (element) => element as Locale,
  );

  @override
  Widget build(BuildContext context) {
    ref.watch(finampSettingsProvider.locale);
    return PaddedCustomScrollview(
      slivers: [
        // For some reason, setting the null (system) LanguageListTile to
        // const stops it from switching when going to/from the same
        // language as the system language (e.g., system to English on a
        // device set to English)
        // ignore: prefer_const_constructors
        SliverList(
          // ignore: prefer_const_constructors
          delegate: SliverChildListDelegate.fixed([
            // ignore: prefer_const_constructors
            LanguageListTile(),
            const Divider(),
          ]),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final locale = locales.values.elementAt(index);

            return LanguageListTile(locale: locale);
          }, childCount: locales.length),
        ),
      ],
    );
  }
}

class LanguageListTile extends ConsumerWidget {
  const LanguageListTile({super.key, this.locale});

  final Locale? locale; // null if system language

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeFromSettings = ref.watch(finampSettingsProvider.locale);
    return RadioListTile<Locale?>(
      title: Text(locale?.nativeDisplayLanguageScript ?? AppLocalizations.of(context)!.system),
      subtitle: locale != null
          ? Text(
              localeFromSettings != null
                  ? "${locale!.displayLanguageScriptIn(localeFromSettings)}${locale!.countryCode != null ? " (${locale!.displayCountryIn(localeFromSettings)})" : ""}"
                  : "${locale!.defaultDisplayLanguageScript}${locale!.countryCode != null ? " (${locale!.defaultDisplayCountry})" : ""}",
            )
          : null,
      value: locale,
      groupValue: localeFromSettings,
      onChanged: (_) => FinampSetters.setLocale(locale),
    );
  }
}
