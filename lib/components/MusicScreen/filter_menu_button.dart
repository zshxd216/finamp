import 'package:finamp/components/Buttons/simple_button.dart';
import 'package:finamp/components/global_snackbar.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

enum tempMenuOption { favorites, downloaded }

class FilterMenuButton extends ConsumerWidget {
  const FilterMenuButton({
    super.key,
    required this.tabType,
    this.sortByOverride,
    this.onOverrideChanged,
    this.forPlaylistTracks = false,
  });

  final TabContentType tabType;
  final SortBy? sortByOverride;
  final void Function(SortBy newSortBy)? onOverrideChanged;
  final bool forPlaylistTracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isOffline = ref.watch(finampSettingsProvider.isOffline);
    final bool onlyShowFavorites = ref.watch(finampSettingsProvider.onlyShowFavorites);
    final bool onlyShowFullyDownloaded = ref.watch(finampSettingsProvider.onlyShowFullyDownloaded);
    final int activeFilterCount = (onlyShowFavorites ? 1 : 0) + (onlyShowFullyDownloaded ? 1 : 0);
    String statusText = activeFilterCount == 0
        ? "No Filter Active*"
        : "$activeFilterCount ${activeFilterCount == 1 ? "Filter" : "Filters"} Active*";
    return SimpleButton(
      icon: TablerIcons.filter,
      text: statusText,
      fontWeight: activeFilterCount > 0 ? FontWeight.w600 : FontWeight.normal,
      iconColor: activeFilterCount > 0
          ? ColorScheme.of(context).primary
          : TextTheme.of(context).bodyMedium?.color?.withOpacity(0.7),
      textColor: activeFilterCount > 0
          ? ColorScheme.of(context).primary
          : TextTheme.of(context).bodyMedium?.color?.withOpacity(0.7),
      onPressed: () {
        showMenu<tempMenuOption>(
          context: context,
          position: const RelativeRect.fromLTRB(0, 160, 0, 0),
          items: [
            for (final option in tempMenuOption.values)
              PopupMenuItem(
                value: option,
                child: Builder(
                  builder: (context) {
                    final color =
                        switch (option) {
                          tempMenuOption.favorites => onlyShowFavorites,
                          tempMenuOption.downloaded => onlyShowFullyDownloaded,
                        }
                        ? Theme.of(context).colorScheme.secondary
                        : null;
                    return Opacity(
                      opacity: (ref.watch(finampSettingsProvider.isOffline) && option == tempMenuOption.downloaded)
                          ? 0.3
                          : 1,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Icon(
                                switch (option) {
                                  tempMenuOption.favorites =>
                                    onlyShowFavorites ? TablerIcons.heart_filled : TablerIcons.heart,
                                  tempMenuOption.downloaded =>
                                    ref.watch(finampSettingsProvider.onlyShowFullyDownloaded)
                                        ? TablerIcons.download
                                        : TablerIcons.download_off,
                                },
                                size: 18,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text("${option.name}*", style: TextStyle(color: color)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ).then((value) {
          if (value != null) {
            switch (value) {
              case tempMenuOption.favorites:
                FinampSetters.setOnlyShowFavorites(!onlyShowFavorites);
              case tempMenuOption.downloaded:
                if (isOffline) {
                  FinampSetters.setOnlyShowFullyDownloaded(!onlyShowFullyDownloaded);
                } else {
                  GlobalSnackbar.message((context) => AppLocalizations.of(context)!.notAvailableInOfflineMode);
                }
            }
          }
        });
      },
    );
  }
}
