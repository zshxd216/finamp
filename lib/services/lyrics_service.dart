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
      print('开始获取歌词: ${song.name}');
      
      // 1. 尝试从本地缓存获取歌词
      final cachedLyrics = await _getCachedLyrics(song.id);
      if (cachedLyrics != null) {
        print('从缓存获取歌词成功');
        return cachedLyrics;
      }
      print('缓存中未找到歌词');

      // 2. 从网络API获取歌词
      // 尝试多个歌词源
      final lyrics = await _fetchFromMultipleSources(song);
      if (lyrics != null) {
        // 缓存歌词
        await _cacheLyrics(song.id, lyrics);
        print('从网络获取歌词成功并缓存');
        return lyrics;
      }

      print('所有歌词源均失败');
      return null;
    } catch (e) {
      print('Error fetching lyrics: $e');
      return null;
    }
  }

  // 从多个来源获取歌词
  Future<String?> _fetchFromMultipleSources(BaseItemDto song) async {
    // 构建搜索查询
    final artistsString = song.artists != null
        ? song.artists!.map((a) => a is String ? a : (a as dynamic).name ?? '').join(' ')
        : '';
    final query = '${song.name} $artistsString';
    print('搜索查询: $query');
    
    // 尝试不同的歌词源
    // 1. 尝试备用的NetEase API
    var lyrics = await _fetchFromAlternativeNetEase(song, query);
    if (lyrics != null) return lyrics;
    
    // 2. 尝试其他备用源（可以根据需要添加）
    // lyrics = await _fetchFromOtherSource(song, query);
    // if (lyrics != null) return lyrics;
    
    return null;
  }

  // 从备用的NetEase Cloud Music API获取歌词
  Future<String?> _fetchFromAlternativeNetEase(BaseItemDto song, String query) async {
    try {
      // 使用备用的API地址
      final encodedQuery = Uri.encodeComponent(query);
      
      // 尝试不同的API端点
      final apiEndpoints = [
        'https://music.163.com/api/search/get',
        'https://api.music.liuzhijin.cn',
        'https://netease-cloud-music-api-git-master-zhao-hui.vercel.app'
      ];
      
      for (final endpoint in apiEndpoints) {
        try {
          print('尝试API: $endpoint');
          
          // 构建搜索URL
          String searchUrl;
          if (endpoint.contains('163.com')) {
            // 网易云官方API格式
            searchUrl = '$endpoint?s=$encodedQuery&type=1&offset=0&limit=1';
          } else {
            // 其他API格式
            searchUrl = '$endpoint/search?keywords=$encodedQuery&type=1';
          }
          
          final searchResponse = await http.get(
            Uri.parse(searchUrl),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
          ).timeout(Duration(seconds: 5));
          
          print('API响应状态: ${searchResponse.statusCode}');
          
          if (searchResponse.statusCode == 200) {
            final searchData = jsonDecode(searchResponse.body);
            print('API响应数据: ${searchData.keys}');
            
            // 处理不同API的响应格式
            dynamic songs;
            if (searchData.containsKey('result') && searchData['result'].containsKey('songs')) {
              songs = searchData['result']['songs'];
            } else if (searchData.containsKey('songs')) {
              songs = searchData['songs'];
            }
            
            if (songs is List && songs.isNotEmpty) {
              final songId = songs[0]['id'];
              print('找到歌曲ID: $songId');
              
              // 获取歌词
              String lyricsUrl;
              if (endpoint.contains('163.com')) {
                lyricsUrl = 'https://music.163.com/api/song/lyric?id=$songId&lv=1&kv=1&tv=-1';
              } else {
                lyricsUrl = '$endpoint/lyric?id=$songId';
              }
              
              final lyricsResponse = await http.get(
                Uri.parse(lyricsUrl),
                headers: {
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                }
              ).timeout(Duration(seconds: 5));
              
              if (lyricsResponse.statusCode == 200) {
                final lyricsData = jsonDecode(lyricsResponse.body);
                print('歌词API响应: ${lyricsData.keys}');
                
                // 处理不同格式的歌词数据
                String? lrc;
                if (lyricsData.containsKey('lrc') && lyricsData['lrc'].containsKey('lyric')) {
                  lrc = lyricsData['lrc']['lyric'] as String;
                } else if (lyricsData.containsKey('tlyric') && lyricsData['tlyric'].containsKey('lyric')) {
                  lrc = lyricsData['tlyric']['lyric'] as String;
                }
                
                if (lrc != null && lrc.isNotEmpty) {
                  print('获取歌词成功');
                  return lrc;
                }
              }
            }
          }
        } catch (e) {
          print('备用API失败: $e');
          // 继续尝试下一个API
          continue;
        }
      }
      
      return null;
    } catch (e) {
      print('Error fetching lyrics from alternative sources: $e');
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
      print('歌词缓存成功: $songId');
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
