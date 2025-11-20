import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:finamp/components/PlayerScreen/artist_chip.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/models/jellyfin_models.dart' as jellyfin_models;
import 'package:finamp/services/artist_content_provider.dart';
import 'package:finamp/services/downloads_service.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/finamp_user_helper.dart';
import 'package:finamp/services/item_helper.dart';
import 'package:finamp/services/jellyfin_api_helper.dart';
import 'package:finamp/services/queue_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:mutex/mutex.dart';

final _radioLogger = Logger("Radio");
final _radioRandom = Random();

/// Returns the amount of tracks that are needed to fill up the radio queue
int calculateRadioTracksNeeded() {
  // fetch enough (10 or more) tracks of at least ~2 minutes to fill the entire precache buffer
  final minUpcomingRadioTracks = max(10, FinampSettingsHelper.finampSettings.bufferDuration.inMinutes ~/ 2);
  final queueService = GetIt.instance<QueueService>();
  final currentQueue = queueService.getQueue();
  if (FinampSettingsHelper.finampSettings.radioEnabled) {
    if (![SavedQueueState.saving, SavedQueueState.pendingSave].contains(currentQueue.saveState)) {
      return 0;
    }
    final queueSize = currentQueue.nextUp.length + currentQueue.queue.length;
    return max(0, minUpcomingRadioTracks - queueSize);
  }
  return 0;
}

final Mutex _radioGenerationLock = Mutex();

final List<DateTime> _radioCallTimestamps = [];
const int _radioCallLimit = 8;
const Duration _radioCallWindow = Duration(seconds: 20);

Future<void> maybeAddRadioTracks() async {
  final queueService = GetIt.instance<QueueService>();
  final currentQueue = queueService.getQueue();

  // Rate-limit: prevent running if called >= _radioCallLimit times within _radioCallWindow.
  final now = DateTime.now();
  _radioCallTimestamps.removeWhere((t) => now.difference(t) > _radioCallWindow);
  if (_radioCallTimestamps.length >= _radioCallLimit) {
    _radioLogger.warning(
      "maybeAddRadioTracks suppressed: called ${_radioCallTimestamps.length} times within the last ${_radioCallWindow.inSeconds}s.",
    );
    return;
  }
  _radioCallTimestamps.add(now);

  final radioTracksNeeded = calculateRadioTracksNeeded();
  if (radioTracksNeeded > 0 && !_radioGenerationLock.isLocked) {
    await _radioGenerationLock.protect(() async {
      RadioResult result = await generateRadioTracks(radioTracksNeeded);
      if (result.tracks.isNotEmpty && result.isStillValid()) {
        await queueService.addToQueue(
          items: result.tracks,
          source: QueueItemSource.rawId(
            type: QueueItemSourceType.radio,
            name: currentQueue.source.item != null
                ? QueueItemSourceName(
                    type: QueueItemSourceNameType.radio,
                    localizationParameter: currentQueue.source.item?.name ?? "",
                  )
                : QueueItemSourceName(type: QueueItemSourceNameType.radio),
            id: currentQueue.source.item?.id.raw ?? currentQueue.source.id,
          ),
        );
        _radioLogger.finer(
          "Added ${result.tracks.map((song) => song.name).toList().join(", ")} to the queue for radio.",
        );
      }
    });
  }
}

//TODO this queue should eventually be moved into the QueueService as part of the virtual queue / treadmill
List<jellyfin_models.BaseItemDto> _surplusTracksQueue = [];
RadioMode? _lastUsedRadioMode;

bool toggleRadio([bool? enable]) {
  final queueService = GetIt.instance<QueueService>();
  final currentlyEnabled = FinampSettingsHelper.finampSettings.radioEnabled;
  final newState = enable ?? !currentlyEnabled;
  FinampSetters.setRadioEnabled(newState);
  if (!newState) {
    clearSurplusRadioTracks();
    unawaited(queueService.clearRadioTracks());
  }
  return newState;
}

void clearSurplusRadioTracks() {
  _surplusTracksQueue.clear();
  _lastUsedRadioMode = null;
}

enum AlbumMixFallbackModes { similarSingles, artistAlbums, artistSingles, performingArtistAlbums, libraryAlbums }

