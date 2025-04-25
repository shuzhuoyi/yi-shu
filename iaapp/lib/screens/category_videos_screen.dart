import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../providers/video_provider.dart';
import '../models/video_model.dart';
import '../services/api_service.dart';
import 'video_detail_screen.dart';

class CategoryVideosScreen extends StatefulWidget {
  final String category;
  final String categoryId;
  
  const CategoryVideosScreen({
    super.key,
    required this.category,
    required this.categoryId,
  });

  @override
  State<CategoryVideosScreen> createState() => _CategoryVideosScreenState();
}

class _CategoryVideosScreenState extends State<CategoryVideosScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  List<Video> _videos = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  
  @override
  void initState() {
    super.initState();
    _loadVideos();
  }
  
  Future<void> _loadVideos({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
      });
    }
    
    if (!_hasMore) {
      _refreshController.loadComplete();
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final videoProvider = Provider.of<VideoProvider>(context, listen: false);
      print('正在加载分类视频: ${widget.category}, ID=${widget.categoryId}, 页码=$_currentPage');
      
      // 使用分类ID加载视频
      final videos = await videoProvider.loadVideosByCategoryId(
        widget.categoryId,
        page: _currentPage,
      );
      
      print('成功加载${videos.length}个"${widget.category}"分类的视频');
      
      setState(() {
        if (refresh || _currentPage == 1) {
          _videos = videos;
        } else {
          _videos.addAll(videos);
        }
        
        if (videos.length < 20) {
          _hasMore = false;
          print('已加载所有"${widget.category}"分类的视频，总共: ${_videos.length}个');
        } else {
          _currentPage++;
          print('"${widget.category}"分类还有更多视频，增加页码到: $_currentPage');
        }
        
        _isLoading = false;
      });
      
      if (refresh) {
        _refreshController.refreshCompleted();
      } else {
        _refreshController.loadComplete();
      }
    } catch (e) {
      print('加载分类视频失败: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (refresh) {
        _refreshController.refreshFailed();
      } else {
        _refreshController.loadFailed();
      }
      
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载视频失败: ${e.toString().substring(0, e.toString().length > 50 ? 50 : e.toString().length)}...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
        title: Text(widget.category),
        elevation: 0,
      ),
      body: _isLoading && _videos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.movie_filter,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无影片',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : SmartRefresher(
                  controller: _refreshController,
                  onRefresh: () => _loadVideos(refresh: true),
                  onLoading: _loadVideos,
                  enablePullUp: _hasMore,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.55,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 0.5,
                    ),
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      return _buildVideoCard(video);
                    },
                  ),
                ),
    );
  }
  
  Widget _buildVideoCard(Video video) {
    return GestureDetector(
      onTap: () => _onVideoTap(context, video),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面图
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 封面图片，处理错误情况
                  video.cover.isNotEmpty
                    ? Image.network(
                        video.cover,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // 图片加载错误时显示默认图片
                          print('视频封面加载失败: ${video.title} - ${error.toString().substring(0, error.toString().length > 30 ? 30 : error.toString().length)}');
                          return Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.movie_outlined, color: Colors.grey[600]),
                                  const SizedBox(height: 4),
                                  Text(
                                    '无图片',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.movie_outlined, color: Colors.grey[600]),
                              const SizedBox(height: 4),
                              Text(
                                '无图片',
                                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                  // 分类标签
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        video.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 标题
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              video.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
          // 更新信息
          Text(
            video.updateTime,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  void _onVideoTap(BuildContext context, Video video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoDetailScreen(video: video),
      ),
    );
  }
} 