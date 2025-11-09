import 'package:finamp/components/Buttons/simple_button.dart';
import 'package:finamp/components/global_snackbar.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class SortMenuButton extends ConsumerWidget {
  const SortMenuButton({
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
    final rawSortOptions = SortBy.defaultsFor(type: tabType.itemType, includeDefaultOrder: forPlaylistTracks);
    final sortOptions = isOffline
        ? [
            ...rawSortOptions.where((s) => s != SortBy.playCount && s != SortBy.datePlayed),
            ...rawSortOptions.where((s) => s == SortBy.playCount || s == SortBy.datePlayed),
          ]
        : rawSortOptions;
    var selectedSortBy =
        (sortByOverride ??
        (forPlaylistTracks
            ? ref.watch(finampSettingsProvider.playlistTracksSortBy)
            : ref.watch(finampSettingsProvider.tabSortBy(tabType))));
    // PlayCount and Last Played are not representative in Offline Mode
    // so we disable it and overwrite it with the Sort Name if it was selected
    if (isOffline && (selectedSortBy == SortBy.playCount || selectedSortBy == SortBy.datePlayed)) {
      selectedSortBy = forPlaylistTracks ? SortBy.defaultOrder : SortBy.sortName;
    }
    return SimpleButton(
      icon: TablerIcons.sort_ascending,
      text: selectedSortBy?.toLocalisedString(context) ?? AppLocalizations.of(context)!.sortBy,
      onPressed: () {
        showMenu<SortBy>(
          context: context,
          position: const RelativeRect.fromLTRB(100, 160, 0, 0),
          items: [
            for (SortBy sortBy in sortOptions)
              PopupMenuItem(
                value: sortBy,
                child: Opacity(
                  opacity: (isOffline && ((sortBy == SortBy.playCount || sortBy == SortBy.datePlayed))) ? 0.3 : 1,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(
                            sortBy.getIcon(),
                            size: 18,
                            color: ((selectedSortBy == sortBy) ? Theme.of(context).colorScheme.secondary : null),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sortBy.toLocalisedString(context),
                          style: TextStyle(
                            color: ((selectedSortBy == sortBy) ? Theme.of(context).colorScheme.secondary : null),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ).then((value) {
          if (value != null) {
            if (isOffline && ((value == SortBy.playCount || value == SortBy.datePlayed))) {
              GlobalSnackbar.message((context) => AppLocalizations.of(context)!.notAvailableInOfflineMode);
            } else {
              if (sortByOverride != null && onOverrideChanged != null) {
                onOverrideChanged!(value);
              } else if (forPlaylistTracks) {
                FinampSetters.setPlaylistTracksSortBy(value);
              } else {
                FinampSetters.setTabSortBy(tabType, value);
              }
            }
          }
        });
      },
    );
    return PopupMenuButton<SortBy>(
      icon: const Icon(Icons.sort),
      tooltip: AppLocalizations.of(context)!.sortBy,
      itemBuilder: (context) => [
        for (SortBy sortBy in sortOptions)
          PopupMenuItem(
            value: sortBy,
            child: Opacity(
              opacity: (isOffline && ((sortBy == SortBy.playCount || sortBy == SortBy.datePlayed))) ? 0.3 : 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        sortBy.getIcon(),
                        size: 18,
                        color: ((selectedSortBy == sortBy) ? Theme.of(context).colorScheme.secondary : null),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sortBy.toLocalisedString(context),
                      style: TextStyle(
                        color: ((selectedSortBy == sortBy) ? Theme.of(context).colorScheme.secondary : null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
      onSelected: (value) {
        if (isOffline && ((value == SortBy.playCount || value == SortBy.datePlayed))) {
          GlobalSnackbar.message((context) => AppLocalizations.of(context)!.notAvailableInOfflineMode);
        } else {
          if (sortByOverride != null && onOverrideChanged != null) {
            onOverrideChanged!(value);
          } else if (forPlaylistTracks) {
            FinampSetters.setPlaylistTracksSortBy(value);
          } else {
            FinampSetters.setTabSortBy(tabType, value);
          }
        }
      },
    );
  }
}
