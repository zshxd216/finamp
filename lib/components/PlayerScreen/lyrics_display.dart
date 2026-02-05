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
  final ScrollController _scrollController = ScrollController();
  
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
      
      // 立即触发滚动，确保歌词与播放进度实时同步
      _scrollToCurrentLine();
    }
  }
  
  void _scrollToCurrentLine() {
    // 自动滚动到当前歌词行
    if (_scrollController.hasClients && _currentLineIndex >= 0) {
      // 计算滚动位置，使当前行居中显示
      final isSmallScreen = MediaQuery.of(context).size.height < 600;
      final itemHeight = widget.isCarMode ? 48.0 : (isSmallScreen ? 24.0 : 32.0);
      final scrollPosition = (_currentLineIndex * itemHeight) - (_scrollController.position.viewportDimension / 2) + (itemHeight / 2);
      
      // 使用更短的动画时间，使滚动更加快速响应
      // 直接跳转到指定位置，无动画，确保与播放进度完全同步
      _scrollController.jumpTo(
        scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent)
      );
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
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          vertical: widget.isCarMode ? 40 : 20,
        ),
        itemCount: _lyrics.length,
        itemBuilder: (context, index) {
          final isCurrentLine = index == _currentLineIndex;
          
          // 根据屏幕尺寸调整歌词行高
          final screenHeight = MediaQuery.of(context).size.height;
          final isSmallScreen = screenHeight < 600;
          
          return Container(
            padding: EdgeInsets.symmetric(
              vertical: widget.isCarMode ? 16 : (isSmallScreen ? 6 : 8),
            ),
            alignment: Alignment.center,
            child: Text(
              _lyrics[index].text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isCurrentLine 
                  ? widget.isCarMode ? 32 : (isSmallScreen ? 18 : 20) * widget.fontScale 
                  : widget.isCarMode ? 24 : (isSmallScreen ? 14 : 16) * widget.fontScale,
                fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                color: isCurrentLine 
                  ? Theme.of(context).primaryColor 
                  : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                height: widget.isCarMode ? 1.6 : (isSmallScreen ? 1.4 : 1.5),
                letterSpacing: widget.isCarMode ? 0.5 : 0,
              ),
            ),
          );
        },
      ),
    );
  }
}