// Generates tracks for the radio. Provide item to generate the initial radio tracks.
Future<RadioResult> generateRadioTracks(int minNumTracks, {jellyfin_models.BaseItemDto? overrideSeedItem}) async {
  final radioMode = FinampSettingsHelper.finampSettings.radioMode;
  final radioState = FinampSettingsHelper.finampSettings.radioEnabled;
  final result = RadioResult(
    tracks: [],
    radioMode: radioMode,
    seedItem: getRadioSeedItem(overrideSeedItem),
    radioState: radioState,
  );

  if (FinampSettingsHelper.finampSettings.radioMode != _lastUsedRadioMode) {
    // clear surplus tracks if the mode changed
    _surplusTracksQueue.clear();
    _lastUsedRadioMode = FinampSettingsHelper.finampSettings.radioMode;
  } else if (minNumTracks <= _surplusTracksQueue.length) {
    final tracksToReturn = _surplusTracksQueue.take(minNumTracks).toList();
    _surplusTracksQueue.removeRange(0, minNumTracks);
    return result.withTracks(tracksToReturn);
  }

  final providers = GetIt.instance<ProviderContainer>();
  final jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();
  final downloadsService = GetIt.instance<DownloadsService>();
  final finampUserHelper = GetIt.instance<FinampUserHelper>();
  final queueService = GetIt.instance<QueueService>();
  final currentQueue = queueService.getQueue();
  final actualSeed = getRadioSeedItem(overrideSeedItem);
  List<jellyfin_models.BaseItemDto> tracksOut = [];

  assert(
    currentQueue.fullQueue.isEmpty ? overrideSeedItem != null : overrideSeedItem == null,
    "overrideSeedItem must be provided if the queue is empty, and must not be provided if a queue exists.",
  );

  _radioLogger.finer(
    "Generating $minNumTracks radio tracks from item '${actualSeed?.name}' using '${FinampSettingsHelper.finampSettings.radioMode.name}' mode.",
  );

  // Items originally in the currently playing source (or manually added)

  final originalQueue = actualSeed != null
      ? (await loadChildTracksFromBaseItem(baseItem: actualSeed)).map((item) => item).toList()
      : currentQueue.fullQueue
            .whereNot((e) => e.source.type == QueueItemSourceType.radio)
            .where((e) => !FinampSettingsHelper.finampSettings.isOffline || e.item.extras?["isDownloaded"] == true)
            .map((e) => e.baseItem)
            .nonNulls
            .toList();
  switch (FinampSettingsHelper.finampSettings.radioMode) {
    case RadioMode.reshuffle:
      // Adds tracks in such a manner to simulate "shuffle + repeat all", but with each repeat iteration re-shuffling
      // the order.
      // Tracks added to the queue manually will throw things off, though!
      final reshuffledQueue = originalQueue.shuffled();
      tracksOut.addAll(reshuffledQueue.take(minNumTracks));
      _surplusTracksQueue.addAll(reshuffledQueue.skip(minNumTracks));
      break;
    case RadioMode.random:
      final randomModeAvailable = providers.read(isRandomRadioModeAvailableProvider(actualSeed));
      if (!randomModeAvailable) {
        _radioLogger.warning(
          "Random radio mode selected but the provided item '${actualSeed?.name}' is not downloaded. Returning empty track list.",
        );
        break;
      }
      tracksOut.addAll(
        List.generate(minNumTracks, (index) {
          // Pick a random item to add, duplicates possible!
          int nextIndex = _radioRandom.nextInt(originalQueue.length);
          return originalQueue[nextIndex];
        }),
      );
      // add at least 25 surplus tracks to the queue
      _surplusTracksQueue.addAll(
        List.generate(max(25, originalQueue.length), (index) {
          int nextIndex = _radioRandom.nextInt(originalQueue.length);
          return originalQueue[nextIndex];
        }),
      );

      break;
    case RadioMode.similar:
      if (actualSeed == null) {
        _radioLogger.warning("No seed item available for radio generation. Aborting.");
        return result;
      }
      const offsetExtraTracks = 1; // extra track to exclude the current track
      const filterExtraTracks = 10; // extra tracks in case duplicates are removed
      // const repetitionThresholdTracks = 50; // filter out X recent tracks
      // filter out ALL duplicates, otherwise things will start repeating too often since the base item never changes
      final repetitionThresholdTracks = currentQueue.fullQueue.length;
      // extra tracks to randomly choose from to introduce non-determinism
      final randomnessExtraTracks = 8 + (minNumTracks * 1.5).ceil();
      List<jellyfin_models.BaseItemDto> fullSample = [];
      (tracksOut, fullSample) = await _getSimilarTracks(
        referenceItem: actualSeed,
        minNumTracks: minNumTracks,
        offsetExtraTracks: offsetExtraTracks,
        filterExtraTracks: filterExtraTracks,
        randomnessExtraTracks: randomnessExtraTracks,
        repetitionThresholdTracks: repetitionThresholdTracks,
      );
      int attempt = 0;
      while (tracksOut.length < minNumTracks) {
        attempt++;
        final additionalTracks = attempt * 10;
        _radioLogger.warning("No similar tracks found. Retrying with $additionalTracks more extra tracks.");
        (tracksOut, fullSample) = await _getSimilarTracks(
          referenceItem: actualSeed,
          minNumTracks: minNumTracks,
          offsetExtraTracks: offsetExtraTracks,
          // we add the extra tracks as a filter instead of an offset, so that newly-added similar tracks are included as soon as possible
          filterExtraTracks: filterExtraTracks + additionalTracks,
          randomnessExtraTracks: randomnessExtraTracks,
          repetitionThresholdTracks: repetitionThresholdTracks,
        );
      }
      _surplusTracksQueue.addAll(fullSample.skip(minNumTracks));
      break;
    case RadioMode.continuous:
      if (actualSeed == null) {
        _radioLogger.warning("No seed item available for radio generation. Aborting.");
        return result;
      }
      // like [RadioMode.similar], but based on the last track in the queue, not the original source
      const offsetExtraTracks = 1; // extra track to exclude the current track
      const filterExtraTracks = 10; // extra tracks in case duplicates are removed
      // const repetitionThresholdTracks = 50; // filter out X recent tracks
      // filter out recent tracks within 90 minutes
      final repetitionThresholdTracks = currentQueue.getTrackCountWithinDuration(Duration(minutes: 90));
      // extra tracks to randomly choose from to introduce non-determinism
      final randomnessExtraTracks = 5 + (minNumTracks * 1.5).ceil();

      // we fetch tracks one-by-one to be truly continuous from the start. for that we use the while loop and only ever fetch a single track at a time.
      (tracksOut, _) = await _getSimilarTracks(
        // use the last track as the reference so that the radio flows better
        // if we use the current tracks it always alternates between similar tracks because there's a delay of [minUpcomingRadioTracks] before the related track is played
        // [seedItem] is only used for generating tracks if there's no queue yet
        referenceItem: currentQueue.fullQueue.isEmpty
            ? overrideSeedItem ?? actualSeed
            : currentQueue.fullQueue.last.baseItem!,
        minNumTracks: 1,
        offsetExtraTracks: offsetExtraTracks,
        filterExtraTracks: filterExtraTracks,
        randomnessExtraTracks: randomnessExtraTracks,
        repetitionThresholdTracks: repetitionThresholdTracks,
      );
      int attempt = 0;
      int lastTracksOutLength = tracksOut.length;
      while (tracksOut.length < minNumTracks) {
        if (attempt > 15) {
          // prevent infinite loops
          break;
        }
        // only increment attempts if no additional track was discovered
        if (lastTracksOutLength == tracksOut.length) {
          attempt++;
        }
        final additionalTracks = attempt * 10;
        _radioLogger.warning("No similar tracks found. Retrying with $additionalTracks more extra tracks.");
        List<jellyfin_models.BaseItemDto> tracksOutSample = [];
        (tracksOutSample, _) = await _getSimilarTracks(
          referenceItem: actualSeed,
          minNumTracks: 1,
          offsetExtraTracks: offsetExtraTracks,
          // we add the extra tracks as a filter instead of an offset, so that newly-added similar tracks are included as soon as possible
          filterExtraTracks: filterExtraTracks + additionalTracks,
          randomnessExtraTracks: randomnessExtraTracks,
          repetitionThresholdTracks: repetitionThresholdTracks,
        );
        tracksOut += tracksOutSample;
      }
      // we don't add anything to the surplus queue, since we need to fetch tracks one-by-one anyway
      break;
    case RadioMode.albumMix:
      if (actualSeed == null) {
        _radioLogger.warning("No seed item available for radio generation. Aborting.");
        return result;
      }
      const filterExtraAlbums = 10; // extra albums in case duplicates are removed
      // extra albums to randomly choose from to introduce non-determinism
      final randomnessExtraAlbums = 5;

      // filter out any albums where tracks with that album as the (radio) source are already in the queue
      final existingAlbumIds = currentQueue.fullQueue
          .where((queueItem) => queueItem.baseItem?.albumId != null)
          .map((queueItem) => queueItem.baseItem!.albumId)
          .toSet();
      List<jellyfin_models.BaseItemDto> filteredSimilarAlbums = [];

      int attempt = 0;
      bool similarAlbumsAvailable = true;
      AlbumMixFallbackModes? fallbackMode = FinampSettingsHelper.finampSettings.isOffline
          ? AlbumMixFallbackModes.artistAlbums
          : null;
      while (filteredSimilarAlbums.isEmpty) {
        // if there are similar albums and we just haven't found any full albums, switch to similar singles
        if (attempt >= 5 || (fallbackMode != null && similarAlbumsAvailable)) {
          if (fallbackMode == null) {
            fallbackMode = AlbumMixFallbackModes.artistAlbums;
            attempt = 0;
          } else if (fallbackMode == AlbumMixFallbackModes.artistAlbums) {
            // prefer similar singles over artist singles
            fallbackMode = AlbumMixFallbackModes.similarSingles;
            attempt = 0;
          } else {
            // prevent infinite loops
            break;
          }
        }
        final additionalAlbums = 2 * attempt + pow(attempt, 2.75).toInt(); // ~ 0, 3, 10, 27, 50, 100
        attempt++;
        if (attempt > 1) {
          _radioLogger.warning("No similar albums found. Retrying with $additionalAlbums more extra albums.");
        }

        final seedId = getAlbumMixRadioModeSeedId(actualSeed);
        if (seedId == null) {
          _radioLogger.warning(
            "Album mix radio mode selected but the provided item '${actualSeed.name}' is not suitable for album mix radio. Returning empty track list.",
          );
          break;
        }

        List<jellyfin_models.BaseItemDto> similarAlbums;

        switch (fallbackMode) {
          case AlbumMixFallbackModes.artistAlbums:
          case AlbumMixFallbackModes.artistSingles:
          case AlbumMixFallbackModes.performingArtistAlbums:
            BaseItemDto? artist;
            List<BaseItemId> artistIds =
                [
                      if (fallbackMode != AlbumMixFallbackModes.performingArtistAlbums)
                        ...?actualSeed.albumArtists?.map((e) => e.id),
                      ...?actualSeed.artistItems?.map((e) => e.id),
                    ].nonNulls.toList()
                    as List<BaseItemId>;
            while (artist == null && artistIds.isNotEmpty) {
              final artistId = artistIds.removeAt(0);
              artist = await providers.read(artistItemProvider(artistId).future);
            }
            if (artist == null) {
              fallbackMode = AlbumMixFallbackModes.libraryAlbums;
              continue;
            }
            if (fallbackMode == AlbumMixFallbackModes.performingArtistAlbums) {
              similarAlbums = await providers.read(
                getPerformingArtistAlbumsProvider(
                  artist: artist,
                  libraryFilter: currentQueue.sourceLibrary,
                  sortBy: SortBy.random,
                ).future,
              );
            } else {
              similarAlbums = await providers.read(
                getArtistAlbumsProvider(
                  artist: artist,
                  libraryFilter: currentQueue.sourceLibrary,
                  sortBy: SortBy.random,
                ).future,
              );
            }

            break;
          case AlbumMixFallbackModes.libraryAlbums:
            // just fetch a random album from the library
            if (FinampSettingsHelper.finampSettings.isOffline) {
              similarAlbums = (await downloadsService.getAllCollections(
                baseTypeFilter: BaseItemDtoType.album,
                fullyDownloaded: false,
                viewFilter: finampUserHelper.currentUser?.currentViewId,
                nullableViewFilters: FinampSettingsHelper.finampSettings.showDownloadsWithUnknownLibrary,
              )).map((e) => e.baseItem).nonNulls.toList();
            } else {
              similarAlbums =
                  (await jellyfinApiHelper.getItems(
                    parentItem: currentQueue.sourceLibrary,
                    recursive: true,
                    includeItemTypes: [BaseItemDtoType.album.name].join(","),
                    sortBy: SortBy.random.jellyfinName(TabContentType.albums),
                  )) ??
                  [];
            }
            break;
          case AlbumMixFallbackModes.similarSingles:
          case null:
            if (FinampSettingsHelper.finampSettings.isOffline) {
              fallbackMode = AlbumMixFallbackModes.artistAlbums;
              continue;
            }
            similarAlbums =
                await jellyfinApiHelper.getSimilarAlbums(
                  seedId,
                  limit: 1 + filterExtraAlbums + randomnessExtraAlbums + additionalAlbums,
                ) ??
                [];
            break;
        }

        if (similarAlbums.isEmpty && fallbackMode == null) {
          // Jellyfin can't guarantee that there are similar albums, since the suggestions are based on genre tags
          // If a genre only contains that one album, no similar albums will be returned
          _radioLogger.warning(
            "No similar albums found for album mix radio from item '${actualSeed.name}'. Fetching based on album artist.",
          );
          similarAlbumsAvailable = false;
          fallbackMode = AlbumMixFallbackModes.artistAlbums;
          continue;
        }

        filteredSimilarAlbums = similarAlbums
            .where((album) => !existingAlbumIds.contains(album.id))
            // don't include singles unless we're falling back to them
            .where(
              (album) =>
                  ([AlbumMixFallbackModes.similarSingles, AlbumMixFallbackModes.artistSingles].contains(fallbackMode) ||
                  (album.songCount ?? album.childCount ?? 0) > 1),
            )
            .toList();

        if (filteredSimilarAlbums.isEmpty && fallbackMode == AlbumMixFallbackModes.artistAlbums) {
          _radioLogger.warning(
            "No suitable similar full albums found for album mix radio from artist '${actualSeed.albumArtists ?? actualSeed.artistItems?.first.name}'. Fetching singles.",
          );
          fallbackMode = AlbumMixFallbackModes.artistSingles;
          continue;
        }

        if (filteredSimilarAlbums.isEmpty) {
          switch (fallbackMode) {
            case AlbumMixFallbackModes.artistAlbums:
              _radioLogger.warning(
                "No suitable similar full albums found for album mix radio from artist '${actualSeed.albumArtists ?? actualSeed.artistItems?.first.name}'. Fetching singles.",
              );
              fallbackMode = AlbumMixFallbackModes.artistSingles;
              break;
            case AlbumMixFallbackModes.artistSingles:
              _radioLogger.warning(
                "No suitable similar singles found for album mix radio from artist '${actualSeed.albumArtists ?? actualSeed.artistItems?.first.name}'. Fetching appears on albums.",
              );
              fallbackMode = AlbumMixFallbackModes.performingArtistAlbums;
              break;
            case AlbumMixFallbackModes.performingArtistAlbums:
              _radioLogger.warning(
                "No suitable similar appears on albums found for album mix radio from artist '${actualSeed.albumArtists ?? actualSeed.artistItems?.first.name}'. Fetching from library.",
              );
              fallbackMode = AlbumMixFallbackModes.libraryAlbums;
              break;
            case AlbumMixFallbackModes.similarSingles:
            case AlbumMixFallbackModes.libraryAlbums:
            case null:
              break;
          }
        }
      }

      // pick a random album from the remaining ones
      if (filteredSimilarAlbums.isNotEmpty) {
        final randomIndex = _radioRandom.nextInt(min(filteredSimilarAlbums.length, randomnessExtraAlbums));
        final selectedAlbum = filteredSimilarAlbums[randomIndex];
        filteredSimilarAlbums.removeAt(randomIndex);
        _radioLogger.finer("Selected album '${selectedAlbum.name}' for album mix radio.");
        // load tracks from the selected album
        final albumTracks = await loadChildTracksFromBaseItem(baseItem: selectedAlbum);
        // we add all tracks at once to preserve the album as a unit
        tracksOut = albumTracks;
      } else {
        _radioLogger.warning("No suitable similar albums found for album mix radio. Returning empty track list.");
      }
      break;
  }
  _radioLogger.finer(
    "Selected ${tracksOut.length} tracks for '${FinampSettingsHelper.finampSettings.radioMode.name}' mode: ${tracksOut.map((e) => "'${e.artists?.firstOrNull} - ${e.name}'").join(", ")}",
  );
  return result.withTracks(tracksOut);
}

