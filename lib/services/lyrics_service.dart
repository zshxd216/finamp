import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/jellyfin_models.dart';

class LyricsService {
  static final LyricsService _instance = LyricsService._internal();
  factory LyricsService() => _instance;
  LyricsService._internal();

  // 拉取歌词
  Future<String?> fetchLyrics(BaseItemDto song) async {
    try {
      // 1. 尝试从本地缓存获取歌词
      final cachedLyrics = await _getCachedLyrics(song.id);
      if (cachedLyrics != null) {
        return cachedLyrics;
      }

      // 2. 从网络API获取歌词
      // 这里使用NetEase Cloud Music API作为示例
      // 实际应用中可能需要使用其他API或服务
      final lyrics = await _fetchFromNetEase(song);
      if (lyrics != null) {
        // 缓存歌词
        await _cacheLyrics(song.id, lyrics);
        return lyrics;
      }

      return null;
    } catch (e) {
      print('Error fetching lyrics: $e');
      return null;
    }
  }

  // 从NetEase Cloud Music API获取歌词
  Future<String?> _fetchFromNetEase(BaseItemDto song) async {
    try {
      // 构建搜索查询
      final artistsString = song.artists != null
          ? song.artists!.map((a) => a is String ? a : (a as dynamic).name ?? '').join(' ')
          : '';
      final query = '${song.name} $artistsString';
      final encodedQuery = Uri.encodeComponent(query);
      
      // 搜索歌曲
      final searchUrl = 'https://api.music.liuzhijin.cn/search?keywords=$encodedQuery&type=1';
      final searchResponse = await http.get(Uri.parse(searchUrl));
      
      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);
        final songs = searchData['result']['songs'] as List;
        
        if (songs.isNotEmpty) {
          final songId = songs[0]['id'];
          
          // 获取歌词
          final lyricsUrl = 'https://api.music.liuzhijin.cn/lyric?id=$songId';
          final lyricsResponse = await http.get(Uri.parse(lyricsUrl));
          
          if (lyricsResponse.statusCode == 200) {
            final lyricsData = jsonDecode(lyricsResponse.body);
            final lrc = lyricsData['lrc']['lyric'] as String;
            return lrc;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error fetching lyrics from NetEase: $e');
      return null;
    }
  }

  // 缓存歌词到本地
  Future<void> _cacheLyrics(String songId, String lyrics) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final lyricsDir = Directory('${directory.path}/lyrics');
      
      if (!lyricsDir.existsSync()) {
        lyricsDir.createSync(recursive: true);
      }
      
      final file = File('${lyricsDir.path}/$songId.lrc');
      await file.writeAsString(lyrics);
    } catch (e) {
      print('Error caching lyrics: $e');
    }
  }

  // 从本地缓存获取歌词
  Future<String?> _getCachedLyrics(String songId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/lyrics/$songId.lrc');
      
      if (file.existsSync()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      print('Error getting cached lyrics: $e');
      return null;
    }
  }

  // 解析LRC格式歌词
  List<LyricLine> parseLrc(String lrcContent) {
    final lines = <LyricLine>[];
    final lrcLines = lrcContent.split('\n');
    
    for (final line in lrcLines) {
      final match = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)').firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();
        
        final duration = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );
        
        lines.add(LyricLine(duration: duration, text: text));
      }
    }
    
    return lines;
  }
}

class LyricLine {
  final Duration duration;
  final String text;
  
  LyricLine({required this.duration, required this.text});
}
