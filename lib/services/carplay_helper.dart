import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';

import 'android_auto_helper.dart';
import 'audio_service_helper.dart';
import 'queue_service.dart';
import 'jellyfin_api_helper.dart';

class CarPlayHelper {
  static final _carPlayHelperLogger = Logger("CarPlayHelper");
  static const _methodChannel = MethodChannel('finamp/carplay');
  
  final _androidAutoHelper = GetIt.instance<AndroidAutoHelper>();
  final _queueService = GetIt.instance<QueueService>();
  final _audioServiceHelper = GetIt.instance<AudioServiceHelper>();
  final _jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();
  
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;
  
  void initialize() {
    if (!Platform.isIOS) return;
    
    _methodChannel.setMethodCallHandler(_handleMethodCall);
    _queueService.addListener(_onQueueChanged);
    
    _carPlayHelperLogger.info("CarPlay helper initialized");
  }
  
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'carplay_connected':
        _isConnected = true;
        _carPlayHelperLogger.info("CarPlay connected");
        await _updateNowPlaying();
        break;
      case 'carplay_disconnected':
        _isConnected = false;
        _carPlayHelperLogger.info("CarPlay disconnected");
        break;
      default:
        _carPlayHelperLogger.warning("Unknown method call: ${call.method}");
    }
  }
  
  void _onQueueChanged() {
    if (_isConnected) {
      _updateNowPlaying();
    }
  }
  
  Future<void> _updateNowPlaying() async {
    if (!_isConnected) return;
    
    try {
      final currentTrack = _queueService.getCurrentTrack();
      
      if (currentTrack?.baseItem == null) {
        return;
      }
      
      await _methodChannel.invokeMethod('updateNowPlaying', {
        'title': currentTrack!.baseItem!.name,
        'artist': currentTrack.baseItem!.artists?.join(", "),
        'album': currentTrack.baseItem!.album,
        'artUri': _jellyfinApiHelper.getImageUrl(item: currentTrack.baseItem!)?.toString(),
      });
    } catch (e) {
      _carPlayHelperLogger.severe("Error updating now playing: $e");
    }
  }
  
  Future<void> updateBrowseContent() async {
    if (!_isConnected) return;
    
    try {
      // Reuse Android Auto's browse content logic
      final recentItems = await _androidAutoHelper.getRecentItems();
      
      await _methodChannel.invokeMethod('updateBrowseContent', {
        'items': recentItems.map((item) => {
          'id': item.id,
          'title': item.title,
          'subtitle': item.artist,
          'artUri': item.artUri?.toString(),
        }).toList(),
      });
    } catch (e) {
      _carPlayHelperLogger.severe("Error updating browse content: $e");
    }
  }
  
  void dispose() {
    _queueService.removeListener(_onQueueChanged);
  }
}
