import 'dart:io';

import 'package:finamp/components/MusicScreen/filter_menu_button.dart';
import 'package:finamp/components/MusicScreen/sort_menu_button.dart';
import 'package:finamp/components/MusicScreen/sort_order_button.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SortAndFilterRow extends ConsumerWidget {
  final TabContentType tabType;
  final void Function(TabContentType) refreshTab;
  final SortBy? sortByOverride;
  final void Function(SortBy?)? updateSortByOverride;
  final SortOrder? sortOrderOverride;
  final void Function(SortOrder?)? updateSortOrderOverride;
  final Set<ItemFilter>? filterOverride;
  final void Function(Set<ItemFilter>?)? updateFilterOverride;

  final bool forPlaylistTracks;

  const SortAndFilterRow({
    super.key,
    required this.tabType,
    required this.refreshTab,
    this.sortByOverride,
    this.updateSortByOverride,
    this.sortOrderOverride,
    this.updateSortOrderOverride,
    this.filterOverride,
    this.updateFilterOverride,
    this.forPlaylistTracks = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tabType != TabContentType.home) {
      return SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FilterMenuButton(
                tabType: tabType,
                filterOverride: filterOverride,
                updateFilterOverride: (newFilters) => updateFilterOverride?.call(newFilters),
              ),
              SortMenuButton(
                tabType: tabType,
                sortByOverride: sortByOverride,
                onSortByOverrideChanged: (newSortBy) => updateSortByOverride?.call(newSortBy),
                sortOrderOverride: sortOrderOverride,
                updateSortOrderOverride: (newSortOrder) => updateSortOrderOverride?.call(newSortOrder),
                forPlaylistTracks: forPlaylistTracks,
              ),
              // if (ref.watch(finampSettingsProvider.isOffline) && tabType != TabContentType.tracks)
              //   IconButton(
              //     icon: ref.watch(finampSettingsProvider.onlyShowFullyDownloaded)
              //         ? const Icon(Icons.download)
              //         : const Icon(Icons.download_outlined),
              //     onPressed: ref.read(finampSettingsProvider.isOffline)
              //         ? () => FinampSetters.setOnlyShowFullyDownloaded(
              //             !ref.read(finampSettingsProvider.onlyShowFullyDownloaded),
              //           )
              //         : null,
              //     tooltip: AppLocalizations.of(context)!.onlyShowFullyDownloaded,
              //   ),
              // if (!ref.watch(finampSettingsProvider.isOffline) ||
              //     ref.watch(finampSettingsProvider.trackOfflineFavorites))
              //   IconButton(
              //     icon: (isFavoriteOverride ?? ref.watch(finampSettingsProvider.onlyShowFavorites))
              //         ? const Icon(Icons.favorite)
              //         : const Icon(Icons.favorite_outline),
              //     onPressed: () {
              //       if (isFavoriteOverride != null) {
              //         updateIsFavoriteOverride(!(isFavoriteOverride!));
              //       } else {
              //         FinampSetters.setOnlyShowFavorites(!ref.watch(finampSettingsProvider.onlyShowFavorites));
              //       }
              //     },
              //     tooltip: AppLocalizations.of(context)!.favorites,
              //   ),
            ],
          ),
        ),
      );
    }
    return SizedBox.shrink();
  }
}
