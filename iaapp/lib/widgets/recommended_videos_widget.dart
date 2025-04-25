import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../models/video_model.dart';
import '../screens/video_detail_screen.dart';
import 'video_card.dart'; // 导入VideoCard组件

class RecommendedVideosWidget extends StatelessWidget {
  const RecommendedVideosWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 从VideoProvider获取视频数据
    final videoProvider = Provider.of<VideoProvider>(context);
    
    // 获取推荐视频列表，如果homeVideos中的视频不足，则尝试从其他分类获取
    List<Video> recommendedVideos = [];
    
    // 首先检查是否有足够的首页视频
    if (videoProvider.homeVideos.length > 12) {
      // 从首页视频中随机选择一部分作为推荐
      recommendedVideos = videoProvider.homeVideos.take(18).toList();
      // 打乱顺序，增加随机性
      recommendedVideos.shuffle();
      // 取前12个
      recommendedVideos = recommendedVideos.take(12).toList();
    } else {
      // 尝试从所有分类中获取视频
      final Map<String, List<Video>> categoryVideosMap = videoProvider.categoryVideosMap;
      final List<Video> allVideos = [];
      
      // 收集所有分类的视频
      categoryVideosMap.forEach((categoryId, videos) {
        if (videos.isNotEmpty) {
          allVideos.addAll(videos);
        }
      });
      
      // 如果有视频，随机选择12个
      if (allVideos.isNotEmpty) {
        allVideos.shuffle();
        recommendedVideos = allVideos.take(12).toList();
      }
    }
    
    // 如果没有推荐视频，返回空容器
    if (recommendedVideos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 14.0, right: 14.0, top: 0.0, bottom: 0.0),
          child: Text(
            '猜你喜欢',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // 使用网格布局代替横向滚动列表
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: GridView.builder(
            shrinkWrap: true, // 让GridView自适应内容高度
            physics: const NeverScrollableScrollPhysics(), // 禁止GridView自身滚动
            padding: EdgeInsets.zero, // 移除内部边距
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 每行3个
              childAspectRatio: 0.6, // 调整宽高比使卡片更窄更短
              crossAxisSpacing: 4, // 减小水平间距
              mainAxisSpacing: 0.5, // 减少到0.5px垂直间距
            ),
            itemCount: recommendedVideos.length,
            itemBuilder: (context, index) {
              final video = recommendedVideos[index];
              // 使用与首页相同的VideoCard组件
              return VideoCard(
                video: video,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoDetailScreen(video: video),
                    ),
                  );
                },
                showUpdateInfo: true,
              );
            },
          ),
        ),
      ],
    );
  }
} 