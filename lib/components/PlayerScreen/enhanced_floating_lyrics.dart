import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import '../../services/lyrics_service.dart';
import '../../services/music_player_background_task.dart';
import '../../models/jellyfin_models.dart';
import '../../services/car_mode_helper.dart';

class EnhancedFloatingLyrics extends ConsumerStatefulWidget {
  final double opacity;
  final double fontSize;
  final bool isCarMode;
  final bool isVisible;
  
  const EnhancedFloatingLyrics({
    Key? key,
    this.opacity = 0.8,
    this.fontSize = 24,
    required this.isCarMode,
    required this.isVisible,
  }) : super(key: key);

  @override
  ConsumerState<EnhancedFloatingLyrics> createState() => _EnhancedFloatingLyricsState();
}

class _EnhancedFloatingLyricsState extends ConsumerState<EnhancedFloatingLyrics> {
  final LyricsService _lyricsService = GetIt.instance<LyricsService>();
  final MusicPlayerBackgroundTask _audioHandler = GetIt.instance<MusicPlayerBackgroundTask>();
  final CarModeHelper _carModeHelper = GetIt.instance<CarModeHelper>();
  
  List<LyricLine> _lyrics = [];
  int _currentLineIndex = -1;
  bool _isDragging = false;
  bool _isLocked = false;
  double _opacity = 0.8;
  Offset _position = Offset(0, 100);
  
  @override
  void initState() {
    super.initState();
    _opacity = widget.opacity;
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
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || _lyrics.isEmpty || _currentLineIndex == -1) {
      return Container();
    }
    
    final carMode = widget.isCarMode;
    final currentLyric = _lyrics[_currentLineIndex].text;
    final screenSize = MediaQuery.of(context).size;
    
    // 确保悬浮歌词在屏幕范围内
    final constrainedPosition = Offset(
      _position.dx.clamp(20, screenSize.width - 20),
      _position.dy.clamp(20, screenSize.height - 100),
    );
    
    return Positioned(
      left: constrainedPosition.dx,
      top: constrainedPosition.dy,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: carMode ? 40 : 20,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: carMode ? 30 : 16,
            vertical: carMode ? 20 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(_opacity),
            borderRadius: BorderRadius.circular(carMode ? 16 : 10),
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
              // 歌词显示
              Text(
                currentLyric,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: carMode ? 32 : widget.fontSize,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 透明度减
                  IconButton(
                    icon: Icon(Icons.opacity, size: 16),
                    onPressed: () => _adjustOpacity(-0.1),
                    color: Colors.white,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                  
                  // 锁定/解锁
                  IconButton(
                    icon: Icon(_isLocked ? Icons.lock : Icons.lock_open, size: 16),
                    onPressed: _toggleLock,
                    color: Colors.white,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                  
                  // 透明度加
                  IconButton(
                    icon: Icon(Icons.opacity, size: 16),
                    onPressed: () => _adjustOpacity(0.1),
                    color: Colors.white,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 24, minHeight: 24),
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
