import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finamp/components/AlbumScreen/track_list_tile.dart';
import 'package:finamp/components/Buttons/simple_button.dart';
import 'package:finamp/components/MusicScreen/music_screen_tab_view.dart';
import 'package:finamp/components/album_image.dart';
import 'package:finamp/components/global_snackbar.dart';
import 'package:finamp/components/padded_custom_scrollview.dart';
import 'package:finamp/components/print_duration.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/services/album_screen_provider.dart';
import 'package:finamp/services/feedback_helper.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/finamp_user_helper.dart';
import 'package:finamp/services/jellyfin_api_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:get_it/get_it.dart';
import '../models/jellyfin_models.dart';

class PlaylistEditScreen extends ConsumerStatefulWidget {
  const PlaylistEditScreen({super.key, required this.playlist});

  static const routeName = "/music/playlist/edit";
  final BaseItemDto playlist;

  @override
  ConsumerState<PlaylistEditScreen> createState() => _PlaylistEditScreenState();
}

class _PlaylistEditScreenState extends ConsumerState<PlaylistEditScreen> {
  String? _name;
  BaseItemId? _id;
  bool? _publicVisibility;
  bool _isUpdating = false;
  List<BaseItemDto> playlistTracks = [];
  List<BaseItemDto> removedTracks = [];

  BaseItemDto? _albumImage;
  // Future<File?> newAlbumImage;
  // int _songCount = 1;

  final _jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name = widget.playlist.name;
    _id = widget.playlist.id;
    _albumImage = widget.playlist;
    // newAlbumImage = widget.playlist as Future<File?>;
    _fetchPublicVisibility();
    // _songCount = 1;

    final tracksAsync = ref.read(getSortedPlaylistTracksProvider(widget.playlist));
    final (allTracks, playableTracks) = tracksAsync.valueOrNull ?? (null, null);

