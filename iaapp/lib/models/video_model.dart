import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class Video {
  final String id;
  final String title;
  final String cover;
  final String category;
  final String updateTime;
  final String director;
  final String actor;
  final String description;
  final String year;
  final String area;
  final String language;
  final String playUrl;
  final List<String> playSources; // 播放源列表
  final List<String> playUrlList; // 播放地址列表
  final List<String> playNotes; // 选集名称列表
  final String? fileSize; // 下载文件大小（MB）
  final String? downloadTime; // 下载时间
  final String? watchPosition; // 观看进度（秒）
  final String? watchEpisode; // 观看的集数
  final String? watchTime; // 最近观看时间
  
  Video({
    required this.id,
    required this.title,
    required this.cover,
    required this.category,
    this.updateTime = '',
    this.director = '',
    this.actor = '',
    this.description = '',
    this.year = '',
    this.area = '',
    this.language = '',
    this.playUrl = '',
    this.playSources = const [],
    this.playUrlList = const [],
    this.playNotes = const [],
    this.fileSize,
    this.downloadTime,
    this.watchPosition,
    this.watchEpisode,
    this.watchTime,
  });
  
  factory Video.fromJson(Map<String, dynamic> json) {
    try {
      // 打印整个JSON数据
      print('解析视频数据，键列表: ${json.keys.toList()}');
      
      // 获取ID - 必须字段
      String id = '';
      if (json.containsKey('vod_id') && json['vod_id'] != null) {
        id = json['vod_id'].toString().trim();
      } else if (json.containsKey('id') && json['id'] != null) {
        id = json['id'].toString().trim();
      } else {
        print('警告: 视频数据缺少ID字段');
        id = DateTime.now().millisecondsSinceEpoch.toString(); // 生成临时ID
      }
      
      // 获取标题 - 必须字段
      String title = '';
      if (json.containsKey('vod_name') && json['vod_name'] != null) {
        title = json['vod_name'].toString().trim();
      } else if (json.containsKey('name') && json['name'] != null) {
        title = json['name'].toString().trim();
      } else if (json.containsKey('title') && json['title'] != null) {
        title = json['title'].toString().trim();
      } else {
        print('警告: 视频数据缺少标题字段');
        title = '未知标题';
      }
      
      // 获取分类
      String category = '';
      // 优先使用主分类ID (type_id)
      if (json.containsKey('type_id') && json['type_id'] != null) {
        final typeId = json['type_id'].toString().trim();
        
        // 尝试获取type_name (分类名称)，如果没有则使用type_id
        if (json.containsKey('type_name') && json['type_name'] != null) {
          category = json['type_name'].toString().trim();
          print('视频[${title}] ID: $id, 分类=${category}, type_id=${typeId}');
        } else {
          // 没有type_name，直接使用type_id
          category = 'type_id:$typeId';
          print('视频[${title}] ID: $id, 无分类名称, 使用type_id=${typeId}');
        }
      }
      // 次要分类处理 (type_id_1)，目前仅记录日志，不影响主分类
      else if (json.containsKey('type_id_1') && json['type_id_1'] != null && json['type_id_1'].toString() != '0') {
        final typeId1 = json['type_id_1'].toString().trim();
        print('视频[${title}] ID: $id, 使用次要分类type_id_1=${typeId1}');
        category = 'type_id:$typeId1';
      }
      // 其他兜底方案
      else if (json.containsKey('type_name') && json['type_name'] != null) {
        category = json['type_name'].toString().trim();
      } else if (json.containsKey('category') && json['category'] != null) {
        category = json['category'].toString().trim();
      } else if (json.containsKey('class') && json['class'] != null) {
        category = json['class'].toString().trim();
      } else {
        print('警告: 视频 $title 缺少分类字段');
        category = '未分类';
      }
      
      // 获取更新时间
      String updateTime = '';
      if (json.containsKey('vod_remarks') && json['vod_remarks'] != null) {
        updateTime = json['vod_remarks'].toString().trim();
      } else if (json.containsKey('vod_time') && json['vod_time'] != null) {
        updateTime = json['vod_time'].toString().trim();
      } else if (json.containsKey('update_time') && json['update_time'] != null) {
        updateTime = json['update_time'].toString().trim();
      }
      
      // 获取详细信息
      String director = json['vod_director']?.toString() ?? json['director']?.toString() ?? '';
      String actor = json['vod_actor']?.toString() ?? json['actor']?.toString() ?? '';
      String description = json['vod_content']?.toString() ?? json['vod_blurb']?.toString() ?? json['content']?.toString() ?? '';
      String year = json['vod_year']?.toString() ?? json['year']?.toString() ?? '';
      String area = json['vod_area']?.toString() ?? json['area']?.toString() ?? '';
      String language = json['vod_lang']?.toString() ?? json['lang']?.toString() ?? '';
      String playUrl = json['vod_play_url']?.toString() ?? json['url']?.toString() ?? '';
      
      // 获取播放源
      List<String> playSources = [];
      if (json.containsKey('vod_play_from') && json['vod_play_from'] != null) {
        final String playFromStr = json['vod_play_from'].toString();
        if (playFromStr.isNotEmpty) {
          // 播放源通常以三个$符号分隔
          playSources = playFromStr.split(r'$$$')
              .where((source) => source.trim().isNotEmpty)
              .toList();
        }
      }
      
      // 解析播放URL列表
      List<String> playUrlList = [];
      if (json.containsKey('vod_play_url') && json['vod_play_url'] != null) {
        final String playUrlStr = json['vod_play_url'].toString();
        if (playUrlStr.isNotEmpty) {
          // 通常整个vod_play_url以$$$分隔多个播放源
          final List<String> sourceUrlGroups = playUrlStr.split(r'$$$');
          
          // 如果有至少一个播放源，使用第一个播放源的地址
          if (sourceUrlGroups.isNotEmpty) {
            // 单个播放源的多个集数以#号分隔
            final String firstSource = sourceUrlGroups.first;
            playUrlList = firstSource.split('#')
                .where((url) => url.trim().isNotEmpty)
                .map((url) {
                  // 有些格式可能是"第1集$http://example.com/1.html"
                  final parts = url.split(r'$');
                  return parts.length > 1 ? parts.last : url;
                })
                .toList();
          }
        }
      }

      // 解析选集名称（vod_play_note）
      List<String> playNotes = [];
      
      if (json.containsKey('vod_play_note') && json['vod_play_note'] != null) {
        final String playNoteStr = json['vod_play_note'].toString();
        if (playNoteStr.isNotEmpty) {
          // 通常vod_play_note以$$$分隔多个播放源的选集信息
          final List<String> noteGroups = playNoteStr.split(r'$$$');
          
          // 如果有至少一个播放源的选集信息，使用第一个
          if (noteGroups.isNotEmpty) {
            // 单个播放源的多个选集名称通常以#号分隔
            final String firstNoteGroup = noteGroups.first;
            playNotes = firstNoteGroup.split('#')
                .where((note) => note.trim().isNotEmpty)
                .toList();
            
            // 打印日志
            if (playNotes.isNotEmpty) {
              print('解析到选集名称: ${playNotes.length}个，第一个: ${playNotes.first}');
            }
          }
        }
      }
      
      // 如果没有解析出播放URL列表但有播放URL，则将其添加为唯一的列表项
      if (playUrlList.isEmpty && playUrl.isNotEmpty) {
        playUrlList = [playUrl];
      }
      
      // 如果选集名称数量与播放URL不匹配，则清空选集名称（避免错位）
      if (playNotes.isNotEmpty && playNotes.length != playUrlList.length) {
        print('警告: 选集名称数量(${playNotes.length})与播放地址数量(${playUrlList.length})不匹配，将不使用选集名称');
        playNotes = [];
      }
      
      // 获取封面图
      String coverUrl = '';
      List<String> possibleCoverFields = ['vod_pic', 'pic', 'cover', 'image', 'img', 'thumb'];
      for (var field in possibleCoverFields) {
        if (json.containsKey(field) && json[field] != null && json[field].toString().isNotEmpty) {
          coverUrl = json[field].toString().trim();
          break;
        }
      }
      
      if (coverUrl.isEmpty) {
        print('警告: 视频 $title (ID: $id) 没有封面图');
      }
      
      // 修复相对URL
      if (coverUrl.isNotEmpty && !coverUrl.startsWith('http')) {
        coverUrl = coverUrl.startsWith('/')
            ? '${ApiConstants.baseUrl}$coverUrl'
            : '${ApiConstants.baseUrl}/$coverUrl';
      }
      
      // 创建并返回视频对象
      return Video(
        id: id,
        title: title,
        cover: coverUrl,
        category: category,
        updateTime: updateTime,
        director: director,
        actor: actor,
        description: description,
        year: year,
        area: area,
        language: language,
        playUrl: playUrl,
        playSources: playSources,
        playUrlList: playUrlList,
        playNotes: playNotes,
        fileSize: json['file_size']?.toString(),
        downloadTime: json['download_time']?.toString(),
        watchPosition: json['watch_position']?.toString(),
        watchEpisode: json['watch_episode']?.toString(),
        watchTime: json['watch_time']?.toString(),
      );
    } catch (e) {
      print('视频解析失败: $e, 原始数据: $json');
      // 返回一个默认视频，避免在UI中出错
      return Video(
        id: 'error',
        title: '数据解析错误',
        cover: '',
        category: '未知',
      );
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'vod_id': id,
      'vod_name': title,
      'vod_pic': cover,
      'type_name': category,
      'vod_remarks': updateTime,
      'vod_director': director,
      'vod_actor': actor,
      'vod_content': description,
      'vod_year': year,
      'vod_area': area,
      'vod_lang': language,
      'vod_play_url': playUrl,
      'vod_play_from': playSources.isEmpty ? '' : playSources.join(r'$$$'),
      'watch_position': watchPosition,
      'watch_episode': watchEpisode,
      'watch_time': watchTime,
      'file_size': fileSize,
      'download_time': downloadTime,
    };
  }
  
  // 创建带有观看进度和时间的新实例
  Video copyWithWatchInfo({
    String? watchPosition,
    String? watchEpisode,
    String? watchTime,
  }) {
    return Video(
      id: this.id,
      title: this.title,
      cover: this.cover,
      category: this.category,
      updateTime: this.updateTime,
      director: this.director,
      actor: this.actor,
      description: this.description,
      year: this.year,
      area: this.area,
      language: this.language,
      playUrl: this.playUrl,
      playSources: this.playSources,
      playUrlList: this.playUrlList,
      playNotes: this.playNotes,
      fileSize: this.fileSize,
      downloadTime: this.downloadTime,
      watchPosition: watchPosition ?? this.watchPosition,
      watchEpisode: watchEpisode ?? this.watchEpisode,
      watchTime: watchTime ?? this.watchTime,
    );
  }
} 