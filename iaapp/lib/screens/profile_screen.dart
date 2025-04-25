import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../models/video_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'favorites_screen.dart'; // 导入收藏页面
import 'downloads_screen.dart'; // 导入下载页面
import 'share_app_screen.dart'; // 导入分享APP页面
import 'request_movie_screen.dart'; // 导入请求电影页面
import 'check_update_screen.dart'; // 导入检查更新页面
import '../services/cache_service.dart';
import 'video_detail_screen.dart'; // 导入视频详情页面
import 'watch_history_screen.dart'; // 导入观看历史页面
import 'login_screen.dart'; // 导入登录页面
import 'user_detail_screen.dart'; // 导入用户详情页面
import '../services/storage_service.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();
  final StorageService _storageService = StorageService();
  List<Video> _historyVideos = [];
  bool _isLoading = true;
  String _cacheSize = '0 MB';
  
  // 实现 AutomaticKeepAliveClientMixin 的要求
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _loadHistoryVideos();
    _loadCacheSize();
  }
  
  Future<void> _loadHistoryVideos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 从StorageService获取观看历史
      final historyVideos = await _storageService.getWatchHistory();
      List<Video> displayVideos;
      
      if (historyVideos.isEmpty) {
        // 如果没有历史记录，使用模拟数据
        displayVideos = await _apiService.getVideoList(pageSize: 3);
      } else {
        // 只显示最近的3条记录
        displayVideos = historyVideos.length > 3 ? historyVideos.sublist(0, 3) : historyVideos;
      }
      
      if (mounted) {
        setState(() {
          _historyVideos = displayVideos;
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
  }
  
  // 加载缓存大小
  Future<void> _loadCacheSize() async {
    final cacheSize = await _cacheService.getCacheSize();
    if (mounted) {
      setState(() {
        _cacheSize = cacheSize;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 必须调用 super.build
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[100], // 设置浅灰色背景
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部安全区域
            SizedBox(height: MediaQuery.of(context).padding.top),
            
            // 用户信息卡片
            _buildUserInfoCard(context),
            
            const SizedBox(height: 10),
            
            // 观看历史卡片
            _buildWatchHistoryCard(context),
            
            const SizedBox(height: 10),
            
            // 常用功能卡片
            _buildCommonFunctionsCard(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserInfoCard(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final bool isLoggedIn = userProvider.isLoggedIn;
        final String username = userProvider.username;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              if (!isLoggedIn) {
                // 未登录时，点击跳转到登录页面
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                ).then((value) {
                  // 从登录页返回时刷新状态
                  if (value == true) {
                    setState(() {});
                  }
                });
              } else {
                // 已登录时，点击跳转到用户详情页或其他操作
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserDetailScreen()),
                ).then((value) {
                  // 如果用户从详情页返回并注销了，刷新状态
                  if (value == true) {
                    setState(() {});
                  }
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Row(
                children: [
                  // 头像或应用图标
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isLoggedIn ? Colors.blue.shade100 : AppConstants.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isLoggedIn
                        ? Center(
                            child: Text(
                              username.isNotEmpty ? username.substring(0, 1).toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.movie,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // 根据登录状态显示不同内容
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              isLoggedIn ? username : '登录|注册',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isLoggedIn ? Colors.blue.shade50 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isLoggedIn ? '会员' : '游客',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isLoggedIn ? Colors.blue : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLoggedIn ? '欢迎回来，尊敬的用户' : '会员登录享更多观影权益',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 箭头图标
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildWatchHistoryCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 屏幕宽度减去卡片边距和内部填充
    final availableWidth = screenWidth - 32 - 16; // 32是卡片左右边距，16是卡片内部左右填充
    // 计算每个历史项的宽度，确保能显示3个
    final itemWidth = (availableWidth - 4) / 3; // 4是历史项之间的间距

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '观看历史',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WatchHistoryScreen()),
                      );
                    },
                    child: Row(
                      children: const [
                        Text(
                          '更多',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 120,
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _historyVideos.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无观看记录',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (int i = 0; i < (_historyVideos.length > 3 ? 3 : _historyVideos.length); i++)
                          _buildHistoryItem(_historyVideos[i], itemWidth),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHistoryItem(Video video, double width) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoDetailScreen(video: video),
          ),
        ).then((_) => _loadHistoryVideos()); // 返回后刷新历史记录
      },
      child: Container(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 影片封面
            Container(
              height: 90,
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: video.cover,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade300,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 20),
                      ),
                    ),
                    // 清晰度标签
                    Positioned(
                      right: 3,
                      bottom: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          '1080P',
                          style: TextStyle(color: Colors.white, fontSize: 7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 3),
            // 标题
            Text(
              video.title,
              style: const TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCommonFunctionsCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '常用功能',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 5,
              crossAxisSpacing: 0,
              childAspectRatio: 1.0,
              padding: EdgeInsets.zero,
              children: [
                _buildImageFunctionItem(context, '我的收藏', 'assets/tbmin/我的收藏_file-collection-one.png'),
                _buildImageFunctionItem(context, '我的下载', 'assets/tbmin/我的下载_download.png'),
                _buildImageFunctionItem(context, '分享APP', 'assets/tbmin/分享APP_share.png'),
                _buildImageFunctionItem(context, '消息', 'assets/tbmin/消息_remind.png'),
                _buildImageFunctionItem(context, '留言求片', 'assets/tbmin/留言求片_email-delect.png'),
                _buildImageFunctionItem(context, '检查升级', 'assets/tbmin/检查升级_update-rotation.png'),
                _buildImageFunctionItem(context, '清理缓存', 'assets/tbmin/清理缓存_delete.png'),
                _buildImageFunctionItem(context, '设置', 'assets/tbmin/设置_setting.png'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFunctionItem(
    BuildContext context, 
    String title,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildImageFunctionItem(
    BuildContext context, 
    String title,
    String imagePath,
  ) {
    // 为清理缓存项添加缓存大小显示
    String displayText = title;
    if (title == '清理缓存') {
      displayText = '清理缓存\n$_cacheSize';
    }
    
    return InkWell(
      onTap: () {
        // 根据标题决定跳转到不同的页面
        if (title == '我的收藏') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FavoritesScreen()),
          );
        } else if (title == '我的下载') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DownloadsScreen()),
          );
        } else if (title == '分享APP') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ShareAppScreen()),
          );
        } else if (title == '留言求片') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RequestMovieScreen()),
          );
        } else if (title == '检查升级') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CheckUpdateScreen()),
          );
        } else if (title == '清理缓存') {
          _clearCache();
        } else {
          // 其他功能的处理逻辑
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title功能即将上线'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                imagePath,
                width: 16,
                height: 16,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            displayText,
            style: const TextStyle(fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理缓存'),
        content: Text('确定要清理缓存吗？当前缓存大小：$_cacheSize'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // 显示加载对话框
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              // 执行清理
              final result = await _cacheService.clearCache();
              
              // 关闭加载对话框
              if (mounted) Navigator.pop(context);
              
              if (result && mounted) {
                // 重新获取缓存大小
                await _loadCacheSize();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('缓存清理成功'),
                    duration: Duration(seconds: 1),
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('缓存清理失败'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}