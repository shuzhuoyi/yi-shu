import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_model.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/video_info_widget.dart';
import '../widgets/video_sources_widget.dart';
import '../widgets/video_episodes_widget.dart';
import '../widgets/recommended_videos_widget.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import 'dart:async';
import 'package:flutter/rendering.dart';

class VideoDetailScreen extends StatefulWidget {
  final Video video;
  
  const VideoDetailScreen({
    super.key,
    required this.video,
  });

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> with WidgetsBindingObserver {
  bool _isPlaying = true;
  int _selectedSourceIndex = 0;
  int _selectedEpisodeIndex = 0;
  bool _isFavorited = false;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  final StorageService _storageService = StorageService();
  late Video _currentVideo;
  List<String> _currentEpisodes = [];
  List<String> _currentEpisodeNames = [];
  // 添加定时更新观看进度的定时器
  Timer? _watchProgressTimer;
  
  // 添加视频控制器引用
  final GlobalKey<VideoPlayerWidgetState> _videoPlayerKey = GlobalKey<VideoPlayerWidgetState>();
  
  @override
  void initState() {
    super.initState();
    // 注册生命周期观察者
    WidgetsBinding.instance.addObserver(this);
    
    // 设置透明状态栏
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    // 初始化当前视频
    _currentVideo = widget.video;
    
    // 如果有播放地址，使用第一个播放源的地址
    if (widget.video.playUrl.isNotEmpty) {
      // 解析播放源
      final sourceGroups = widget.video.playUrl.split(r'$$$');
      if (sourceGroups.isNotEmpty) {
        // 获取第一个播放源的所有地址
        final episodeUrls = sourceGroups[0].split('#')
            .where((url) => url.trim().isNotEmpty)
            .map((url) {
              final parts = url.split(r'$');
              return parts.length > 1 ? parts.last.trim() : url.trim();
            }).toList();
        if (episodeUrls.isNotEmpty) {
          _currentEpisodes = episodeUrls;
          print('初始化时找到${episodeUrls.length}个播放地址');
        }
      }
    }
    
    // 如果没有解析到地址，使用默认的playUrlList
    if (_currentEpisodes.isEmpty) {
      _currentEpisodes = widget.video.playUrlList.isNotEmpty ? 
          widget.video.playUrlList : [];
    }
    
    // 尝试解析选集名称
    if (widget.video.playNotes.isNotEmpty) {
      _currentEpisodeNames = widget.video.playNotes;
    } else {
      // 根据播放地址生成选集名称
      _generateEpisodeNames();
    }
    
    _checkFavoriteStatus();
    _checkDownloadStatus();
    _loadWatchProgress();
    
    // 启动定时保存观看进度的任务
    _startWatchProgressTimer();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 当应用进入后台时暂停视频
    if (state == AppLifecycleState.paused) {
      // 在进入后台前保存当前观看进度
      _saveCurrentWatchProgress();
      
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  void dispose() {
    // 保存最终的观看进度
    _saveCurrentWatchProgress();
    
    // 取消定时器
    _watchProgressTimer?.cancel();
    
    // 移除生命周期观察者
    WidgetsBinding.instance.removeObserver(this);
    
    // 在离开页面时停止播放
    if (_videoPlayerKey.currentState != null) {
      _videoPlayerKey.currentState!.disposeVideoPlayer();
    }
    
    super.dispose();
  }

  // 加载保存的观看进度
  Future<void> _loadWatchProgress() async {
    try {
      final progress = await _storageService.getWatchProgress(widget.video.id);
      
      if (mounted) {
        setState(() {
          // 如果有保存的集数，选择对应的集数
          if (progress['episode'] != null && progress['episode'] != '0' && progress['episode'] != '1') {
            final episodeIndex = int.tryParse(progress['episode']!) ?? 0;
            if (episodeIndex > 0 && episodeIndex <= _currentEpisodes.length) {
              _selectedEpisodeIndex = episodeIndex - 1;
              
              // 更新当前视频对象，包含播放URL
              if (_currentEpisodes.isNotEmpty && _selectedEpisodeIndex < _currentEpisodes.length) {
                final selectedUrl = _currentEpisodes[_selectedEpisodeIndex];
                _currentVideo = Video(
                  id: widget.video.id,
                  title: widget.video.title,
                  cover: widget.video.cover,
                  category: widget.video.category,
                  director: widget.video.director,
                  actor: widget.video.actor,
                  description: widget.video.description,
                  playUrl: widget.video.playUrl,
                  playSources: widget.video.playSources,
                  playUrlList: [selectedUrl],
                  playNotes: widget.video.playNotes,
                  watchPosition: progress['position'],
                  watchEpisode: progress['episode'],
                  watchTime: progress['time'],
                );
              }
            }
          } else {
            // 更新观看进度信息
            _currentVideo = _currentVideo.copyWithWatchInfo(
              watchPosition: progress['position'],
              watchEpisode: progress['episode'],
              watchTime: progress['time'],
            );
          }
        });
        
        print('加载观看进度: 位置=${progress['position']}秒, 集数=${progress['episode']}, 时间=${progress['time']}');
      }
      
      // 记录本次观看历史
      await _recordWatchHistory();
    } catch (e) {
      print('加载观看进度失败: $e');
      // 记录本次观看历史
      await _recordWatchHistory();
    }
  }
  
  // 启动定时保存观看进度的定时器
  void _startWatchProgressTimer() {
    // 每30秒保存一次观看进度
    _watchProgressTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _saveCurrentWatchProgress();
    });
  }
  
  // 保存当前观看进度
  Future<void> _saveCurrentWatchProgress() async {
    if (_videoPlayerKey.currentState == null || 
        _videoPlayerKey.currentState!.videoController == null ||
        !_videoPlayerKey.currentState!.videoController!.value.isInitialized) {
      return;
    }
    
    try {
      // 获取当前播放位置（秒）
      final position = _videoPlayerKey.currentState!.videoController!.value.position;
      final positionInSeconds = position.inSeconds.toString();
      
      // 当前集数索引加1（因为集数从1开始计数）
      final episode = (_selectedEpisodeIndex + 1).toString();
      
      // 更新观看进度
      await _storageService.updateWatchProgress(
        widget.video.id,
        position: positionInSeconds,
        episode: episode,
      );
      
      print('保存观看进度: 位置=$positionInSeconds秒, 集数=$episode');
    } catch (e) {
      print('保存观看进度失败: $e');
    }
  }
  
  // 生成默认选集名称
  void _generateEpisodeNames() {
    if (_currentEpisodes.isEmpty) {
      _currentEpisodeNames = [];
      return;
    }
    
    // 使用简单的数字编号
    _currentEpisodeNames = List.generate(_currentEpisodes.length, (index) => '${index + 1}');
  }
  
  // 记录观看历史
  Future<void> _recordWatchHistory() async {
    await _storageService.addToWatchHistory(widget.video);
  }
  
  // 检查视频是否已收藏
  Future<void> _checkFavoriteStatus() async {
    final isFavorited = await _storageService.isVideoFavorited(widget.video.id);
    if (mounted) {
      setState(() {
        _isFavorited = isFavorited;
      });
    }
  }
  
  // 检查视频是否已下载
  Future<void> _checkDownloadStatus() async {
    final isDownloaded = await _storageService.isVideoDownloaded(widget.video.id);
    if (mounted) {
      setState(() {
        _isDownloaded = isDownloaded;
      });
    }
  }
  
  // 切换收藏状态
  Future<void> _toggleFavorite() async {
    final result = await _storageService.toggleFavorite(widget.video);
    if (result && mounted) {
      setState(() {
        _isFavorited = !_isFavorited;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorited ? '已添加到收藏' : '已从收藏中移除'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  // 处理下载操作
  Future<void> _handleDownload() async {
    if (_isDownloaded) {
      _showDeleteDownloadDialog();
      return;
    }
    
    if (_isDownloading) {
      _cancelDownload();
      return;
    }
    
    // 开始下载
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });
    
    // 模拟下载进度
    for (var i = 0; i <= 100; i += 5) {
      if (!_isDownloading) break; // 检查是否取消下载
      
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _downloadProgress = i / 100;
        });
      }
    }
    
    // 下载完成
    if (_isDownloading && mounted) {
      // 计算随机文件大小（实际应用中应该根据真实文件大小计算）
      final fileSize = (20 + (widget.video.id.hashCode % 100)).toString();
      
      // 将视频添加到下载列表
      final result = await _storageService.addToDownloads(
        widget.video,
        fileSize: fileSize,
        downloadTime: DateTime.now().toIso8601String(),
      );
      
      setState(() {
        _isDownloading = false;
        _isDownloaded = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? '《${widget.video.title}》下载完成' : '《${widget.video.title}》已经下载过了'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  // 取消下载
  void _cancelDownload() {
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已取消下载《${widget.video.title}》'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  // 显示删除下载对话框
  void _showDeleteDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除下载'),
        content: Text('确定要删除《${widget.video.title}》的缓存吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 从下载列表中移除视频
              final result = await _storageService.removeFromDownloads(widget.video.id);
              if (mounted) {
                setState(() {
                  _isDownloaded = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result ? '已删除《${widget.video.title}》的缓存' : '删除失败'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  // 修改播放源选择项的方法
  void _selectSource(int index) {
    if (index == _selectedSourceIndex) {
      // 如果点击的是当前已选中的播放源，则不执行切换
      return;
    }
    
    // 更新当前播放列表 - 从vod_play_url获取对应播放源的播放地址
    if (widget.video.playSources.length > index) {
      // 如果有多播放源数据
      final videoProvider = Provider.of<VideoProvider>(context, listen: false);
      final result = videoProvider.updateCurrentPlaylist(widget.video, index);
      
      // 获取新的播放地址列表
      List<String> newEpisodes = result['urls'] ?? [];
      List<String> newEpisodeNames = result['notes'] ?? [];
      
      setState(() {
        _selectedSourceIndex = index;
        _selectedEpisodeIndex = 0; // 重置选集索引
        
        // 更新选集列表
        _currentEpisodes = newEpisodes;
        _currentEpisodeNames = newEpisodeNames;
        
        // 同时更新当前视频对象的播放地址列表，选择第一个集数播放
        if (_currentEpisodes.isNotEmpty) {
          // 创建新的播放地址列表，只包含第一个地址
          List<String> firstEpisodeUrl = [_currentEpisodes.first];
          
          // 创建一个新的视频对象，使用新的播放源
          _currentVideo = Video(
            id: widget.video.id,
            title: widget.video.title,
            cover: widget.video.cover,
            category: widget.video.category,
            director: widget.video.director,
            actor: widget.video.actor,
            description: widget.video.description,
            playUrl: widget.video.playUrl,
            playSources: widget.video.playSources,
            playUrlList: firstEpisodeUrl, // 使用新播放源的第一个URL
            playNotes: widget.video.playNotes,
            watchPosition: "0", // 切换播放源时重置观看进度
            watchEpisode: "1",
          );
          
          // 更新播放状态
          _isPlaying = true; // 切换源后自动开始播放
          
          print('切换到播放源: ${widget.video.playSources[index]}，共${_currentEpisodes.length}个集数，默认播放第1集');
        }
      });
      
      // 切换播放源时保存观看进度
      _saveCurrentWatchProgress();
    }
  }
  
  // 修改选集选择项的方法
  void _selectEpisode(int index) {
    if (index == _selectedEpisodeIndex) {
      // 如果点击的是当前已选中的选集，则不执行切换
      return;
    }
    
    print('正在切换选集: 从${_selectedEpisodeIndex + 1}集到${index + 1}集');
    
    // 保存当前URL用于比较
    final String oldUrl = _currentEpisodes.isNotEmpty && _selectedEpisodeIndex < _currentEpisodes.length 
        ? _currentEpisodes[_selectedEpisodeIndex] : '';
    
    // 获取新URL
    final String newUrl = _currentEpisodes.isNotEmpty && index < _currentEpisodes.length 
        ? _currentEpisodes[index] : '';
    
    print('URL变化: 从[$oldUrl]到[$newUrl]');
    
    // 切换前保存当前观看进度
    _saveCurrentWatchProgress();
    
    // 先完全释放当前视频播放器
    if (_videoPlayerKey.currentState != null) {
      print('先停止并释放当前播放器');
      _videoPlayerKey.currentState!.disposeVideoPlayer();
    }
    
    // 必须先停止当前视频播放
    setState(() {
      _isPlaying = false;
    });
    
    // 确保释放完成后再进行下一步
    Future.delayed(const Duration(milliseconds: 100), () {
      // 在延迟后更新状态变量
      _selectedEpisodeIndex = index;
      
      // 更新播放状态
      setState(() {
      _isPlaying = true; // 切换选集后自动开始播放
      
      // 创建一个新的视频对象，包含更新后的播放URL
      if (_currentEpisodes.isNotEmpty && index < _currentEpisodes.length) {
        // 获取选中的URL
        final selectedUrl = _currentEpisodes[index];
        
        // 创建一个新的视频对象，使用选中的集数URL作为播放地址
        _currentVideo = Video(
          id: widget.video.id,
          title: widget.video.title,
          cover: widget.video.cover,
          category: widget.video.category,
          director: widget.video.director,
          actor: widget.video.actor,
          description: widget.video.description,
          playUrl: widget.video.playUrl,
          playSources: widget.video.playSources,
          playUrlList: [selectedUrl], // 只包含选中的地址
          playNotes: widget.video.playNotes,
            watchPosition: "0", // 切换选集时重置观看位置
            watchEpisode: (index + 1).toString(), // 更新观看的集数
        );
        
        print('已选择集数: ${index + 1}，播放地址: $selectedUrl');
      }
    });
    
      // 等待状态更新后再刷新播放器
      Future.delayed(const Duration(milliseconds: 50), () {
    if (_videoPlayerKey.currentState != null) {
          print('完全重新初始化播放器');
      _videoPlayerKey.currentState!.refreshPlayer();
        } else {
          print('错误: 播放器引用为空，无法刷新');
    }
      });
    });
  }
  
  // 处理播放/暂停逻辑
  void _togglePlaying() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    
    // 当暂停时保存观看进度
    if (!_isPlaying) {
      _saveCurrentWatchProgress();
    }
  }
  
  // 显示视频详细信息底部弹窗
  void _showVideoDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.95, // 稍微减小宽度，增加边距
      ),
      clipBehavior: Clip.hardEdge, // 确保内容不超出圆角
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Stack(
              children: [
                // 关闭按钮
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 24, color: Colors.black),
                  ),
                ),
                
                // 详细内容
                SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题
                        Padding(
                          padding: const EdgeInsets.only(right: 40, bottom: 16),
                          child: Text(
                            widget.video.title,
                            style: const TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        // 导演
                        if (widget.video.director.isNotEmpty)
                          _buildDetailItem('导演：', widget.video.director),
                        
                        // 主演
                        if (widget.video.actor.isNotEmpty)
                          _buildDetailItem('主演：', widget.video.actor),
                        
                        // 类型
                        if (widget.video.category.isNotEmpty)
                          _buildDetailItem('类型：', widget.video.category),
                        
                        // 地区
                        if (widget.video.area.isNotEmpty)
                          _buildDetailItem('地区：', widget.video.area),
                        
                        // 年代
                        if (widget.video.year.isNotEmpty)
                          _buildDetailItem('年代：', widget.video.year),
                        
                        const SizedBox(height: 24),
                        
                        // 简介标题
                        const Text(
                          '简介',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // 简介内容
                        Text(
                          widget.video.description.isNotEmpty ? 
                            widget.video.description : 
                            '暂无影片简介信息',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                        
                        // 底部小间距，避免内容太紧贴底部
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // 构建详情项目
  Widget _buildDetailItem(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // 设置状态栏为透明
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    return Scaffold(
      backgroundColor: Colors.white,
      // 确保内容扩展到状态栏区域
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // 播放器区域 - 不设置顶部边距让播放器占据整个顶部区域
          VideoPlayerWidget(
              key: _videoPlayerKey,
              video: _currentVideo,
              isPlaying: _isPlaying,
              onTogglePlaying: _togglePlaying,
              onBack: () {
              // 返回前先停止播放并保存进度
              _saveCurrentWatchProgress();
              
                setState(() {
                  _isPlaying = false;
                });
                // 延迟一下确保视频停止播放
                Future.delayed(const Duration(milliseconds: 50), () {
                  Navigator.pop(context);
                });
              },
          ),
          
          // 底部内容区域
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标签页头部 - 简化为单一标签
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                '视频',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: const Text(
                              '讨论',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 包含三角形按钮的影片信息部分
                    Stack(
                      children: [
                    VideoInfoWidget(
                      video: widget.video,
                      isFavorited: _isFavorited,
                      isDownloaded: _isDownloaded,
                      isDownloading: _isDownloading,
                      downloadProgress: _downloadProgress,
                      onToggleFavorite: _toggleFavorite,
                      onHandleDownload: _handleDownload,
                        ),
                        // 向右的三角形按钮 - 与标题平行，点击显示详情
                        Positioned(
                          top: 32, // 精确定位到与影片标题同高度
                          right: 16.0,
                          child: GestureDetector(
                            onTap: () {
                              _showVideoDetailsBottomSheet(context);
                            },
                            child: Row(
                              children: const [
                                Text(
                                  '简介',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // 播放源
                    VideoSourcesWidget(
                      selectedIndex: _selectedSourceIndex,
                      onSelect: _selectSource,
                      playSources: widget.video.playSources,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 选集 - 只有在有选集时才显示
                    _currentEpisodes.isNotEmpty ?
                    VideoEpisodesWidget(
                      selectedIndex: _selectedEpisodeIndex,
                      onSelect: _selectEpisode,
                      episodes: _currentEpisodes,
                      episodeNames: _currentEpisodeNames,
                    ) : const SizedBox.shrink(),
                    
                    const SizedBox(height: 20),
                    
                    // 猜你喜欢
                    const RecommendedVideosWidget(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 