import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import '../services/lyrics_service.dart';
import '../services/music_player_background_task.dart';
import '../models/jellyfin_models.dart';

class DesktopLyrics extends ConsumerStatefulWidget {
  final double opacity;
  final double fontSize;
  final bool isVisible;
  
  const DesktopLyrics({
    Key? key,
    this.opacity = 0.8,
    this.fontSize = 24,
    required this.isVisible,
  }) : super(key: key);

  @override
  ConsumerState<DesktopLyrics> createState() => _DesktopLyricsState();
}

class _DesktopLyricsState extends ConsumerState<DesktopLyrics> {
  final LyricsService _lyricsService = GetIt.instance<LyricsService>();
  final MusicPlayerBackgroundTask _audioHandler = GetIt.instance<MusicPlayerBackgroundTask>();
  
  List<LyricLine> _lyrics = [];
  int _currentLineIndex = -1;
  bool _isDragging = false;
  bool _isLocked = false;
  double _opacity = 0.8;
  double _fontSize = 24;
  Offset _position = Offset(0, 0);
  MediaItem? _currentMediaItem;
  bool _isPlaying = false;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  bool _isShuffling = false;
  
  @override
  void initState() {
    super.initState();
    _opacity = widget.opacity;
    _fontSize = widget.fontSize;
    _loadLyrics();
    _listenToPlaybackState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初始化桌面歌词位置，靠下居中显示
    _initializePosition();
    // 根据屏幕大小调整字体大小
    _adjustFontSizeForScreen();
  }
  
  void _initializePosition() {
    final screenSize = MediaQuery.of(context).size;
    // 计算靠下居中的位置
    final desktopLyricsWidth = 300.0; // 桌面歌词的大致宽度
    final centerX = (screenSize.width - desktopLyricsWidth) / 2;
    // 根据屏幕高度动态调整距离底部的距离
    final bottomY = screenSize.height - (screenSize.height * 0.2); // 距离底部20%屏幕高度
    
    setState(() {
      _position = Offset(centerX, bottomY);
    });
  }
  