Future<(List<jellyfin_models.BaseItemDto>, List<jellyfin_models.BaseItemDto>)> _getSimilarTracks({
  required jellyfin_models.BaseItemDto referenceItem,
  required int minNumTracks,
  required int offsetExtraTracks,
  required int filterExtraTracks,
  required int randomnessExtraTracks,
  required int repetitionThresholdTracks,
}) async {
  assert(!FinampSettingsHelper.finampSettings.isOffline, "Similar tracks not available while offline");
  final jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();
  final queueService = GetIt.instance<QueueService>();
  final currentQueue = queueService.getQueue();
  List<jellyfin_models.BaseItemDto> fullSample = [];
  List<jellyfin_models.BaseItemDto> itemsOut = [];
  final items = await jellyfinApiHelper.getInstantMix(
    referenceItem,
    limit: minNumTracks + offsetExtraTracks + filterExtraTracks + randomnessExtraTracks,
  );
  if (items != null) {
    fullSample.addAll(items);
    _radioLogger.finer(
      "Fetched ${fullSample.length} similar radio candidates: ${fullSample.map((e) => "'${e.artists?.firstOrNull} - ${e.name}'").join(", ")}",
    );
    // instant mixes always return the track itself as the first item, filter it out
    fullSample.removeRange(0, offsetExtraTracks);
    // filter out duplicate tracks, including upcoming ones
    final recentlyPlayedIds = currentQueue.fullQueue.reversed
        .take(repetitionThresholdTracks)
        .map((item) => item.baseItem!.id)
        .toSet();
    fullSample.removeWhere((item) => recentlyPlayedIds.contains(item.id));
    _radioLogger.finer(
      "Filtered candidates (${fullSample.length}): ${fullSample.map((e) => "'${e.artists?.firstOrNull} - ${e.name}'").join(", ")}",
    );
    // pick a random subset of tracks to ensure non-determinism
    fullSample = fullSample.shuffled();
    itemsOut = fullSample.take(minNumTracks).toList();
  }
  return (itemsOut, fullSample);
}

