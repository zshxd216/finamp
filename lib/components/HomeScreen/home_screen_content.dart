import 'dart:math';

import 'package:balanced_text/balanced_text.dart';
import 'package:finamp/components/Buttons/simple_button.dart';
import 'package:finamp/components/HomeScreen/show_all_button.dart';
import 'package:finamp/components/HomeScreen/show_all_screen.dart';
import 'package:finamp/components/MusicScreen/item_collection_card.dart';
import 'package:finamp/components/MusicScreen/item_collection_wrapper.dart';
import 'package:finamp/components/MusicScreen/music_screen_tab_view.dart';
import 'package:finamp/components/finamp_icon.dart';
import 'package:finamp/components/global_snackbar.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/screens/music_screen.dart';
import 'package:finamp/screens/queue_restore_screen.dart';
import 'package:finamp/services/downloads_service.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:finamp/services/audio_service_helper.dart';
import 'package:finamp/services/finamp_user_helper.dart';
import 'package:finamp/services/jellyfin_api_helper.dart';
import 'package:finamp/components/Buttons/cta_large.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';

part 'home_screen_content.g.dart';

final _homeScreenLogger = Logger("HomeScreen");
const homeScreenSectionItemLimit = 20;

class HomeScreenContent extends ConsumerStatefulWidget {
  const HomeScreenContent({super.key});