  void _adjustFontSizeForScreen() {
    final screenSize = MediaQuery.of(context).size;
    // 根据屏幕宽度调整字体大小
    final screenWidth = screenSize.width;
    // 字体大小与屏幕宽度成正比，确保在不同尺寸的屏幕上都能正常显示
    final calculatedFontSize = screenWidth * 0.06; // 字体大小为屏幕宽度的6%
    
    setState(() {
      _fontSize = calculatedFontSize.clamp(16.0, 40.0); // 字体大小范围：16-40
    });
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
          _currentMediaItem = mediaItem;
        });
      }
    } catch (e) {
      print('Error loading desktop lyrics: $e');
    }
  }
  
  void _listenToPlaybackState() {
    // 监听播放状态变化，确保与播放进度完全同步
    _audioHandler.playbackState.listen((state) {
      final position = state.position;
      setState(() {
        _isPlaying = state.playing;
        _repeatMode = state.repeatMode;
        _isShuffling = state.shuffleMode == AudioServiceShuffleMode.all;
      });
      // 立即更新当前歌词行，确保与播放进度完全同步
      _updateCurrentLine(position);
    });
    
    // 监听媒体项变化
    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        _loadLyrics();
        _currentLineIndex = -1;
      }
    });
  }
  
  void _updateCurrentLine(Duration position) {
    if (_lyrics.isEmpty) return;
    
    // 精确匹配歌词时间，使用歌曲当前播放时间去匹配歌词时间
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
  
  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
    });
  }
  
  void _adjustOpacity(double change) {
    setState(() {
      _opacity = (_opacity + change).clamp(0.3, 1.0);
    });
  }
  
  void _adjustFontSize(double change) {
    setState(() {
      _fontSize = (_fontSize + change).clamp(16, 40);
    });
  }
  
  void _onPanStart(DragStartDetails details) {
    if (!_isLocked) {
      setState(() {
        _isDragging = true;
      });
    }
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isLocked && _isDragging) {
      setState(() {
        _position += details.delta;
      });
    }
  }
  
  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }
  
  void _playPause() {
    if (_isPlaying) {
      _audioHandler.pause();
    } else {
      _audioHandler.play();
    }
  }
  
  void _previous() {
    _audioHandler.skipToPrevious();
  }
  
  void _next() {
    _audioHandler.skipToNext();
  }
  
  void _toggleRepeat() {
    AudioServiceRepeatMode newMode;
    switch (_repeatMode) {
      case AudioServiceRepeatMode.none:
        newMode = AudioServiceRepeatMode.all;
        break;
      case AudioServiceRepeatMode.all:
        newMode = AudioServiceRepeatMode.one;
        break;
      case AudioServiceRepeatMode.one:
        newMode = AudioServiceRepeatMode.none;
        break;
      default:
        newMode = AudioServiceRepeatMode.none;
    }
    _audioHandler.setRepeatMode(newMode);
  }
  
  void _toggleShuffle() {
    _audioHandler.setShuffleMode(
      _isShuffling ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || _lyrics.isEmpty || _currentLineIndex == -1) {
      return Container();
    }
    
    final currentLyric = _lyrics[_currentLineIndex].text;
    final screenSize = MediaQuery.of(context).size;
    
    // 确保悬浮歌词在屏幕范围内
    final constrainedPosition = Offset(
      _position.dx.clamp(20, screenSize.width - 320), // 320是桌面歌词的大致宽度
      _position.dy.clamp(20, screenSize.height - 200),
    );
    
    return Positioned(
      left: constrainedPosition.dx,
      top: constrainedPosition.dy,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(_opacity),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 歌曲信息
              if (_currentMediaItem != null)
                Text(
                  '${_currentMediaItem!.title} - ${_currentMediaItem!.artist}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              
              // 歌词显示
              SizedBox(height: 8),
              Text(
                currentLyric,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _fontSize,
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
              
              // 控制按钮
              SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 上一曲
                  IconButton(
                    icon: Icon(Icons.skip_previous, size: 18),
                    onPressed: _previous,
                    color: Colors.white,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  
                  // 播放/暂停
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 24),
                    onPressed: _playPause,
                    color: Colors.white,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  
                  // 下一曲
                  IconButton(
                    icon: Icon(Icons.skip_next, size: 18),
                    onPressed: _next,
                    color: Colors.white,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // 循环模式
                  IconButton(
                    icon: Icon(
                      _repeatMode == AudioServiceRepeatMode.none ? Icons.repeat :
                      _repeatMode == AudioServiceRepeatMode.one ? Icons.repeat_one :
                      Icons.repeat,
                      size: 18,
                    ),
                    onPressed: _toggleRepeat,
                    color: _repeatMode == AudioServiceRepeatMode.none ? Colors.white54 : Colors.white,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  
                  // 随机播放
                  IconButton(
                    icon: Icon(Icons.shuffle, size: 18),
                    onPressed: _toggleShuffle,
                    color: _isShuffling ? Colors.white : Colors.white54,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // 透明度减
                  IconButton(
                    icon: Icon(Icons.opacity, size: 16),
                    onPressed: () => _adjustOpacity(-0.1),
                    color: Colors.white,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  
                  // 锁定/解锁
                  IconButton(
                    icon: Icon(_isLocked ? Icons.lock : Icons.lock_open, size: 16),
                    onPressed: _toggleLock,
                    color: Colors.white,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  
                  // 透明度加
                  IconButton(
                    icon: Icon(Icons.opacity, size: 16),
                    onPressed: () => _adjustOpacity(0.1),
                    color: Colors.white,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  
                  SizedBox(width: 8),
                  
                  // 字体减小
                  IconButton(
                    icon: Icon(Icons.text_decrease, size: 16),
                    onPressed: () => _adjustFontSize(-2),
                    color: Colors.white,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  
                  // 字体增大
                  IconButton(
                    icon: Icon(Icons.text_increase, size: 16),
                    onPressed: () => _adjustFontSize(2),
                    color: Colors.white,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