final isRadioCurrentlyActiveProvider = ProviderFamily<bool, BaseItemDto?>((ref, BaseItemDto? source) {
  final radioMode = ref.watch(finampSettingsProvider.radioMode);
  final radioModeAvailable = ref.watch(isRadioModeAvailableProvider((radioMode, source)));
  final radioEnabled = ref.watch(finampSettingsProvider.radioEnabled);
  return radioEnabled && radioModeAvailable;
});

final isRadioModeAvailableProvider = ProviderFamily<bool, (RadioMode, BaseItemDto?)>((
  ref,
  (RadioMode radioMode, BaseItemDto? source) arguments,
) {
  final radioMode = arguments.$1;
  final source = arguments.$2;

  final notOffline = !ref.watch(finampSettingsProvider.isOffline);
  final randomModeAvailable = ref.watch(isRandomRadioModeAvailableProvider(source));
  final albumMixModeAvailable = ref.watch(isAlbumMixRadioModeAvailableProvider(source));

  final currentModeAvailable = switch (radioMode) {
    RadioMode.reshuffle => true,
    RadioMode.random => randomModeAvailable,
    RadioMode.similar => notOffline,
    RadioMode.continuous => notOffline,
    RadioMode.albumMix => albumMixModeAvailable,
  };
  return currentModeAvailable;
});