  @override
  ConsumerState<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends ConsumerState<HomeScreenContent> {
  final _audioServiceHelper = GetIt.instance<AudioServiceHelper>();
  final _finampUserHelper = GetIt.instance<FinampUserHelper>();
  final _jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FinampSettings? finampSettings = ref.watch(finampSettingsProvider).value;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(loadHomeSectionItemsProvider),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 0,
                runSpacing: 8,
                direction: Axis.horizontal,
                alignment: WrapAlignment.spaceBetween,
                runAlignment: WrapAlignment.center,
                children: [
                  CTALarge(
                    text: 'Song Mix*',
                    icon: TablerIcons.arrows_shuffle,
                    vertical: true,
                    minWidth: 110,
                    onPressed: () {
                      _audioServiceHelper.shuffleAll(onlyShowFavorites: finampSettings?.onlyShowFavorites ?? false);
                    },
                  ),
                  CTALarge(
                    text: 'Recents*',
                    icon: TablerIcons.calendar,
                    vertical: true,
                    minWidth: 110,
                    onPressed: () {
                      Navigator.pushNamed(context, QueueRestoreScreen.routeName);
                    },
                  ),
                  CTALarge(
                    text: 'Radio*',
                    icon: TablerIcons.radio,
                    vertical: true,
                    minWidth: 110,
                    onPressed: () {
                      //TODO start radio with a random track?
                      GlobalSnackbar.message((buildContext) {
                        return "Radio is not available yet.";
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSection(HomeScreenSectionInfo(type: HomeScreenSectionType.collection, itemId: BaseItemId(""))),
              _buildSection(HomeScreenSectionInfo(type: HomeScreenSectionType.listenAgain)),
              _buildSection(HomeScreenSectionInfo(type: HomeScreenSectionType.newlyAdded)),
              _buildSection(HomeScreenSectionInfo(type: HomeScreenSectionType.favoriteArtists)),
              SizedBox(height: 80),
              ...[
                // monochrome icon
                FinampIcon(56, 56, overrideColor: TextTheme.of(context).bodySmall?.color?.withOpacity(0.4)),
                SizedBox(height: 16),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 200),
                    child: BalancedText(
                      "Built with ♥ by the Finamp contributors.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: TextTheme.of(context).bodySmall?.color?.withOpacity(0.6)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(HomeScreenSectionInfo sectionInfo) {
    return Consumer(
      builder: (context, ref, child) {
        final items = ref.watch(loadHomeSectionItemsProvider(sectionInfo: sectionInfo));

        return Padding(
          // if we show text, it won't fill up all four lines (on average), so we have enough white space already
          padding: EdgeInsets.only(top: ref.watch(finampSettingsProvider.showTextOnGridView) ? 4.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimpleGestureDetector(
                onTap: () {
                  // Handle the tap event
                  GlobalSnackbar.message((buildContext) {
                    return "This feature is not available yet.";
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      sectionInfo.type.toLocalisedString(context),
                      style: TextTheme.of(context).titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                        color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                      ),
                    ),
                    ShowAllButton(
                      onPressed: () {
                        Navigator.pushNamed(context, ShowAllScreen.routeName, arguments: sectionInfo);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(flex: 0, child: _buildHorizontalList(items)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizontalList(AsyncValue<List<BaseItemDto>?> items) {
    return switch (items) {
      AsyncData(:final value) => switch (value) {
        null => _buildHorizontalSkeletonLoader(),
        [] => const Center(child: Text("No items available.", maxLines: 1)),
        _ => SizedBox(
          height: calculateItemCollectionCardHeight(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: value.length,
            itemBuilder: (context, index) {
              final BaseItemDto item = value[index];
              return ItemCollectionWrapper(item: item, isGrid: true);
            },
            separatorBuilder: (context, index) => const SizedBox(width: 8, height: 1),
          ),
        ),
        // _ => _buildHorizontalSkeletonLoader(),
      },
      AsyncError(:final error) => () {
        _homeScreenLogger.severe("Error loading items: $error");
        return Center(child: Text("Failed to load items.", maxLines: 1));
      }(),
      _ => _buildHorizontalSkeletonLoader(),
    };
  }

  Widget _buildHorizontalSkeletonLoader() {
    return SizedBox(
      height: calculateItemCollectionCardHeight(context) + 20,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5, // Show 5 skeleton items
        itemBuilder: (context, index) {
          final cardWidth = calculateItemCollectionCardWidth(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: cardWidth,
                height: cardWidth,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
              ),
              SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Container(
                  width: cardWidth * Random().nextDouble().clamp(0.2, 0.9),
                  height: max(calculateTextHeight(style: TextTheme.of(context).bodySmall!, lines: 1) - 4, 0),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Container(
                  width: cardWidth * Random().nextDouble().clamp(0.2, 0.9),
                  height: max(calculateTextHeight(style: TextTheme.of(context).bodySmall!, lines: 1) - 4, 0),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
      ),
    );
  }
}

@Riverpod(keepAlive: true)
Future<List<BaseItemDto>?> loadHomeSectionItems(
  Ref ref, {
  required HomeScreenSectionInfo sectionInfo,
  int startIndex = 0,
  int limit = homeScreenSectionItemLimit,
}) async {
  final jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();
  final finampUserHelper = GetIt.instance<FinampUserHelper>();
  final settings = FinampSettingsHelper.finampSettings;

  print("CALLED loadHomeSectionItems provider with ${sectionInfo.type}");

  final Future<List<BaseItemDto>?> newItemsFuture;

  if (settings.isOffline) {
    newItemsFuture = loadHomeSectionItemsOffline(sectionInfo: sectionInfo, startIndex: startIndex, limit: limit);
    return newItemsFuture;
  }

  switch (sectionInfo.type) {
    case HomeScreenSectionType.listenAgain:
      newItemsFuture = jellyfinApiHelper.getItems(
        parentItem: finampUserHelper.currentUser?.currentView,
        includeItemTypes: [BaseItemDtoType.album.jellyfinName, BaseItemDtoType.playlist.jellyfinName].join(","),
        sortBy: SortBy.datePlayed.jellyfinName(null),
        sortOrder: SortOrder.descending.toString(),
        // filters: settings.onlyShowFavorites ? "IsFavorite" : null,
        startIndex: startIndex,
        limit: limit,
      );
      break;
    case HomeScreenSectionType.newlyAdded:
      newItemsFuture = jellyfinApiHelper.getItems(
        parentItem: finampUserHelper
            .currentUser
            ?.currentView, //FIXME Jellyfin can't query (playlists) and (albums of a specific library) at the same time yet
        includeItemTypes: [BaseItemDtoType.album.jellyfinName, BaseItemDtoType.playlist.jellyfinName].join(","),
        sortBy: SortBy.dateCreated.jellyfinName(null),
        sortOrder: SortOrder.descending.toString(),
        // filters: settings.onlyShowFavorites ? "IsFavorite" : null,
        startIndex: startIndex,
        limit: limit,
      );
      break;
    case HomeScreenSectionType.favoriteArtists:
      newItemsFuture = jellyfinApiHelper.getItems(
        parentItem: finampUserHelper.currentUser?.currentView,
        includeItemTypes: [BaseItemDtoType.artist.jellyfinName].join(","),
        sortBy: SortBy.datePlayed.jellyfinName(null),
        sortOrder: SortOrder.descending.toString(),
        filters: "IsFavorite",
        startIndex: startIndex,
        limit: limit,
      );
      break;
    case HomeScreenSectionType.collection:
      final baseItem = await jellyfinApiHelper.getItemById(
        sectionInfo.itemId!,
      ); //TODO I don't like this null check. Enforcing IDs for collection types would be much nice, but how to do that while allowing dynamic IDs? Enums don't seem to work
      newItemsFuture = jellyfinApiHelper.getItems(
        parentItem: baseItem,
        // includeItemTypes: [
        //   BaseItemDtoType.album.jellyfinName,
        //   BaseItemDtoType.playlist.jellyfinName,
        //   BaseItemDtoType.artist.jellyfinName,
        //   BaseItemDtoType.genre.jellyfinName,
        //   BaseItemDtoType.audioBook.jellyfinName,
        // ].join(","),
        recursive: false, //!!! prevent loading tracks and albums from inside the collection items
        // filters: "IsFavorite",
        startIndex: startIndex,
        limit: limit,
      );
      break;
  }

  return await newItemsFuture;
}

Future<List<BaseItemDto>?> loadHomeSectionItemsOffline({
  required HomeScreenSectionInfo sectionInfo,
  int startIndex = 0,
  int limit = 10,
}) async {
  final FinampSettings settings = FinampSettingsHelper.finampSettings;
  final downloadsService = GetIt.instance<DownloadsService>();
  final finampUserHelper = GetIt.instance<FinampUserHelper>();

  List<DownloadStub> offlineItems;
  List<BaseItemDto> items;

  switch (sectionInfo.type) {
    case HomeScreenSectionType.listenAgain:
      //FIXME this seems to also return metadata-only albums which don't have any downloaded children
      offlineItems = await downloadsService.getAllCollections(
        includeItemTypes: [BaseItemDtoType.album, BaseItemDtoType.playlist], //FIXME support allowing multiple types
        fullyDownloaded: settings.onlyShowFullyDownloaded,
        viewFilter: finampUserHelper.currentUser?.currentViewId,
        childViewFilter: null,
        nullableViewFilters: settings.showDownloadsWithUnknownLibrary,
        onlyFavorites: settings.onlyShowFavorites && settings.trackOfflineFavorites,
      );

      items = offlineItems.map((e) => e.baseItem).nonNulls.toList();
      items = sortItems(items, SortBy.datePlayed, SortOrder.descending);
      break;

    case HomeScreenSectionType.newlyAdded:
      offlineItems = await downloadsService.getAllCollections(
        includeItemTypes: [BaseItemDtoType.album, BaseItemDtoType.playlist], //FIXME support allowing multiple types
        fullyDownloaded: settings.onlyShowFullyDownloaded,
        viewFilter: finampUserHelper.currentUser?.currentViewId,
        childViewFilter: null,
        nullableViewFilters: settings.showDownloadsWithUnknownLibrary,
        onlyFavorites: settings.onlyShowFavorites && settings.trackOfflineFavorites,
      );
      items = offlineItems.map((e) => e.baseItem).nonNulls.toList();
      items = sortItems(items, SortBy.dateCreated, SortOrder.descending);
      break;
    case HomeScreenSectionType.favoriteArtists:
      offlineItems = await downloadsService.getAllCollections(
        includeItemTypes: [BaseItemDtoType.artist],
        fullyDownloaded: settings.onlyShowFullyDownloaded,
        viewFilter: finampUserHelper.currentUser?.currentViewId,
        childViewFilter: null,
        nullableViewFilters: false,
        onlyFavorites: settings.onlyShowFavorites && settings.trackOfflineFavorites,
      );
      items = offlineItems.map((e) => e.baseItem).nonNulls.toList();
      items = sortItems(items, SortBy.datePlayed, SortOrder.descending);
      break;
    default:
      offlineItems = <DownloadStub>[]; // No items for other sections
      items = offlineItems.map((e) => e.baseItem).nonNulls.toList();
  }

  return items.take(limit).toList();
}
