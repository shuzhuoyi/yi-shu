import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CacheService {
  // 获取当前应用缓存大小
  Future<String> getCacheSize() async {
    try {
      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      // 获取缓存图片目录
      final cacheDir = Directory('${tempDir.path}/libCachedImageData');
      
      double totalSize = 0;
      
      // 计算缓存图片大小
      if (await cacheDir.exists()) {
        final entities = await cacheDir.list(recursive: true).toList();
        for (var entity in entities) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      
      // 获取SharedPreferences大小（这是一个近似值）
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (var key in keys) {
        var value = prefs.get(key);
        if (value is String) {
          totalSize += value.length;
        } else if (value is List<String>) {
          for (var item in value) {
            totalSize += item.length;
          }
        }
      }
      
      // 转换为合适的单位
      return _formatSize(totalSize);
    } catch (e) {
      debugPrint('获取缓存大小失败: $e');
      return '0 B';
    }
  }
  
  // 格式化大小显示
  String _formatSize(double size) {
    const units = ['B', 'KB', 'MB', 'GB'];
    int index = 0;
    
    while (size > 1024 && index < units.length - 1) {
      size /= 1024;
      index++;
    }
    
    return '${size.toStringAsFixed(2)} ${units[index]}';
  }
  
  // 清理缓存
  Future<bool> clearCache() async {
    try {
      // 清理图片缓存
      imageCache.clear();
      imageCache.clearLiveImages();
      await CachedNetworkImage.evictFromCache('');
      
      // 清理临时文件
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final cacheDir = Directory('${tempDir.path}/libCachedImageData');
        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
        }
      }
      
      // 注意：我们不清理SharedPreferences，因为它包含用户设置和收藏等重要数据
      // 如果需要清理特定的SharedPreferences数据，应该单独处理
      
      return true;
    } catch (e) {
      debugPrint('清理缓存失败: $e');
      return false;
    }
  }
  
  // 获取视频缓存大小（如果应用支持视频下载功能）
  Future<String> getVideoCacheSize() async {
    try {
      // 获取应用文档目录
      final docDir = await getApplicationDocumentsDirectory();
      // 假设视频下载到 "downloads" 子目录
      final videoCacheDir = Directory('${docDir.path}/downloads');
      
      double totalSize = 0;
      
      if (await videoCacheDir.exists()) {
        final entities = await videoCacheDir.list(recursive: true).toList();
        for (var entity in entities) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      
      return _formatSize(totalSize);
    } catch (e) {
      debugPrint('获取视频缓存大小失败: $e');
      return '0 B';
    }
  }
  
  // 清理视频缓存
  Future<bool> clearVideoCache() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final videoCacheDir = Directory('${docDir.path}/downloads');
      
      if (await videoCacheDir.exists()) {
        await videoCacheDir.delete(recursive: true);
        await videoCacheDir.create();
      }
      
      return true;
    } catch (e) {
      debugPrint('清理视频缓存失败: $e');
      return false;
    }
  }
}