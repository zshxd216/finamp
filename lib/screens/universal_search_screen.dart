import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';

import '../components/AlbumScreen/song_list_tile.dart';
import '../components/MusicScreen/album_item.dart';
import '../components/glass_surface.dart';
import '../models/jellyfin_models.dart';
import '../services/finamp_settings_helper.dart';
import '../services/jellyfin_api_helper.dart';

class UniversalSearchScreen extends StatefulWidget {
  const UniversalSearchScreen({Key? key}) : super(key: key);

  static const routeName = "/search";

  @override
  State<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends State<UniversalSearchScreen> {
  final _searchController = TextEditingController();
  final _jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();
  Timer? _debounce;
  Future<List<BaseItemDto>>? _searchFuture;
  String _query = "";

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _query = value.trim();
        _searchFuture = _query.isEmpty ? null : _performSearch(_query);
      });
    });
  }

  Future<List<BaseItemDto>> _performSearch(String query) async {
    if (FinampSettingsHelper.finampSettings.isOffline) {
      return [];
    }

    final results = await _jellyfinApiHelper.getItems(
      includeItemTypes:
          "Audio,MusicAlbum,MusicArtist,Playlist,MusicGenre",
      searchTerm: query,
      sortBy: "SortName",
      sortOrder: "Ascending",
      startIndex: 0,
      limit: 100,
      isGenres: false,
    );

    return results ?? [];
  }

  Widget _buildResultItem(BaseItemDto item) {
    if (item.type == "Audio") {
      return SongListTile(
        item: item,
        parentId: item.albumId,
        isSong: true,
      );
    }

    return AlbumItem(
      album: item,
      isGrid: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final isOffline = FinampSettingsHelper.finampSettings.isOffline;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: MaterialLocalizations.of(context).searchFieldLabel,
          ),
        ),
        backgroundColor: isIOS ? Colors.transparent : null,
        elevation: isIOS ? 0 : null,
        scrolledUnderElevation: isIOS ? 0 : null,
        flexibleSpace: isIOS ? const GlassSurface() : null,
      ),
      body: isOffline
          ? Center(
              child:
                  Text(AppLocalizations.of(context)!.notAvailableInOfflineMode),
            )
          : _searchFuture == null
              ? const SizedBox.shrink()
              : FutureBuilder<List<BaseItemDto>>(
                  future: _searchFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final results = snapshot.data ?? [];
                    if (results.isEmpty) {
                      return const Center(child: Text("No results"));
                    }

                    return ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) =>
                          _buildResultItem(results[index]),
                    );
                  },
                ),
    );
  }
}
