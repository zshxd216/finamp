import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import '../../services/lyrics_service.dart';
import '../../services/music_player_background_task.dart';
import '../../models/jellyfin_models.dart';
import '../../services/car_mode_helper.dart';

class FloatingLyricsDisplay extends ConsumerStatefulWidget {
  final double opacity;
  final double fontSize;
  final bool isCarMode;
  
  const FloatingLyricsDisplay({
    Key? key,
    this.opacity = 0.8,
    this.fontSize = 24,
    required this.isCarMode,
  }) : super(key: key);

  @override
  ConsumerState<FloatingLyricsDisplay> createState() => _FloatingLyricsDisplayState();
}

class _FloatingLyricsDisplayState extends ConsumerState<FloatingLyricsDisplay> {
  final LyricsService _lyricsService = GetIt.instance<LyricsService>();
  final MusicPlayerBackgroundTask _audioHandler = GetIt.instance<MusicPlayerBackgroundTask>();
  final CarModeHelper _carModeHelper = GetIt.instance<CarModeHelper>();
  
  List<LyricLine> _lyrics = [];
  int _currentLineIndex = -1;
  bool _isVisible = true;
  
  @override
  void initState() {
    super.initState();
    _loadLyrics();
    _listenToPlaybackState();
  }
  
  void _loadLyrics() async {
    final mediaItem = _audioHandler.mediaItem.value;
    if (mediaItem == null || mediaItem.extras?["itemJson"] == null) {
      return;
    }
    
    try {
      final item = BaseItemDto.fromJson(mediaItem.extras!["itemJson"]);
      final lrcContent = await _lyricsService.fetchLyrics(item);
      
      if (lrcContent != null) {
        setState(() {
          _lyrics = _lyricsService.parseLrc(lrcContent);
        });
      }
    } catch (e) {
      print('Error loading floating lyrics: $e');
    }
  }
  
  void _listenToPlaybackState() {
    _audioHandler.playbackState.listen((state) {
      final position = state.position;
      _updateCurrentLine(position);
    });
    
    _audioHandler.mediaItem.listen((_) {
      _loadLyrics();
      _currentLineIndex = -1;
    });
  }
  
  void _updateCurrentLine(Duration position) {
    if (_lyrics.isEmpty) return;
    
    int newIndex = -1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (position >= _lyrics[i].duration) {
        newIndex = i;
      } else {
        break;
      }
    }
    
    if (newIndex != _currentLineIndex) {
      setState(() {
        _currentLineIndex = newIndex;
      });
    }
  }
  
  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _lyrics.isEmpty || _currentLineIndex == -1) {
      return Container();
    }
    
    final carMode = widget.isCarMode;
    final currentLyric = _lyrics[_currentLineIndex].text;
    
    return Positioned(
      top: carMode ? 100 : 50,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: _toggleVisibility,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: carMode ? 80 : 40,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: carMode ? 40 : 20,
            vertical: carMode ? 24 : 12,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(widget.opacity),
            borderRadius: BorderRadius.circular(carMode ? 20 : 12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            currentLyric,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: carMode ? 36 : widget.fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
