import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/services/downloads_service.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/jellyfin_api_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'item_by_id_provider.g.dart';

@riverpod
Future<BaseItemDto?> itemById(Ref ref, BaseItemId baseItemId) async {
  final jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();
  final downloadsService = GetIt.instance<DownloadsService>();

  late BaseItemDto? baseItem;

  if (ref.watch(finampSettingsProvider.isOffline)) {
    //FIXME implement offline support by implementing and equivalent to getItemById in DownloadsService, which doesn't care about the download type
    baseItem = null;
  } else {
    baseItem = await jellyfinApiHelper.getItemById(baseItemId);
  }
  return baseItem;
}
