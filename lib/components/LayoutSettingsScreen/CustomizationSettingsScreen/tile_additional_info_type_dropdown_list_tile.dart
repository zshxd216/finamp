import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class TileAdditionalInfoTypeTitleListTile extends ConsumerWidget {
  const TileAdditionalInfoTypeTitleListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(AppLocalizations.of(context)!.additionalBaseItemInfoTitle),
      subtitle: Text(AppLocalizations.of(context)!.additionalBaseItemInfoSubtitle),
    );
  }
}

class TileAdditionalInfoTypeDropdownListTile extends ConsumerWidget {
  final TabContentType tabContentType;

  const TileAdditionalInfoTypeDropdownListTile({required this.tabContentType, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tileAdditionalInfoType = ref.watch(finampSettingsProvider.tileAdditionalInfoType(tabContentType));
    final currentType = tileAdditionalInfoType ?? TileAdditionalInfoType.adaptive;

    // Filter dropdown items based on tabContentType
    final dropdownItems = [
      TileAdditionalInfoType.adaptive,
      TileAdditionalInfoType.dateAdded,
      if ([TabContentType.tracks, TabContentType.albums].contains(tabContentType)) TileAdditionalInfoType.dateReleased,
      if ([TabContentType.tracks].contains(tabContentType)) TileAdditionalInfoType.playCount,
      if ([TabContentType.tracks].contains(tabContentType)) TileAdditionalInfoType.dateLastPlayed,
      if ([TabContentType.albums, TabContentType.artists, TabContentType.playlists].contains(tabContentType))
        TileAdditionalInfoType.duration,
      TileAdditionalInfoType.none,
    ];

    return ListTile(
      title: Text(tabContentType.toLocalisedString(context)),
      subtitle: LayoutBuilder(
        builder: (context, constraints) {
          return DropdownMenu<TileAdditionalInfoType>(
            width: constraints.maxWidth,
            dropdownMenuEntries: dropdownItems
                .map(
                  (e) => DropdownMenuEntry<TileAdditionalInfoType>(
                    value: e,
                    label: e.toLocalisedString(context),
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all<EdgeInsets>(
                        const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      ),
                    ),
                  ),
                )
                .toList(),
            initialSelection: currentType,
            enableFilter: false,
            enableSearch: false,
            onSelected: (value) {
              if (value != null) {
                FinampSetters.setTileAdditionalInfoType(tabContentType, value);
              }
            },
            textStyle: Theme.of(context).textTheme.bodyMedium,
            trailingIcon: const Icon(TablerIcons.chevron_down),
            selectedTrailingIcon: const Icon(TablerIcons.chevron_up),
            menuStyle: MenuStyle(
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              backgroundColor: WidgetStateProperty.all<Color>(
                Color.alphaBlend(ColorScheme.of(context).onSurface.withOpacity(0.2), ColorScheme.of(context).surface),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              filled: true,
              fillColor: Color.alphaBlend(
                ColorScheme.of(context).primary.withOpacity(0.075),
                ColorScheme.of(context).onSurface.withOpacity(0.1),
              ),
              visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.only(left: 8.0),
            ),
          );
        },
      ),
    );
  }
}
