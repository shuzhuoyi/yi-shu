import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../providers/video_provider.dart';
import '../constants/app_constants.dart';
import '../widgets/search_box.dart';
import '../widgets/category_list.dart';
import '../widgets/carousel_slider_widget.dart';
import '../widgets/video_list_section.dart';
import '../widgets/video_card.dart';
import '../models/video_model.dart';
import '../models/category_model.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../services/home_loader_service.dart';
import '../widgets/home_sections.dart';
import 'search_result_screen.dart';
import 'category_videos_screen.dart';
import 'video_detail_screen.dart';
import 'downloads_screen.dart';
import 'watch_history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// 使用AutomaticKeepAliveClientMixin保持状态
class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  DateTime _lastRefreshTime = DateTime.now();
  
  // 存储各分类的视频，直接从API获取
  Map<String, List<Video>> _categoryVideosCache = {};
  // 存储轮播图数据
  List<Video> _carouselVideos = [];
  bool _isLoadingCategoryVideos = false;
  
  // 已加载的分类ID集合，用于避免重复加载
  Set<String> _loadedCategoryIds = {};
  bool _initialDataLoaded = false;
  
  // 数据加载服务
  late HomeLoaderService _loaderService;

  // 实现AutomaticKeepAliveClientMixin的要求
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // 立即从Provider获取已加载的数据，不再使用延迟
      _initializeData();
  }
  
  // 初始化数据加载服务和数据
  void _initializeData() {
    _loaderService = HomeLoaderService(context);
    
    // 从Provider获取已加载的数据
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    
    // 检查Provider中是否已有数据
      final categories = videoProvider.categories;
    final categoryVideosMap = videoProvider.categoryVideosMap;
      
    if (categories.isNotEmpty && categoryVideosMap.isNotEmpty) {
      print('Provider中已有数据，直接使用缓存数据');
      
      // 直接使用Provider中的缓存数据
      setState(() {
        _categoryVideosCache = Map.from(categoryVideosMap);
        
        // 标记所有已缓存的分类为已加载
        _loadedCategoryIds = categoryVideosMap.keys.toSet();
        _initialDataLoaded = true;
        
        // 设置轮播图数据
        if (categories.length > 1 && _categoryVideosCache.isNotEmpty) {
          _setCarouselVideosFromCategories(categories, _categoryVideosCache);
      }
      });
    } else {
      // 如果Provider中没有数据，才进行加载
      print('Provider中没有数据，需要加载数据');
    _loaderService.initializeData(
      updateLoadingState: (isLoading) {
        setState(() {
          _isLoadingCategoryVideos = isLoading;
        });
      }
    ).then((_) {
      // 加载完成后，更新UI数据
      setState(() {
        _categoryVideosCache = _loaderService.categoryVideosCache;
        
        // 更新轮播图数据源
        final categories = Provider.of<VideoProvider>(context, listen: false).categories;
        final categoryMap = _categoryVideosCache;
        
        if (categories.length > 1 && categoryMap.isNotEmpty) {
          _setCarouselVideosFromCategories(categories, categoryMap);
        }
        
        _loadedCategoryIds = _loaderService.loadedCategoryIds;
        _initialDataLoaded = _loaderService.initialDataLoaded;
      });
    });
    }
  }
  
  // 从分类中设置轮播图数据
  void _setCarouselVideosFromCategories(List<Category> categories, Map<String, List<Video>> categoryMap) {
    // 重置轮播图数据
    _carouselVideos = [];
    
    print('开始设置轮播图数据，共有 ${categories.length} 个分类，${categoryMap.length} 个分类的视频缓存');
    
    // 寻找第一个有视频的非推荐分类
    for (var category in categories) {
      if (category.id != '0') {
        final categoryId = category.id;
        if (categoryMap.containsKey(categoryId) && 
            categoryMap[categoryId]!.isNotEmpty) {
          // 选取该分类下最多5个视频作为轮播图
          final availableVideos = categoryMap[categoryId]!;
          _carouselVideos = availableVideos.take(5).toList();
          print('设置轮播图数据为[${category.name}]分类，共${_carouselVideos.length}个视频');
          break;
        }
      }
    }
    
    // 如果没有找到合适的非推荐分类，尝试使用推荐分类
    if (_carouselVideos.isEmpty && categoryMap.containsKey('0') && categoryMap['0']!.isNotEmpty) {
      _carouselVideos = categoryMap['0']!.take(5).toList();
      print('未找到合适的非推荐分类视频，使用推荐分类视频作为轮播图，共${_carouselVideos.length}个视频');
    }
    
    // 打印最终设置的轮播图数据
    if (_carouselVideos.isNotEmpty) {
      print('成功设置${_carouselVideos.length}个轮播图视频, 第一个视频标题: ${_carouselVideos.first.title}');
    } else {
      print('未能设置轮播图数据，使用空轮播');
    }
  }
  
  // 加载单个分类的视频（切换分类时使用）
  Future<void> _loadCategoryVideos(String categoryId, String categoryName) async {
    await _loaderService.loadCategoryVideos(
      categoryId, 
      updateLoadingState: (isLoading) {
        setState(() {
          _isLoadingCategoryVideos = isLoading;
        });
      }
    );
    
    // 加载完成后更新本地缓存
        setState(() {
      _categoryVideosCache = _loaderService.categoryVideosCache;
      _loadedCategoryIds = _loaderService.loadedCategoryIds;
        });
  }
  
  void _updateLastRefreshTime() {
    setState(() {
      _lastRefreshTime = DateTime.now();
    });
  }
  
  Future<void> _onRefresh() async {
    // 移除时间限制，确保每次都可以刷新
    print('执行下拉刷新操作');
    
    // 标记刷新状态但不清空现有数据
    setState(() {
      _isLoadingCategoryVideos = true;
    });
    
    // 强制刷新Provider中的数据
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    
    try {
      // 重新加载分类
      await videoProvider.loadCategories();
      
      // 重新初始化数据，但保持现有内容可见
      await _loaderService.initializeData(
        updateLoadingState: (isLoading) {
          setState(() {
            _isLoadingCategoryVideos = isLoading;
    });
        }
      );
      
      // 刷新成功后才更新UI数据
      setState(() {
        _categoryVideosCache = _loaderService.categoryVideosCache;
        _loadedCategoryIds = _loaderService.loadedCategoryIds;
        _initialDataLoaded = _loaderService.initialDataLoaded;
        
        // 更新轮播图数据源
        final categories = videoProvider.categories;
        final categoryMap = _categoryVideosCache;
        
        if (categories.length > 1 && categoryMap.isNotEmpty) {
          _setCarouselVideosFromCategories(categories, categoryMap);
        }
      });
      
      print('刷新操作成功完成');
    } catch (e) {
      print('刷新操作失败: $e');
      // 刷新失败时显示提示，但保留原有内容
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('刷新失败，请稍后再试'),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
    _updateLastRefreshTime();
    _refreshController.refreshCompleted();
      setState(() {
        _isLoadingCategoryVideos = false;
      });
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 必须调用super.build
    super.build(context);
    
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, child) {
        final isLoading = videoProvider.isLoading || _isLoadingCategoryVideos;
        final isLoadingMore = videoProvider.isLoadingMore;
        final currentCategory = videoProvider.currentCategory;
        final currentCategoryId = videoProvider.currentCategoryId;
        final categories = videoProvider.categories;
        final categoryVideosMap = videoProvider.categoryVideosMap;
        
        // 同步缓存中还没有的当前分类数据 - 简化逻辑，只关注当前分类
        if (currentCategoryId != '0' && !_loadedCategoryIds.contains(currentCategoryId) &&
            categoryVideosMap.containsKey(currentCategoryId) && !isLoading) {
          // 在帧结束时更新状态，避免在build中setState
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _categoryVideosCache[currentCategoryId] = categoryVideosMap[currentCategoryId]!;
              _loadedCategoryIds.add(currentCategoryId);
            });
          });
        } 
        // 如果当前分类数据尚未加载，触发加载
        else if (currentCategoryId != '0' && !_loadedCategoryIds.contains(currentCategoryId) && 
            !categoryVideosMap.containsKey(currentCategoryId) && !isLoading) {
          // 使用Frame回调避免在build过程中setState
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadCategoryVideos(currentCategoryId, currentCategory);
          });
        }
        
        // 创建分类视频列表 - 优化视频列表创建逻辑
        List<Widget> categoryVideoSections = [];
        
        // 如果分类列表为空，不显示任何内容
        if (categories.isEmpty) {
          // 什么都不做，等待分类加载完成
        }
        // 如果当前分类是"推荐"(ID=0)，显示多个分类的视频列表
        else if (categories.isNotEmpty && currentCategoryId == '0') {
          // 显示推荐分类视频（最多显示4个主要分类）
          _buildRecommendCategorySections(categories, categoryVideoSections);
        } else {
          // 显示当前分类的视频
          _buildCurrentCategorySection(currentCategoryId, currentCategory, 
                                     categoryVideosMap, categoryVideoSections);
        }
        
        // 返回主界面Scaffold
        return _buildMainScaffold(context, currentCategoryId, categoryVideoSections);
      },
    );
  }
  
  // 构建推荐页面分类部分
  void _buildRecommendCategorySections(List<Category> categories, List<Widget> categoryVideoSections) {
    print('构建推荐页面分类部分，有 ${categories.length} 个分类可用');
    
    int shownCategories = 0;
    
    // 遍历分类（跳过"推荐"分类）
    for (int i = 1; i < categories.length && shownCategories < 4; i++) {
      final category = categories[i];
      final categoryId = category.id;
      final categoryName = category.name;
      
      // 从缓存中获取视频
      if (_categoryVideosCache.containsKey(categoryId) && _categoryVideosCache[categoryId]!.isNotEmpty) {
        List<Video> categoryVideos = _categoryVideosCache[categoryId]!;
        print('添加分类[$categoryName]，共 ${categoryVideos.length} 个视频');
        
        categoryVideoSections.add(
          buildCategorySection(context, categoryName, categoryVideos, categoryId),
        );
        shownCategories++;
      } else {
        print('分类[$categoryName]没有视频或未加载，跳过');
      }
    }
    
    // 如果没有找到任何分类视频，显示一个友好的提示
    if (shownCategories == 0) {
      categoryVideoSections.add(
        _buildNoContentMessage('暂无分类内容', '请下拉刷新或稍后再试')
      );
    }
  }
  
  // 构建无内容提示
  Widget _buildNoContentMessage(String title, String subtitle) {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '正在加载内容',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '请稍候...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建当前分类部分
  void _buildCurrentCategorySection(String currentCategoryId, String currentCategory, 
                                  Map<String, List<Video>> categoryVideosMap, 
                                  List<Widget> categoryVideoSections) {
    // 先尝试使用本地缓存
          if (_loadedCategoryIds.contains(currentCategoryId)) {
            if (_categoryVideosCache.containsKey(currentCategoryId) && 
                _categoryVideosCache[currentCategoryId]!.isNotEmpty) {
              categoryVideoSections.add(
                buildCategorySection(context, currentCategory, _categoryVideosCache[currentCategoryId]!, currentCategoryId),
              );
            } else {
              categoryVideoSections.add(
                buildEmptyStateSection(currentCategory),
              );
            }
    } 
    // 再尝试使用Provider缓存
    else if (categoryVideosMap.containsKey(currentCategoryId)) {
            if (categoryVideosMap[currentCategoryId]!.isNotEmpty) {
              categoryVideoSections.add(
                buildCategorySection(context, currentCategory, categoryVideosMap[currentCategoryId]!, currentCategoryId),
              );
            } else {
              categoryVideoSections.add(
                buildEmptyStateSection(currentCategory),
              );
            }
    } 
    // 没有任何缓存，显示空状态
    else {
            categoryVideoSections.add(
        buildEmptyStateSection(currentCategory),
            );
          }
        }
        
  // 构建主界面Scaffold
  Widget _buildMainScaffold(BuildContext context, String currentCategoryId, List<Widget> categoryVideoSections) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // 顶部安全区域
              SizedBox(height: MediaQuery.of(context).padding.top),
              
              // 顶部搜索栏 (固定)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: Row(
                  children: [
                    // App图标
                    GestureDetector(
                      onTap: _navigateToLogin,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.movie_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 搜索框
                    Expanded(
                      child: SearchBox(
                        controller: _searchController,
                        onSearch: _handleSearch,
                        onDownloadTap: _navigateToDownloads,
                        onUserTap: _navigateToWatchHistory,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 分类导航 (固定)
              CategoryList(
            currentCategory: Provider.of<VideoProvider>(context).currentCategory,
            onCategorySelected: _handleCategorySelection,
              ),
              
              // 添加分隔线，使界面更美观
              Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.grey.withOpacity(0.2),
              ),
              
              // 内容区域 (可滚动)
              Expanded(
                child: SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  enablePullUp: currentCategoryId != '0', // 只在非推荐分类启用上拉加载更多
                  onLoading: _onLoadMore, // 上拉加载更多回调
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
                  footer: CustomFooter(
                    builder: (context, mode) {
                      Widget body;
                      if (mode == LoadStatus.idle) {
                        body = Text("上拉加载更多", style: TextStyle(color: Colors.grey[600], fontSize: 13));
                      } else if (mode == LoadStatus.loading) {
                        body = Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16, 
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text("加载中...", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        );
                      } else if (mode == LoadStatus.failed) {
                        body = Text("加载失败，点击重试", style: TextStyle(color: Colors.grey[600], fontSize: 13));
                      } else if (mode == LoadStatus.canLoading) {
                        body = Text("释放加载更多", style: TextStyle(color: Colors.grey[600], fontSize: 13));
                      } else {
                        body = Text("没有更多数据了", style: TextStyle(color: Colors.grey[600], fontSize: 13));
                      }
                      return Container(
                        height: 55.0,
                        child: Center(child: body),
                      );
                    },
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 轮播图 (只在推荐分类显示)
                        if (currentCategoryId == '0')
                          _carouselVideos.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: CarouselSliderWidget(
                                  videos: _carouselVideos,
                                  onTap: (video) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VideoDetailScreen(video: video),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : _buildEmptyCarousel(),
                        
                        // 分类视频列表
                        ...categoryVideoSections,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }
  
  // 构建空轮播图状态
  Widget _buildEmptyCarousel() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '正在加载内容...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
      ),
    );
  }
  
  // 处理分类选择
  void _handleCategorySelection(String categoryId) {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    final categories = videoProvider.categories;
    
    // 如果选择的是当前已经显示的分类，不做任何操作
    if (categoryId == videoProvider.currentCategoryId) {
      return;
    }
    
    // 首先检查VideoProvider中是否已有该分类的缓存数据
    final categoryVideosMap = videoProvider.categoryVideosMap;
    
    // 设置当前分类ID（这会触发UI刷新）
    videoProvider.setCurrentCategoryById(categoryId);
    
    if (categoryId != "0" && !_loadedCategoryIds.contains(categoryId)) {
      if (categoryVideosMap.containsKey(categoryId)) {
        // VideoProvider已有该分类缓存数据，直接使用
        setState(() {
          _categoryVideosCache[categoryId] = categoryVideosMap[categoryId]!;
          _loadedCategoryIds.add(categoryId);
        });
      } else {
        // VideoProvider中没有缓存，需要加载
        setState(() {
          _isLoadingCategoryVideos = true;
        });
        
        // 立即加载分类数据
        final categoryName = categories
            .firstWhere((c) => c.id == categoryId, 
                      orElse: () => Category(id: categoryId, name: '未知分类'))
            .name;
        
        // 使用Frame回调避免在build过程中setState
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _loadCategoryVideos(categoryId, categoryName);
        });
      }
    }
  }
  
  Widget _buildCategorySection(String title, List<Video> videos, [String sectionCategoryId = '0']) {
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
        // 分类标题
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
              if (isRecommendSection && sectionCategoryId != '0')
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
  
  void _handleSearch() {
    if (_searchController.text.trim().isNotEmpty) {
      final provider = Provider.of<VideoProvider>(context, listen: false);
      provider.searchVideos(_searchController.text.trim());
      // 导航到搜索结果页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultScreen(
            keyword: _searchController.text.trim(),
          ),
        ),
      );
    }
  }
  
  void _onVideoTap(BuildContext context, Video video) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('视频详情页已移除: ${video.title}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  void _navigateToCategoryVideos(String categoryName, String categoryId) {
    print('导航到分类视频页面: $categoryName, ID: $categoryId');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryVideosScreen(
          category: categoryName,
          categoryId: categoryId,
        ),
      ),
    );
  }
  
  void _navigateToDownloads() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DownloadsScreen(),
      ),
    );
  }
  
  void _navigateToWatchHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WatchHistoryScreen(),
      ),
    );
  }

  // 当点击视频卡片时
  Video? _onVideoCardTap(Video video) {
    // 将方法修改为返回Video，这样类型会匹配
    return video;
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  // 构建空状态提示
  Widget _buildEmptyStateSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分类标题
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 6, bottom: 2),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 加载中提示
        Container(
          height: 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '正在加载内容',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '请稍候...',
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

  // 上拉加载更多
  Future<void> _onLoadMore() async {
    print('===== 触发上拉加载更多操作 =====');
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    final currentCategoryId = videoProvider.currentCategoryId;
    
    await _loaderService.loadMoreVideos(
      currentCategoryId,
      updateCategoryCache: (latestVideos) {
        setState(() {
          _categoryVideosCache[currentCategoryId] = latestVideos;
        });
      },
      onNoMoreData: () {
        _refreshController.loadNoData();
      },
      onLoadFailed: (error) {
        _refreshController.loadFailed();
        print('❌ 加载更多失败: $error');
      }
    );
    
    // 如果没有触发上面的回调，说明加载成功且还有更多数据
    _refreshController.loadComplete();
  }
} 