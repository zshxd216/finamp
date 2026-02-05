import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../../services/lyrics_service.dart';
import '../../services/music_player_background_task.dart';
import '../../models/jellyfin_models.dart';

class LyricsDisplay extends ConsumerStatefulWidget {
  final bool isCarMode;
  final double fontScale;
  
  const LyricsDisplay({
    Key? key,
    required this.isCarMode,
    this.fontScale = 1.0,
  }) : super(key: key);

  @override
  ConsumerState<LyricsDisplay> createState() => _LyricsDisplayState();
}

class _LyricsDisplayState extends ConsumerState<LyricsDisplay> {
  final LyricsService _lyricsService = GetIt.instance<LyricsService>();
  final MusicPlayerBackgroundTask _audioHandler = GetIt.instance<MusicPlayerBackgroundTask>();
  
  List<LyricLine> _lyrics = [];
  int _currentLineIndex = -1;
  bool _isLoading = false;
  String? _error;
  
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
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final item = BaseItemDto.fromJson(mediaItem.extras!["itemJson"]);
      final lrcContent = await _lyricsService.fetchLyrics(item);
      
      if (lrcContent != null) {
        setState(() {
          _lyrics = _lyricsService.parseLrc(lrcContent);
        });
      } else {
        setState(() {
          _error = "No lyrics found";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error loading lyrics";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _listenToPlaybackState() {
    // 监听播放状态变化，包括进度变化
    _audioHandler.playbackState.listen((state) {
      final position = state.position;
      print('播放状态变化，位置: $position');
      _updateCurrentLine(position);
    });
    
    // 监听媒体项变化
    _audioHandler.mediaItem.listen((_) {
      print('媒体项变化，重新加载歌词');
      _loadLyrics();
      _currentLineIndex = -1;
    });
    
    // 监听播放状态的所有变化，确保拖动进度条后能同步
    _audioHandler.playbackState.listen((state) {
      final position = state.position;
      print('播放状态详细变化，状态: ${state.processingState}, 位置: $position');
      _updateCurrentLine(position);
    });
  }
  
  // 手动更新歌词进度
  void updateLyricsProgress(Duration position) {
    _updateCurrentLine(position);
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
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: widget.isCarMode
            ? SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                ),
              )
            : const CircularProgressIndicator(),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: widget.isCarMode ? 24 : 16 * widget.fontScale,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
      );
    }
    
    if (_lyrics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "No lyrics available",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: widget.isCarMode ? 24 : 16,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCarMode ? 60 : 20,
      ),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          vertical: widget.isCarMode ? 40 : 20,
        ),
        itemCount: _lyrics.length,
        itemBuilder: (context, index) {
          final isCurrentLine = index == _currentLineIndex;
          
          return Container(
            padding: EdgeInsets.symmetric(
              vertical: widget.isCarMode ? 16 : 8,
            ),
            alignment: Alignment.center,
            child: Text(
              _lyrics[index].text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isCurrentLine 
                  ? widget.isCarMode ? 32 : 20 * widget.fontScale 
                  : widget.isCarMode ? 24 : 16 * widget.fontScale,
                fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                color: isCurrentLine 
                  ? Theme.of(context).primaryColor 
                  : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                height: widget.isCarMode ? 1.6 : 1.5,
                letterSpacing: widget.isCarMode ? 0.5 : 0,
              ),
            ),
          );
        },
      ),
    );
  }
}
