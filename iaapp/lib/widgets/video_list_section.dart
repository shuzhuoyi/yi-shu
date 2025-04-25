import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/video_model.dart';
import 'video_card.dart';

class VideoListSection extends StatelessWidget {
  final String title;
  final List<Video> videos;
  final Function(Video) onVideoTap;
  final VoidCallback? onMoreTap;
  
  const VideoListSection({
    super.key,
    required this.title,
    required this.videos,
    required this.onVideoTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分区标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onMoreTap != null)
                GestureDetector(
                  onTap: onMoreTap,
                  child: Text(
                    '更多 >',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // 视频网格
        SizedBox(
          height: 220,
          child: AnimationLimiter(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: videos.length > 6 ? 6 : videos.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    horizontalOffset: 50.0,
                    child: FadeInAnimation(
                      child: SizedBox(
                        width: 120,
                        child: VideoCard(
                          video: videos[index],
                          onTap: () => onVideoTap(videos[index]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
} 