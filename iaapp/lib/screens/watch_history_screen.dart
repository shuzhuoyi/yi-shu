import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'video_detail_screen.dart';

class WatchHistoryScreen extends StatefulWidget {
  const WatchHistoryScreen({super.key});

  @override
  State<WatchHistoryScreen> createState() => _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends State<WatchHistoryScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  List<Video> _historyVideos = [];
  bool _isLoading = true;
  bool _isEditing = false;
  Set<String> _selectedVideoIds = {};
  
  @override
  void initState() {
    super.initState();
    _loadHistoryVideos();
  }
  
  Future<void> _loadHistoryVideos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 从StorageService获取观看历史
      final videos = await _storageService.getWatchHistory();
      
      if (mounted) {
        setState(() {
          _historyVideos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('加载历史视频失败: $e');
      if (mounted) {
        setState(() {
          _historyVideos = [];
          _isLoading = false;
        });
      }
    }
    
    _refreshController.refreshCompleted();
  }
  
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _selectedVideoIds.clear();
      }
    });
  }
  
  void _toggleVideoSelection(String videoId) {
    setState(() {
      if (_selectedVideoIds.contains(videoId)) {
        _selectedVideoIds.remove(videoId);
      } else {
        _selectedVideoIds.add(videoId);
      }
    });
  }
  
  void _clearSelectedHistory() {
    if (_selectedVideoIds.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除观看记录'),
        content: Text('确定要清除已选择的${_selectedVideoIds.length}条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeSelectedVideos();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _clearAllHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除全部记录'),
        content: const Text('确定要清除全部观看记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeAllVideos();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _removeSelectedVideos() async {
    // 调用StorageService移除选定的历史记录
    final result = await _storageService.removeMultipleFromWatchHistory(_selectedVideoIds.toList());
    
    if (result) {
      setState(() {
        _historyVideos.removeWhere((video) => _selectedVideoIds.contains(video.id));
        _selectedVideoIds.clear();
        _isEditing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已清除选中的观看记录'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('清除记录失败'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
  
  void _removeAllVideos() async {
    // 调用StorageService清空所有历史记录
    final result = await _storageService.clearWatchHistory();
    
    if (result) {
      setState(() {
        _historyVideos.clear();
        _selectedVideoIds.clear();
        _isEditing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已清除全部观看记录'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('清除记录失败'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('观看历史'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _toggleEditMode,
            child: Text(_isEditing ? '完成' : '编辑'),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _historyVideos.isEmpty 
              ? _buildEmptyView()
              : Column(
                  children: [
                    Expanded(
                      child: SmartRefresher(
                        controller: _refreshController,
                        onRefresh: _loadHistoryVideos,
                        header: const ClassicHeader(
                          refreshStyle: RefreshStyle.UnFollow,
                          idleText: '下拉刷新',
                          refreshingText: '刷新中',
                          completeText: '刷新完成',
                          failedText: '刷新失败',
                          releaseText: '释放刷新',
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: _historyVideos.length,
                          itemBuilder: (context, index) {
                            final video = _historyVideos[index];
                            return _buildVideoItem(video);
                          },
                        ),
                      ),
                    ),
                    if (_isEditing) _buildBottomActionBar(),
                  ],
                ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/tbmin/我的下载_download.png',
            width: 50,
            height: 50,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          const Text(
            '暂无观看记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '您观看过的视频将会显示在这里',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVideoItem(Video video) {
    final bool isSelected = _isEditing && _selectedVideoIds.contains(video.id);
    
    // 格式化观看时间
    String formattedWatchTime = '未知时间';
    if (video.watchTime != null && video.watchTime!.isNotEmpty) {
      try {
        final DateTime watchTime = DateTime.parse(video.watchTime!);
        final DateTime now = DateTime.now();
        final Duration difference = now.difference(watchTime);
        
        if (difference.inMinutes < 60) {
          formattedWatchTime = '${difference.inMinutes}分钟前';
        } else if (difference.inHours < 24) {
          formattedWatchTime = '${difference.inHours}小时前';
        } else if (difference.inDays < 30) {
          formattedWatchTime = '${difference.inDays}天前';
        } else {
          formattedWatchTime = '${watchTime.year}-${watchTime.month.toString().padLeft(2, '0')}-${watchTime.day.toString().padLeft(2, '0')}';
        }
      } catch (e) {
        print('解析观看时间失败: $e');
      }
    }
    
    // 格式化观看进度
    String progressText = '';
    if (video.watchPosition != null && video.watchPosition!.isNotEmpty) {
      try {
        int seconds = int.parse(video.watchPosition!);
        int minutes = seconds ~/ 60;
        int remainingSeconds = seconds % 60;
        
        if (video.watchEpisode != null && video.watchEpisode!.isNotEmpty && video.watchEpisode != '1') {
          progressText = '已看至第${video.watchEpisode}集 ${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
        } else {
          progressText = '已看至 ${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
        }
      } catch (e) {
        print('解析观看进度失败: $e');
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: _isEditing 
            ? () => _toggleVideoSelection(video.id)
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoDetailScreen(video: video),
                ),
              ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 勾选框（仅在编辑模式下显示）
              if (_isEditing)
                Padding(
                padding: const EdgeInsets.all(12),
                  child: Container(
                  width: 24,
                  height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: 2,
                      ),
                    color: isSelected ? Colors.blue : Colors.transparent,
                    ),
                  child: isSelected
                        ? const Icon(
                            Icons.check,
                          size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              
              // 视频封面
              ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                  width: 100,
                height: 140,
                child: Stack(
                  children: [
                    // 封面图
                    CachedNetworkImage(
                    imageUrl: video.cover,
                      width: 100,
                      height: 140,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                    
                    // 播放进度指示
                    if (video.watchPosition != null && video.watchPosition!.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          color: Colors.blue.withOpacity(0.7),
                          width: double.infinity,
                        ),
                      ),
                    
                    // 继续播放按钮
                    if (!_isEditing)
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
              
              // 视频信息
              Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // 分类和年份
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (video.year.isNotEmpty)
                    Text(
                            video.year,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // 观看进度
                    if (progressText.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 14,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            progressText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    
                    // 最后观看时间
                    Text(
                      '上次观看: $formattedWatchTime',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    // 演员（如果有）
                    if (video.actor.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '主演: ${video.actor}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                      ),
                    ),
                  ],
                ),
              ),
                ),
            ],
        ),
      ),
    );
  }
  
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (_selectedVideoIds.length == _historyVideos.length) {
                  _selectedVideoIds.clear();
                } else {
                  _selectedVideoIds = _historyVideos.map((v) => v.id).toSet();
                }
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedVideoIds.length == _historyVideos.length 
                            ? Colors.blue 
                            : Colors.grey,
                        width: 1.5,
                      ),
                      color: _selectedVideoIds.length == _historyVideos.length 
                          ? Colors.blue 
                          : Colors.transparent,
                    ),
                    child: _selectedVideoIds.length == _historyVideos.length
                        ? const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 4),
                  const Text('全选'),
                ],
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _selectedVideoIds.isNotEmpty 
                ? _clearSelectedHistory 
                : null,
            child: const Text('删除选中'),
          ),
          TextButton(
            onPressed: _historyVideos.isNotEmpty 
                ? _clearAllHistory 
                : null,
            child: const Text('清空全部'),
          ),
        ],
      ),
    );
  }
} 