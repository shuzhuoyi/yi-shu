import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../providers/video_provider.dart';
import '../models/video_model.dart';
import '../services/api_service.dart';
import 'video_detail_screen.dart';

class SearchResultScreen extends StatefulWidget {
  final String keyword;
  
  const SearchResultScreen({
    super.key,
    required this.keyword,
  });

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  
  @override
  void initState() {
    super.initState();
    _performSearch();
  }
  
  void _performSearch() {
    if (widget.keyword.isNotEmpty) {
      Provider.of<VideoProvider>(context, listen: false).searchVideos(widget.keyword);
    }
  }
  
  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, child) {
        final isLoading = videoProvider.isLoading;
        final searchResults = videoProvider.searchResults;
        
        return Scaffold(
          appBar: AppBar(
            title: Text('搜索: ${widget.keyword}'),
            elevation: 0,
          ),
          body: isLoading && searchResults.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '没有找到相关影片',
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
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final video = searchResults[index];
                          return _buildVideoItem(video);
                        },
                      ),
                    ),
        );
      },
    );
  }
  
  Widget _buildVideoItem(Video video) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: InkWell(
        onTap: () => _onVideoTap(context, video),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 封面图
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  video.cover,
                  width: 100,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    height: 140,
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
                    const SizedBox(height: 6),
                    Text(
                      '分类: ${video.category}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (video.year.isNotEmpty || video.area.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${video.year.isNotEmpty ? "${video.year} · " : ""}${video.area}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                    if (video.director.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '导演: ${video.director}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (video.actor.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '演员: ${video.actor}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      video.description,
                      style: TextStyle(color: Colors.grey[800], fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
    await Provider.of<VideoProvider>(context, listen: false).searchVideos(widget.keyword);
    _refreshController.refreshCompleted();
  }
} 