    playlistTracks = allTracks ?? [];
  }

  Future<File?> filePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      File file = File(result.files.single.path!);
      return file;
    } else {
      return null;
    }
  }

  void setNewAlbumImage() async {}

  Future<void> _fetchPublicVisibility() async {
    if (_publicVisibility != null) return;
    final resultPlaylist = await _jellyfinApiHelper.getPlaylist(_id!);
    setState(() {
      _publicVisibility = resultPlaylist['OpenAccess'] as bool;
    });
  }

  Future<void> _saveOrUpdatePlaylist() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
      });

      _formKey.currentState!.save();

      try {
        BaseItemDto playlistTemp = widget.playlist;
        playlistTemp.name = _name;
        await _jellyfinApiHelper.updatePlaylist(
          newPlaylist: NewPlaylist(
            isPublic: _publicVisibility,
            userId: GetIt.instance<FinampUserHelper>().currentUserId,
            ids: playlistTracks.map((track) => track.id).toList(),
            name: _name,
          ),
          itemId: widget.playlist.id,
        );

        musicScreenRefreshStream.add(null); // refresh playlist content

        if (!mounted) return;

        GlobalSnackbar.message((context) => AppLocalizations.of(context)!.playlistUpdated, isConfirmation: true);
        Navigator.of(context).pop();
      } catch (e) {
        errorSnackbar(e, context);

        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOffline = ref.watch(finampSettingsProvider.isOffline);
    SortBy playlistSortBySetting = ref.read(finampSettingsProvider.playlistTracksSortBy);
    final playlistSortBy =
        (isOffline && (playlistSortBySetting == SortBy.datePlayed || playlistSortBySetting == SortBy.playCount))
        ? SortBy.defaultOrder
        : playlistSortBySetting;

    final playlistTracksCount = playlistTracks.length;
    final trackCountString = (playlistTracks.length == widget.playlist.childCount || !isOffline)
        ? AppLocalizations.of(context)!.trackCount(playlistTracksCount)
        : AppLocalizations.of(context)!.offlineTrackCount(widget.playlist.childCount!, playlistTracksCount);
    final trackDurationString = (playlistTracks.length == widget.playlist.childCount)
        ? printDuration(widget.playlist.runTimeTicksDuration(), leadingZeroes: false)
        : printDuration(
            playlistTracks
                .map((t) => t.runTimeTicksDuration())
                .whereType<Duration>()
                .fold<Duration>(Duration.zero, (sum, dur) => sum + dur),
            leadingZeroes: false,
          );

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.editItemTitle("playlist"))),
      body: PaddedCustomScrollview(
        bottomPadding: 100.0,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Album Image
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AlbumImage(
                          item: _albumImage,
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          tapToZoom: false,
                        ),
                        Stack(
                          children: [
                            Container(color: Colors.black.withValues(alpha: 0.4)),
                            Center(
                              child: SimpleButton(
                                onPressed: () {
                                  // Future<File?> _newImage = filePicker();
                                },
                                icon: TablerIcons.edit,
                                iconColor: Colors.white,
                                iconSize: 32.0,
                                text: "Tap to Edit Cover*",
                                textColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Playlist Name + Public Visibility
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsGeometry.only(left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Form(
                            key: _formKey,
                            child: TextFormField(
                              initialValue: _name,
                              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.name),
                              textInputAction: TextInputAction.done,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!.required;
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) async => await _saveOrUpdatePlaylist(),
                              onSaved: (newValue) => _name = newValue,
                            ),
                          ),

                          FormField<bool>(
                            builder: (state) {
                              return CheckboxListTile(
                                value: _publicVisibility ?? false,
                                title: Text(
                                  AppLocalizations.of(context)!.publiclyVisiblePlaylist,
                                  textAlign: TextAlign.left,
                                ),
                                contentPadding: EdgeInsets.zero,
                                onChanged: (value) {
                                  state.didChange(value);
                                  setState(() {
                                    _publicVisibility = value!;
                                  });
                                },
                              );
                            },
                          ),

                          // Text(_songCount as String),
                          Wrap(
                            direction: Axis.horizontal,
                            alignment: WrapAlignment.start,
                            spacing: 12.0,
                            children: [Text(trackCountString), Text(trackDurationString)],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverReorderableList(
            autoScrollerVelocityScalar: 20.0,
            onReorder: (oldIndex, newIndex) {
              if (mounted) {
                setState(() {
                  playlistTracks.insert(newIndex, playlistTracks.removeAt(oldIndex));
                });
              }
            },
            onReorderStart: (p0) {
              FeedbackHelper.feedback(FeedbackType.selection);
            },
            findChildIndexCallback: (Key key) {
              key = key as GlobalObjectKey;
              final ValueKey<String> valueKey = key.value as ValueKey<String>;
              final index = playlistTracks.indexWhere((item) => item.id == valueKey.value);
              if (index == -1) return null;
              return index;
            },
            itemCount: playlistTracks.length,
            itemBuilder: (context, index) {
              final item = playlistTracks[index];
              final actualIndex = index;
              final indexOffset = index + 1;

              return Material(
                type: MaterialType.transparency,
                key: ValueKey(item.id),
                child: QueueListTile(
                  item: item,
                  listIndex: index,
                  actualIndex: actualIndex,
                  indexOffset: indexOffset,
                  parentItem: widget.playlist,
                  allowReorder: true,
                  isCurrentTrack: false,
                  isInPlaylist: true,
                  allowDismiss: true,
                  onRemoveFromList: () {
                    setState(() {
                      removedTracks.add(playlistTracks.removeAt(index));
                    });
                  },
                  onTap: (bool playable) {},
                ),
              );
            },
          ),
          SliverStickyHeader(
            header: Text("Removed Tracks*"),
            sliver: SliverReorderableList(
              autoScrollerVelocityScalar: 20.0,
              onReorder: (oldIndex, newIndex) {
                if (mounted) {
                  setState(() {
                    removedTracks.insert(newIndex, removedTracks.removeAt(oldIndex));
                  });
                }
              },
              onReorderStart: (p0) {
                FeedbackHelper.feedback(FeedbackType.selection);
              },
              findChildIndexCallback: (Key key) {
                key = key as GlobalObjectKey;
                final ValueKey<String> valueKey = key.value as ValueKey<String>;
                final index = removedTracks.indexWhere((item) => item.id == valueKey.value);
                if (index == -1) return null;
                return index;
              },
              itemCount: removedTracks.length,
              itemBuilder: (context, index) {
                final item = removedTracks[index];
                final actualIndex = index;
                final indexOffset = index + 1;

                return Material(
                  type: MaterialType.transparency,
                  key: ValueKey(item.id),
                  child: QueueListTile(
                    item: item,
                    listIndex: index,
                    actualIndex: actualIndex,
                    indexOffset: indexOffset,
                    parentItem: widget.playlist,
                    allowReorder: false,
                    isCurrentTrack: false,
                    isInPlaylist: false,
                    allowDismiss: false,
                    onRemoveFromList: () {
                      setState(() {
                        removedTracks.removeAt(index);
                      });
                    },
                    onTap: (bool playable) {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUpdating ? null : () async => await _saveOrUpdatePlaylist(),
        label: Text("Save/Update Playlist*"),
        icon: Icon(TablerIcons.device_floppy),
      ),
    );
  }
}
