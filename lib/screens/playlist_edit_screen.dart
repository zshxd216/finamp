import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:finamp/components/AlbumScreen/track_list_tile.dart';
import 'package:finamp/components/MusicScreen/music_screen_tab_view.dart';
import 'package:finamp/components/album_image.dart';
import 'package:finamp/components/global_snackbar.dart';
import 'package:finamp/components/padded_custom_scrollview.dart';
import 'package:finamp/components/print_duration.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/services/album_screen_provider.dart';
import 'package:finamp/services/feedback_helper.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/finamp_user_helper.dart';
import 'package:finamp/services/jellyfin_api_helper.dart';
import 'package:finamp/services/permission_providers.dart';
import 'package:finamp/services/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';

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
  File? newAlbumImage;

  // Dirty tracking baselines
  late String _initialName;
  late bool _initialVisibility;
  late List<String> _initialTrackIdsOrder;

  bool get _haveTracksChanged {
    final currentOrder = playlistTracks.map((t) => t.id.raw).toList();
    if (currentOrder.length != _initialTrackIdsOrder.length) return true;
    for (var i = 0; i < currentOrder.length; i++) {
      if (currentOrder[i] != _initialTrackIdsOrder[i]) return true;
    }
    if (removedTracks.isNotEmpty) return true;
    return false;
  }

  bool get _hasMetadataChanged {
    return _name != _initialName || (_publicVisibility ?? false) != _initialVisibility;
  }

  bool get _hasCoverChanged {
    return newAlbumImage != null;
  }

  bool get _isDirty {
    return _haveTracksChanged || _hasMetadataChanged || _hasCoverChanged;
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_isDirty) return true;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.discardChangesTitle),
            content: Text(AppLocalizations.of(context)!.discardChangesDescription),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(AppLocalizations.of(context)!.genericCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(AppLocalizations.of(context)!.discardChangesConfirmButton),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _resetDirtyBaseline() {
    _initialName = _name ?? '';
    _initialVisibility = _publicVisibility ?? false;
    _initialTrackIdsOrder = playlistTracks.map((t) => t.id.raw).toList();
    newAlbumImage = null;
    removedTracks.clear();
  }

  final _jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name = widget.playlist.name;
    _id = widget.playlist.id;
    _albumImage = widget.playlist;
    _fetchPublicVisibility();
    final tracksAsync = ref.read(getSortedPlaylistTracksProvider(widget.playlist));
    final (allTracks, playableTracks) = tracksAsync.valueOrNull ?? (null, null);
    playlistTracks = allTracks ?? [];
    _initialName = _name ?? '';
    _initialVisibility = _publicVisibility ?? false;
    _initialTrackIdsOrder = playlistTracks.map((t) => t.id.raw).toList();
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
        if (_hasMetadataChanged) {
          // Jellyfin can't handle updating both the track list and name at the same time, so make two separate requests
          await _jellyfinApiHelper.updatePlaylist(
            newPlaylist: NewPlaylist(
              isPublic: _publicVisibility,
              name: _name,
              userId: GetIt.instance<FinampUserHelper>().currentUserId,
            ),
            itemId: widget.playlist.id,
          );
        }
        if (_haveTracksChanged) {
          await _jellyfinApiHelper.updatePlaylist(
            newPlaylist: NewPlaylist(
              ids: playlistTracks.map((track) => track.id).toList(),
              userId: GetIt.instance<FinampUserHelper>().currentUserId,
            ),
            itemId: widget.playlist.id,
          );
        }

        if (_hasCoverChanged) {
          await _jellyfinApiHelper.setItemPrimaryImage(itemId: widget.playlist.id!, imageFile: newAlbumImage!);
        }

        musicScreenRefreshStream.add(null); // refresh playlist content

        if (!mounted) return;

        GlobalSnackbar.message((context) => AppLocalizations.of(context)!.playlistUpdated, isConfirmation: true);
        setState(() {
          _resetDirtyBaseline();
        });
        Navigator.of(context).pop();
      } catch (e) {
        GlobalSnackbar.error(e);

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

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _confirmDiscardChanges();
        if (shouldDiscard && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: PaddedCustomScrollview(
          bottomPadding: 120.0,
          slivers: [
            SliverAppBar(
              title: Text(AppLocalizations.of(context)!.editItemTitle(BaseItemDtoType.fromItem(widget.playlist).name)),
              expandedHeight: kToolbarHeight + 125 + 48,
              pinned: true,
              centerTitle: false,
              titleSpacing: 0,
              flexibleSpace: ItemTheme(
                item: widget.playlist,
                child: Builder(
                  builder: (context) {
                    return FlexibleSpaceBar(
                      background: Align(
                        alignment: AlignmentGeometry.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: ColorScheme.of(context).primary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: ref.watch(canEditMetadataProvider)
                                        ? () async {
                                            final file = await filePicker();
                                            if (file == null) return;
                                            setState(() {
                                              newAlbumImage = file;
                                            });
                                          }
                                        : () {
                                            GlobalSnackbar.message(
                                              (context) => AppLocalizations.of(context)!.noPermissionToEditMetadata,
                                            );
                                          },
                                    child: SizedBox(
                                      height: 130,
                                      width: 130,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.center,
                                        children: [
                                          if (newAlbumImage != null)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(5),
                                              child: Image.file(
                                                newAlbumImage!,
                                                fit: BoxFit.cover,
                                                width: 150,
                                                height: 150,
                                                errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black26),
                                              ),
                                            )
                                          else
                                            AlbumImage(
                                              item: _albumImage,
                                              borderRadius: BorderRadius.all(Radius.circular(5)),
                                              tapToZoom: false,
                                            ),
                                          if (ref.watch(canEditMetadataProvider))
                                            Stack(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withValues(alpha: 0.4),
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                ),
                                                Center(child: Icon(TablerIcons.edit, color: Colors.white, size: 32.0)),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10, height: 1),
                                  // Playlist Name + Public Visibility
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Form(
                                          key: _formKey,
                                          child: TextFormField(
                                            initialValue: _name,
                                            textAlign: TextAlign.start,
                                            cursorColor: ColorScheme.of(context).onSurface,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                              labelText: AppLocalizations.of(context)!.name,
                                              floatingLabelBehavior: FloatingLabelBehavior.never,
                                              filled: true,
                                              fillColor: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.black.withOpacity(0.8)
                                                  : Colors.white.withOpacity(0.8),
                                              border: OutlineInputBorder(
                                                // borderSide: BorderSide(color: ColorScheme.of(context).primary, width: 1.0),
                                                borderSide: BorderSide.none,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                            textInputAction: TextInputAction.done,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return AppLocalizations.of(context)!.required;
                                              }
                                              return null;
                                            },
                                            onFieldSubmitted: (_) async => await _saveOrUpdatePlaylist(),
                                            onChanged: (value) => setState(() {
                                              _name = value;
                                            }),
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
                                              contentPadding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
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
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                          child: Wrap(
                                            direction: Axis.horizontal,
                                            alignment: WrapAlignment.start,
                                            spacing: 12.0,
                                            children: [Text(trackCountString), Text(trackDurationString)],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverReorderableList(
              autoScrollerVelocityScalar: 20.0,
              onReorder: (oldIndex, newIndex) {
                if (mounted) {
                  setState(() {
                    playlistTracks.insert(
                      newIndex < oldIndex ? newIndex : newIndex - 1,
                      playlistTracks.removeAt(oldIndex),
                    );
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

                return Material(
                  type: MaterialType.transparency,
                  key: ValueKey(item.id),
                  child: EditListTile(
                    item: item,
                    listIndex: index,
                    onRemoveOrRestore: () {
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
              header: Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 16.0, bottom: 2.0),
                child: Text(
                  AppLocalizations.of(context)!.removedTracks,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              sliver: removedTracks.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Center(child: Text(AppLocalizations.of(context)!.removedTracksEmptyListPlaceholder)),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = removedTracks[index];

                        return Material(
                          type: MaterialType.transparency,
                          key: ValueKey(item.id),
                          child: EditListTile(
                            item: item,
                            listIndex: index,
                            restoreInsteadOfRemove: true,
                            onRemoveOrRestore: () {
                              setState(() {
                                playlistTracks.add(removedTracks.removeAt(index));
                              });
                            },
                            onTap: (bool playable) {},
                          ),
                        );
                      }, childCount: removedTracks.length),
                    ),
            ),
          ],
        ),
        floatingActionButton: _isDirty
            ? FloatingActionButton.extended(
                onPressed: _isUpdating ? null : () async => await _saveOrUpdatePlaylist(),
                label: _isUpdating
                    ? Row(
                        children: <Widget>[
                          SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.savingChanges),
                        ],
                      )
                    : Text(AppLocalizations.of(context)!.updatePlaylistButtonLabel),
                icon: _isUpdating ? null : const Icon(TablerIcons.device_floppy),
              )
            : null,
      ),
    );
  }
}
