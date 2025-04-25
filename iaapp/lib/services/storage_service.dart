import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_model.dart';

class StorageService {
  // 键名常量
  static const String favoriteVideosKey = 'favorite_videos';
  static const String watchHistoryKey = 'watch_history';
  static const String downloadedVideosKey = 'downloaded_videos';
  
  // 获取收藏的视频列表
  Future<List<Video>> getFavoriteVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(favoriteVideosKey) ?? [];
      
      return favoritesJson
          .map((json) => Video.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('获取收藏视频失败: $e');
      return [];
    }
  }
  
  // 添加视频到收藏
  Future<bool> addToFavorites(Video video) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取已保存的收藏列表
      List<String> favoritesJson = prefs.getStringList(favoriteVideosKey) ?? [];
      
      // 检查视频是否已经收藏，避免重复
      final videoJson = jsonEncode({
        'vod_id': video.id,
        'vod_name': video.title,
        'vod_pic': video.cover,
        'type_name': video.category,
        'vod_remarks': video.updateTime,
        'vod_director': video.director,
        'vod_actor': video.actor,
        'vod_content': video.description,
        'vod_year': video.year,
        'vod_area': video.area,
        'vod_lang': video.language,
        'vod_play_url': video.playUrl,
      });
      
      // 检查是否已存在该视频（根据ID）
      bool alreadyExists = false;
      for (var i = 0; i < favoritesJson.length; i++) {
        final existingVideo = jsonDecode(favoritesJson[i]);
        if (existingVideo['vod_id'] == video.id) {
          alreadyExists = true;
          break;
        }
      }
      
      // 如果不存在才添加
      if (!alreadyExists) {
        favoritesJson.add(videoJson);
        await prefs.setStringList(favoriteVideosKey, favoritesJson);
        return true; // 添加成功
      }
      
      return false; // 已经存在，无需添加
    } catch (e) {
      print('添加收藏失败: $e');
      return false;
    }
  }
  
  // 从收藏中移除视频
  Future<bool> removeFromFavorites(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取已保存的收藏列表
      List<String> favoritesJson = prefs.getStringList(favoriteVideosKey) ?? [];
      
      // 找到并删除匹配ID的视频
      bool found = false;
      List<String> updatedList = [];
      
      for (var json in favoritesJson) {
        final video = jsonDecode(json);
        if (video['vod_id'] != videoId) {
          updatedList.add(json);
        } else {
          found = true;
        }
      }
      
      // 如果找到并删除了视频，更新存储
      if (found) {
        await prefs.setStringList(favoriteVideosKey, updatedList);
        return true;
      }
      
      return false; // 未找到视频
    } catch (e) {
      print('移除收藏失败: $e');
      return false;
    }
  }
  
  // 检查视频是否已收藏
  Future<bool> isVideoFavorited(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(favoriteVideosKey) ?? [];
      
      for (var json in favoritesJson) {
        final video = jsonDecode(json);
        if (video['vod_id'] == videoId) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('检查视频收藏状态失败: $e');
      return false;
    }
  }
  
  // 切换视频收藏状态
  Future<bool> toggleFavorite(Video video) async {
    final isFavorited = await isVideoFavorited(video.id);
    
    if (isFavorited) {
      return await removeFromFavorites(video.id);
    } else {
      return await addToFavorites(video);
    }
  }
  
  // 获取观看历史
  Future<List<Video>> getWatchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(watchHistoryKey) ?? [];
      
      // 将JSON字符串转换为Video对象列表
      return historyJson
          .map((json) => Video.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('获取观看历史失败: $e');
      return [];
    }
  }
  
  // 添加到观看历史
  Future<bool> addToWatchHistory(Video video, {String? position, String? episode, String? watchTime}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取已有的历史记录
      List<String> historyJson = prefs.getStringList(watchHistoryKey) ?? [];
      
      // 创建视频对象的JSON表示，并添加观看位置和时间信息
      final videoData = {
        'vod_id': video.id,
        'vod_name': video.title,
        'vod_pic': video.cover,
        'type_name': video.category,
        'vod_remarks': video.updateTime,
        'vod_director': video.director,
        'vod_actor': video.actor,
        'vod_content': video.description,
        'vod_year': video.year,
        'vod_area': video.area,
        'vod_lang': video.language,
        'vod_play_url': video.playUrl,
        'vod_play_from': video.playSources.isEmpty ? '' : video.playSources.join(r'$$$'),
        'watch_position': position ?? video.watchPosition ?? '0', // 观看位置（秒）
        'watch_episode': episode ?? video.watchEpisode ?? '1', // 观看集数
        'watch_time': watchTime ?? DateTime.now().toIso8601String(), // 观看时间
      };
      
      // 检查是否已存在该视频（根据ID）
      bool alreadyExists = false;
      int existingIndex = -1;
      
      for (var i = 0; i < historyJson.length; i++) {
        final existingVideo = jsonDecode(historyJson[i]);
        if (existingVideo['vod_id'] == video.id) {
          alreadyExists = true;
          existingIndex = i;
          break;
        }
      }
      
      final newVideoJson = jsonEncode(videoData);
      
      // 如果已存在，则更新记录并移动到列表最前面
      if (alreadyExists && existingIndex >= 0) {
        historyJson.removeAt(existingIndex);
        historyJson.insert(0, newVideoJson);
      } else {
        // 如果不存在，则添加到列表开头
        historyJson.insert(0, newVideoJson);
        
        // 限制历史记录数量（保留最近的100条）
        if (historyJson.length > 100) {
          historyJson = historyJson.sublist(0, 100);
        }
      }
      
      // 保存更新后的历史记录
      await prefs.setStringList(watchHistoryKey, historyJson);
      return true;
    } catch (e) {
      print('添加观看历史失败: $e');
      return false;
    }
  }
  
  // 更新观看进度
  Future<bool> updateWatchProgress(String videoId, {String? position, String? episode}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取已保存的历史记录
      List<String> historyJson = prefs.getStringList(watchHistoryKey) ?? [];
      
      // 查找匹配ID的视频
      bool found = false;
      for (var i = 0; i < historyJson.length; i++) {
        final videoData = jsonDecode(historyJson[i]);
        if (videoData['vod_id'] == videoId) {
          // 更新观看进度和时间
          videoData['watch_position'] = position ?? videoData['watch_position'];
          videoData['watch_episode'] = episode ?? videoData['watch_episode'];
          videoData['watch_time'] = DateTime.now().toIso8601String();
          
          // 更新记录
          historyJson[i] = jsonEncode(videoData);
          
          // 将该记录移到列表最前面
          final record = historyJson.removeAt(i);
          historyJson.insert(0, record);
          
          found = true;
          break;
        }
      }
      
      // 如果找到并更新了视频，保存记录
      if (found) {
        await prefs.setStringList(watchHistoryKey, historyJson);
        return true;
      }
      
      return false; // 未找到视频
    } catch (e) {
      print('更新观看进度失败: $e');
      return false;
    }
  }
  
  // 获取特定视频的观看进度
  Future<Map<String, String>> getWatchProgress(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(watchHistoryKey) ?? [];
      
      for (var json in historyJson) {
        final videoData = jsonDecode(json);
        if (videoData['vod_id'] == videoId) {
          return {
            'position': videoData['watch_position']?.toString() ?? '0',
            'episode': videoData['watch_episode']?.toString() ?? '1',
            'time': videoData['watch_time']?.toString() ?? DateTime.now().toIso8601String(),
          };
        }
      }
      
      // 如果没有找到，返回默认值
      return {
        'position': '0',
        'episode': '1',
        'time': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('获取观看进度失败: $e');
      return {
        'position': '0',
        'episode': '1',
        'time': DateTime.now().toIso8601String(),
      };
    }
  }
  
  // 从观看历史中移除视频
  Future<bool> removeFromWatchHistory(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取已保存的历史记录
      List<String> historyJson = prefs.getStringList(watchHistoryKey) ?? [];
      
      // 找到并删除匹配ID的视频
      bool found = false;
      List<String> updatedList = [];
      
      for (var json in historyJson) {
        final video = jsonDecode(json);
        if (video['vod_id'] != videoId) {
          updatedList.add(json);
        } else {
          found = true;
        }
      }
      
      // 如果找到并删除了视频，更新存储
      if (found) {
        await prefs.setStringList(watchHistoryKey, updatedList);
        return true;
      }
      
      return false; // 未找到视频
    } catch (e) {
      print('移除观看历史失败: $e');
      return false;
    }
  }
  
  // 清空观看历史
  Future<bool> clearWatchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(watchHistoryKey, []);
      return true;
    } catch (e) {
      print('清空观看历史失败: $e');
      return false;
    }
  }
  
  // 移除多个观看历史记录
  Future<bool> removeMultipleFromWatchHistory(List<String> videoIds) async {
    try {
      if (videoIds.isEmpty) return true;
      
      final prefs = await SharedPreferences.getInstance();
      
      // 获取已保存的历史记录
      List<String> historyJson = prefs.getStringList(watchHistoryKey) ?? [];
      
      // 找到并删除匹配ID的视频
      List<String> updatedList = [];
      
      for (var json in historyJson) {
        final video = jsonDecode(json);
        if (!videoIds.contains(video['vod_id'])) {
          updatedList.add(json);
        }
      }
      
      // 更新存储
      await prefs.setStringList(watchHistoryKey, updatedList);
      return true;
    } catch (e) {
      print('移除多个观看历史失败: $e');
      return false;
    }
  }
  
  // 获取已下载的视频列表
  Future<List<Video>> getDownloadedVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadedJson = prefs.getStringList(downloadedVideosKey) ?? [];
      
      return downloadedJson
          .map((json) => Video.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('获取下载视频失败: $e');
      return [];
    }
  }
  
  // 添加视频到下载列表
  Future<bool> addToDownloads(Video video, {String? fileSize, String? downloadTime}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取已下载视频列表
      List<String> downloadedJson = prefs.getStringList(downloadedVideosKey) ?? [];
      
      // 创建视频对象的JSON表示，包含文件大小和下载时间信息
      final videoData = {
        'vod_id': video.id,
        'vod_name': video.title,
        'vod_pic': video.cover,
        'type_name': video.category,
        'vod_remarks': video.updateTime,
        'vod_director': video.director,
        'vod_actor': video.actor,
        'vod_content': video.description,
        'vod_year': video.year,
        'vod_area': video.area,
        'vod_lang': video.language,
        'vod_play_url': video.playUrl,
        'file_size': fileSize ?? '0', // 文件大小（MB）
        'download_time': downloadTime ?? DateTime.now().toIso8601String(), // 下载时间
      };
      
      // 检查是否已存在该视频（根据ID）
      bool alreadyExists = false;
      
      for (var i = 0; i < downloadedJson.length; i++) {
        final existingVideo = jsonDecode(downloadedJson[i]);
        if (existingVideo['vod_id'] == video.id) {
          alreadyExists = true;
          break;
        }
      }
      
      // 如果不存在才添加
      if (!alreadyExists) {
        downloadedJson.add(jsonEncode(videoData));
        await prefs.setStringList(downloadedVideosKey, downloadedJson);
        return true; // 添加成功
      }
      
      return false; // 已经存在，无需添加
    } catch (e) {
      print('添加下载失败: $e');
      return false;
    }
  }
  
  // 从下载列表中移除视频
  Future<bool> removeFromDownloads(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取已下载视频列表
      List<String> downloadedJson = prefs.getStringList(downloadedVideosKey) ?? [];
      
      // 找到并删除匹配ID的视频
      bool found = false;
      List<String> updatedList = [];
      
      for (var json in downloadedJson) {
        final video = jsonDecode(json);
        if (video['vod_id'] != videoId) {
          updatedList.add(json);
        } else {
          found = true;
        }
      }
      
      // 如果找到并删除了视频，更新存储
      if (found) {
        await prefs.setStringList(downloadedVideosKey, updatedList);
        return true;
      }
      
      return false; // 未找到视频
    } catch (e) {
      print('移除下载失败: $e');
      return false;
    }
  }
  
  // 检查视频是否已下载
  Future<bool> isVideoDownloaded(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadedJson = prefs.getStringList(downloadedVideosKey) ?? [];
      
      for (var json in downloadedJson) {
        final video = jsonDecode(json);
        if (video['vod_id'] == videoId) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('检查视频下载状态失败: $e');
      return false;
    }
  }
} 