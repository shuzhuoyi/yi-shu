import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_model.dart';
import '../services/storage_service.dart';
import 'video_detail_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final StorageService _storageService = StorageService();
  List<Video> _downloadedVideos = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadDownloadedVideos();
  }
  
  Future<void> _loadDownloadedVideos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 从本地存储加载已下载的视频
      final videos = await _storageService.getDownloadedVideos();
      
      if (mounted) {
        setState(() {
          _downloadedVideos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('加载下载视频失败: $e');
      if (mounted) {
        setState(() {
          _downloadedVideos = [];
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的下载'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _downloadedVideos.isEmpty 
              ? _buildEmptyView()
              : _buildDownloadList(),
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
            '暂无下载内容',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '您可以在视频详情页点击下载按钮缓存视频',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDownloadList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _downloadedVideos.length,
      itemBuilder: (context, index) {
        final video = _downloadedVideos[index];
        return _buildDownloadItem(video);
      },
    );
  }
  
  Widget _buildDownloadItem(Video video) {
    // 使用Video模型中的下载信息
    final String downloadSize = video.fileSize ?? '20';
    final String downloadTime = video.downloadTime ?? DateTime.now().toIso8601String();
    final DateTime downloadDate = DateTime.tryParse(downloadTime) ?? DateTime.now();
    final String formattedDate = '${downloadDate.year}-${downloadDate.month.toString().padLeft(2, '0')}-${downloadDate.day.toString().padLeft(2, '0')}';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: video.cover,
                      width: 100,
                      height: 130,
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
                    // 添加已下载标记
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.sd_storage, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$downloadSize MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                        const SizedBox(width: 4),
                        Text(
                          '下载完成',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 操作按钮
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(video);
                  } else if (value == 'play') {
                    _navigateToVideoDetail(video);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'play',
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_outline, size: 16),
                        SizedBox(width: 8),
                        Text('播放'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16),
                        SizedBox(width: 8),
                        Text('删除'),
                      ],
                    ),
                  ),
                ],
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
    );
  }
  
  void _showDeleteDialog(Video video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除下载'),
        content: Text('确定要删除《${video.title}》的缓存吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 从StorageService删除下载记录
              final result = await _storageService.removeFromDownloads(video.id);
              
              if (result) {
                setState(() {
                  _downloadedVideos.removeWhere((v) => v.id == video.id);
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已删除《${video.title}》的缓存'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('删除失败，请重试'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
} 