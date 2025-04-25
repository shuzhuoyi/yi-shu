import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_model.dart';
import '../providers/video_provider.dart';
import '../constants/app_constants.dart';
import 'video_card.dart';
import '../screens/video_detail_screen.dart';

/// 构建分类视频部分
Widget buildCategorySection(BuildContext context, String title, List<Video> videos, [String sectionCategoryId = '0']) {
  // 确定是否在推荐分类下显示，如果是推荐则限制为6个视频，否则显示所有加载的视频
  final currentCategoryId = Provider.of<VideoProvider>(context, listen: false).currentCategoryId;
  final bool isRecommendSection = currentCategoryId == '0';
  
  // 在推荐分类下每个分类显示6个视频，在分类详情页显示所有视频
  // 直接使用原始视频列表
  List<Video> displayVideos = List.from(videos);
  
  print('构建分类 $title (ID: $sectionCategoryId) 的视频部分，视频总数: ${videos.length}，显示数量: ${isRecommendSection ? '最多6个' : '全部'}');
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 分类标题 - 只在推荐分类下显示
      if (isRecommendSection)
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 6, bottom: 2),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (sectionCategoryId != '0')
                GestureDetector(
                  onTap: () {
                    print('点击了"$title"分类的"更多"按钮，分类ID: $sectionCategoryId');
                    // 切换到对应的分类标签，而不是导航到新页面
                    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
                    videoProvider.setCurrentCategoryById(sectionCategoryId);
                  },
                  child: Row(
                    children: [
                      Text(
                        '更多',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      // 视频网格
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.60,
          crossAxisSpacing: 2,
          mainAxisSpacing: 0.5,
        ),
        itemCount: isRecommendSection ? 
                  (displayVideos.length > 6 ? 6 : displayVideos.length) : // 推荐模式下最多显示6个
                  displayVideos.length, // 分类详情模式下显示全部
        itemBuilder: (context, index) {
          return VideoCard(
            video: displayVideos[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoDetailScreen(video: displayVideos[index]),
                ),
              );
            },
          );
        },
      ),
      const SizedBox(height: 2), // 极小的底部间距
    ],
  );
}

/// 构建空状态提示
Widget buildEmptyStateSection(String title) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 分类标题 - 只在推荐分类下显示
      // 注意：这里不需要判断是否为推荐分类，因为该函数只在分类详情页面调用时才会用到
      // 所以可以直接移除标题显示
      // 空状态提示
      Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.movie_filter,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 10),
            Text(
              '该分类暂无视频',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '请选择其他分类查看',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    ],
  );
} 