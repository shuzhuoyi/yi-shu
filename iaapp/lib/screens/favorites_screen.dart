import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_model.dart';
import '../services/storage_service.dart';
import 'video_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final StorageService _storageService = StorageService();
  List<Video> _favoriteVideos = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadFavoriteVideos();
  }
  
  Future<void> _loadFavoriteVideos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final videos = await _storageService.getFavoriteVideos();
      setState(() {
        _favoriteVideos = videos;
        _isLoading = false;
      });
    } catch (e) {
      print('加载收藏视频失败: $e');
      setState(() {
        _favoriteVideos = [];
        _isLoading = false;
      });
    }
    
    _refreshController.refreshCompleted();
  }
  
  Future<void> _removeFromFavorites(Video video) async {
    final result = await _storageService.removeFromFavorites(video.id);
    if (result) {
      setState(() {
        _favoriteVideos.removeWhere((v) => v.id == video.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已从收藏中移除《${video.title}》'),
          duration: const Duration(seconds: 1),
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
        title: const Text('我的收藏'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _favoriteVideos.isEmpty 
              ? _buildEmptyView()
              : SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _loadFavoriteVideos,
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
                    itemCount: _favoriteVideos.length,
                    itemBuilder: (context, index) {
                      final video = _favoriteVideos[index];
                      return _buildVideoItem(video);
                    },
                  ),
                ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/xxmin/收藏_file-collection.png',
            width: 50,
            height: 50,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          const Text(
            '暂无收藏内容',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '您可以在视频详情页点击收藏按钮添加喜欢的视频',
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _navigateToVideoDetail(video),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 视频封面
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 100,
                  height: 130,
                  child: CachedNetworkImage(
                    imageUrl: video.cover,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 视频信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${video.category} · ${video.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.updateTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      video.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 删除按钮
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: () => _removeFromFavorites(video),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _navigateToVideoDetail(Video video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoDetailScreen(video: video),
      ),
    ).then((_) {
      // 从详情页返回后刷新列表，因为可能已经取消收藏
      _loadFavoriteVideos();
    });
  }
} 