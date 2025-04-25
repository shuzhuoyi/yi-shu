import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../providers/video_provider.dart';
import '../models/video_model.dart';
import '../constants/app_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'video_detail_screen.dart';

class RankScreen extends StatefulWidget {
  const RankScreen({super.key});

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final videoProvider = Provider.of<VideoProvider>(context, listen: false);
      videoProvider.loadRankVideos();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, child) {
        final isLoading = videoProvider.isLoading;
        final rankVideos = videoProvider.rankVideos;
        
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: AppConstants.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppConstants.primaryColor,
                    tabs: const [
                      Tab(text: '热播榜'),
                      Tab(text: '电影榜'),
                      Tab(text: '剧集榜'),
                      Tab(text: '综艺榜'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: isLoading && rankVideos.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRankList(rankVideos),
                    _buildRankList(_filterByCategory(rankVideos, '电影')),
                    _buildRankList(_filterByCategory(rankVideos, '连续剧')),
                    _buildRankList(_filterByCategory(rankVideos, '综艺')),
                  ],
                ),
        );
      },
    );
  }
  
  List<Video> _filterByCategory(List<Video> videos, String category) {
    return videos.where((video) => video.category.contains(category)).toList();
  }
  
  Widget _buildRankList(List<Video> videos) {
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      header: ClassicHeader(
        refreshStyle: RefreshStyle.UnFollow,
        idleText: '下拉刷新',
        refreshingText: '刷新中',
        completeText: '完成',
        failedText: '失败',
        releaseText: '释放',
        refreshingIcon: const SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
        idleIcon: const Icon(Icons.arrow_downward, color: Colors.grey, size: 15),
        releaseIcon: const Icon(Icons.arrow_upward, color: Colors.grey, size: 15),
        textStyle: const TextStyle(color: Colors.grey, fontSize: 11),
        height: 30,
        completeIcon: const Icon(Icons.check, color: Colors.green, size: 15),
        failedIcon: const Icon(Icons.close, color: Colors.red, size: 15),
        completeDuration: const Duration(milliseconds: 300),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return _buildRankItem(video, index);
        },
      ),
    );
  }
  
  Widget _buildRankItem(Video video, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: InkWell(
        onTap: () => _onVideoTap(context, video),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 排名
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: index < 3 ? AppConstants.accentColor : Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 封面图
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  video.cover,
                  width: 80,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 影片信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '分类: ${video.category}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (video.director.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '导演: ${video.director}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (video.actor.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '演员: ${video.actor}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
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
  
  void _onRefresh() async {
    await Provider.of<VideoProvider>(context, listen: false).loadRankVideos();
    _refreshController.refreshCompleted();
  }
} 