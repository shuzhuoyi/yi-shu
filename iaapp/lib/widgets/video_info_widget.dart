import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_model.dart';

class VideoInfoWidget extends StatelessWidget {
  final Video video;
  final bool isFavorited;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onToggleFavorite;
  final VoidCallback onHandleDownload;

  const VideoInfoWidget({
    super.key,
    required this.video,
    required this.isFavorited,
    required this.isDownloaded,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onToggleFavorite,
    required this.onHandleDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面图
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 80,
              height: 110,
              color: Colors.grey[200],
              child: CachedNetworkImage(
                imageUrl: video.cover,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (context, url, error) => const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 影片信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${video.category}' + 
                  '${video.area.isNotEmpty ? " · ${video.area}" : ""}' + 
                  '${video.year.isNotEmpty ? " · ${video.year}" : ""}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                // 功能按钮行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildImageActionButton(
                      'assets/xxmin/收藏_file-collection.png', 
                      isFavorited ? '已收藏' : '收藏', 
                      onTap: onToggleFavorite,
                      isActive: isFavorited
                    ),
                    _buildImageActionButton('assets/xxmin/分享_share.png', '分享'),
                    _buildImageActionButton(
                      'assets/xxmin/下载_download.png', 
                      isDownloaded ? '已下载' : isDownloading ? '下载中' : '下载', 
                      onTap: onHandleDownload,
                      isActive: isDownloaded || isDownloading
                    ),
                    _buildImageActionButton('assets/xxmin/催更_refresh.png', '催更'),
                    _buildImageActionButton('assets/xxmin/反馈_caution.png', '反馈'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageActionButton(String assetPath, String label, {VoidCallback? onTap, bool isActive = false}) {
    // 下载按钮特殊处理，显示下载状态
    if (label == '下载中') {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  assetPath,
                  width: 20,
                  height: 20,
                  color: Colors.blue,
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: downloadProgress,
                    strokeWidth: 2,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      );
    }
    
    // 其他按钮
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Image.asset(
            assetPath,
            width: 20,
            height: 20,
            color: isActive ? Colors.blue : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.blue : null,
            ),
          ),
        ],
      ),
    );
  }
} 