final isRandomRadioModeAvailableProvider = ProviderFamily<bool, BaseItemDto?>((ref, BaseItemDto? baseItem) {
  final downloadsService = GetIt.instance<DownloadsService>();

  // only available offline when downloaded
  final randomModeAvailable =
      !ref.watch(finampSettingsProvider.isOffline) ||
      (baseItem != null &&
          ref
              .watch(
                downloadsService.statusProvider((
                  DownloadStub.fromItem(type: baseItem.downloadType, item: baseItem),
                  null,
                )),
              )
              .isDownloaded);
  return randomModeAvailable;
});

BaseItemId? getAlbumMixRadioModeSeedId(BaseItemDto? baseItem) {
  return baseItem != null
      ? switch (BaseItemDtoType.fromItem(baseItem)) {
          BaseItemDtoType.album => baseItem.id,
          BaseItemDtoType.track => baseItem.albumId,
          _ => null,
        }
      : null;
}

final isAlbumMixRadioModeAvailableProvider = ProviderFamily<bool, BaseItemDto?>((ref, BaseItemDto? baseItem) {
  // only when the seed item is an album itself or part of one
  final albumMixModeAvailable = getAlbumMixRadioModeSeedId(baseItem) != null;
  return albumMixModeAvailable;
});

BaseItemDto? getRadioSeedItem([BaseItemDto? seedItem]) {
  final queueService = GetIt.instance<QueueService>();
  final currentQueue = queueService.getQueue();
  final actualSeed =
      seedItem ??
      currentQueue.source.item ??
      currentQueue.fullQueue.last.baseItem; // use last track if no source available
  return actualSeed;
}

IconData getRadioModeIcon(RadioMode radioMode) {
  return switch (radioMode) {
    RadioMode.reshuffle => TablerIcons.arrows_shuffle,
    RadioMode.random => TablerIcons.help_hexagon,
    RadioMode.similar => TablerIcons.ear,
    RadioMode.continuous => TablerIcons.route,
    RadioMode.albumMix => TablerIcons.album,
  };
}
