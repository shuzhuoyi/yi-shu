import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../models/category_model.dart' as model;
import '../services/api_service.dart';

class VideoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Video> _homeVideos = [];
  List<Video> _rankVideos = [];
  List<Video> _searchResults = [];
  List<model.Category> _categories = [];
  Map<String, List<Video>> _categoryVideosMap = {}; // 存储各分类的视频
  String _currentCategory = '推荐'; // 默认设置为"推荐"
  String _currentCategoryId = '0'; // 默认分类ID为"0"（推荐）
  bool _isLoading = false;
  
  // 分页相关
  Map<String, int> _categoryCurrentPage = {}; // 存储各分类当前页码
  Map<String, bool> _categoryHasMore = {}; // 存储各分类是否有更多数据
  bool _isLoadingMore = false; // 是否正在加载更多
  
  // 连续空页计数
  Map<String, int> _consecutiveEmptyPages = {};
  
  // 新增的变量
  Map<String, bool> _categoryNoMoreData = {}; // 存储各分类是否没有更多数据
  
  // 构造函数
  VideoProvider() {
    print('VideoProvider初始化，默认分类: $_currentCategory, ID: $_currentCategoryId');
  }
  
  // getter
  List<Video> get homeVideos => _homeVideos;
  List<Video> get rankVideos => _rankVideos;
  List<Video> get searchResults => _searchResults;
  List<model.Category> get categories => _categories;
  String get currentCategory => _currentCategory;
  String get currentCategoryId => _currentCategoryId;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  Map<String, List<Video>> get categoryVideosMap => _categoryVideosMap;
  
  // 设置当前分类(通过分类名称)
  void setCurrentCategory(String category) {
    _currentCategory = category;
    
    // 更新当前分类ID
    final categoryObj = _categories.firstWhere(
      (item) => item.name == category, 
      orElse: () => model.Category(id: '0', name: '推荐')
    );
    _currentCategoryId = categoryObj.id;
    
    print('设置当前分类: $_currentCategory, ID: $_currentCategoryId');
    notifyListeners();
  }
  
  // 设置当前分类(通过分类ID)
  void setCurrentCategoryById(String id) {
    // 如果当前分类ID相同，跳过处理
    if (_currentCategoryId == id) {
      print('分类ID未变化(${id})，跳过状态更新');
      return;
    }
    
    _currentCategoryId = id;
    
    // 更新当前分类名称
    final categoryObj = _categories.firstWhere(
      (item) => item.id == id, 
      orElse: () => model.Category(id: '0', name: '推荐')
    );
    _currentCategory = categoryObj.name;
    
    print('通过ID设置当前分类: $_currentCategory, ID: $_currentCategoryId');
    
    // 只进行UI状态更新，不再主动加载数据
    // 数据加载由HomeScreen控制，避免重复加载
    notifyListeners();
  }
  
  // 设置加载状态
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // 设置加载更多状态
  void setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }
  
  // 加载首页视频
  Future<void> loadHomeVideos() async {
    setLoading(true);
    
    // 先清空视频列表，避免显示旧数据
    _homeVideos = [];
    notifyListeners();
    
    try {
      print('开始加载首页视频数据...');
      final videos = await _apiService.getVideoList(pageSize: 18);
      print('加载完成，获取到 ${videos.length} 个视频');
      
      if (videos.isNotEmpty) {
        _homeVideos = videos;
        print('首页视频数据更新成功，第一个视频标题: ${videos.first.title}');
        
        // 在加载首页视频后，预加载各个分类的视频
        preloadCategoryVideos();
      } else {
        print('警告: API返回了空的视频列表');
        // 确保视频列表为空
        _homeVideos = [];
      }
      
      notifyListeners();
    } catch (e) {
      print('加载首页视频失败: $e');
      _homeVideos = []; // 确保失败时也清空视频列表
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }
  
  // 加载分类数据
  Future<void> loadCategories() async {
    int retryCount = 0;
    const maxRetries = 3;
    
    // 保存旧数据的临时变量
    final oldCategoryVideosMap = Map<String, List<Video>>.from(_categoryVideosMap);
    final oldCategoryCurrentPage = Map<String, int>.from(_categoryCurrentPage);
    final oldCategoryHasMore = Map<String, bool>.from(_categoryHasMore);
    final oldCategoryNoMoreData = Map<String, bool>.from(_categoryNoMoreData);
    final oldConsecutiveEmptyPages = Map<String, int>.from(_consecutiveEmptyPages);
    final oldHomeVideos = List<Video>.from(_homeVideos);
    final oldCategories = List<model.Category>.from(_categories);
    
    // 设置加载状态，通知UI
    setLoading(true);
    
    try {
    while (retryCount < maxRetries) {
      try {
        print('开始加载分类数据...(尝试 ${retryCount + 1}/${maxRetries})');
        final categories = await _apiService.getNewCategoryList();
        
        if (categories.isNotEmpty) {
          // 确保"推荐"分类始终在第一位
          final recommendIndex = categories.indexWhere((c) => c.id == '0');
          if (recommendIndex == -1) {
            // 如果API没有返回"推荐"分类，手动添加
            categories.insert(0, model.Category(id: '0', name: '推荐'));
          } else if (recommendIndex > 0) {
            // 如果"推荐"分类不在第一位，移动到第一位
            final recommend = categories.removeAt(recommendIndex);
            categories.insert(0, recommend);
          }
          
          // 打印当前所有分类
          print('成功加载 ${categories.length} 个分类:');
          for (int i = 0; i < categories.length; i++) {
            print('  ${i+1}. ${categories[i].name} (ID: ${categories[i].id})');
          }
          
            // 加载成功后，清除旧数据
            _categoryVideosMap.clear();
            _categoryCurrentPage.clear();
            _categoryHasMore.clear();
            _categoryNoMoreData.clear();
            _consecutiveEmptyPages.clear();
            _homeVideos.clear();
            
            // 更新分类列表
          _categories = categories;
          notifyListeners();
            
          return; // 成功加载，跳出循环
        } else {
          print('警告: API返回了空的分类列表，使用推荐分类');
            
            // 清除旧数据
            _categoryVideosMap.clear();
            _categoryCurrentPage.clear();
            _categoryHasMore.clear();
            _categoryNoMoreData.clear();
            _consecutiveEmptyPages.clear();
            _homeVideos.clear();
            
            // 设置默认分类
          _categories = [
            model.Category(id: '0', name: '推荐'),
          ];
          notifyListeners();
            
          return; // 虽然只有推荐分类，但也算成功加载
        }
      } catch (e) {
        print('加载分类失败: $e');
        retryCount++;
        
        if (retryCount < maxRetries) {
          // 指数退避重试，每次等待时间翻倍
          final waitTime = Duration(milliseconds: 500 * (1 << retryCount));
          print('将在 ${waitTime.inMilliseconds}毫秒后重试...');
          await Future.delayed(waitTime);
        }
      }
    }
    
      // 如果所有重试都失败，恢复旧数据
      print('所有重试失败，保留现有数据');
      _categoryVideosMap = oldCategoryVideosMap;
      _categoryCurrentPage = oldCategoryCurrentPage;
      _categoryHasMore = oldCategoryHasMore;
      _categoryNoMoreData = oldCategoryNoMoreData;
      _consecutiveEmptyPages = oldConsecutiveEmptyPages;
      _homeVideos = oldHomeVideos;
      
      // 如果没有现有分类数据，使用默认分类
      if (_categories.isEmpty) {
    _categories = [
      model.Category(id: '0', name: '推荐'),
    ];
      }
      
    notifyListeners();
    } finally {
      setLoading(false);
    }
  }
  
  // 预加载各分类视频
  Future<void> preloadCategoryVideos() async {
    // 确保分类已加载
    if (_categories.isEmpty) {
      print('分类列表为空，先加载分类列表');
      await loadCategories();
    }
    
    if (_categories.isEmpty) {
      print('分类列表仍为空，无法预加载分类视频');
      return;
    }
    
    print('开始预加载各分类的视频数据');
    
    // 创建一个映射存储各分类的视频
    _categoryVideosMap = {};
    
    // 针对所有分类预加载，但限制并行数量，避免过多请求
    List<String> categoryIds = _categories
        .map((category) => category.id)
        .toList();
    
    // 限制最多预加载6个分类
    if (categoryIds.length > 6) {
      categoryIds = categoryIds.sublist(0, 6);
    }
    
    print('将预加载 ${categoryIds.length} 个分类的视频');
    
    // 并行加载各分类视频
    await Future.wait(categoryIds.map((categoryId) async {
      try {
        final categoryName = _categories.firstWhere((c) => c.id == categoryId).name;
        print('预加载分类 $categoryName (ID: $categoryId) 的视频');
        
        final videos = await loadVideosByCategoryId(categoryId, forceRefresh: true);
        print('成功预加载 ${videos.length} 个 $categoryName (ID: $categoryId) 分类的视频');
      } catch (e) {
        print('预加载分类ID $categoryId 的视频失败: $e');
        // 确保即使失败也有一个空列表
        _categoryVideosMap[categoryId] = [];
      }
    }));
    
    print('所有分类视频预加载完成，共预加载了 ${_categoryVideosMap.length} 个分类的视频');
  }
  
  // 加载排行榜视频
  Future<void> loadRankVideos() async {
    setLoading(true);
    try {
      _rankVideos = await _apiService.getVideoList(pageSize: 20);
      notifyListeners();
    } catch (e) {
      print('加载排行榜视频失败: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // 根据分类ID加载视频，支持分页
  Future<List<Video>> loadVideosByCategoryId(String categoryId, {bool forceRefresh = false, int page = 1}) async {
    // 如果是首页推荐分类，直接返回首页视频
    if (categoryId == '0') {
      return _homeVideos;
    }
    
    // 如果是强制刷新或首次加载，重置页码
    if (forceRefresh || page == 1) {
      _categoryCurrentPage[categoryId] = 1;
      // 重置为有更多数据
      _categoryHasMore[categoryId] = true;
      // 重置没有更多数据标志
      _categoryNoMoreData.remove(categoryId);
      // 重置连续空页计数
      _consecutiveEmptyPages[categoryId] = 0;
    }
    
    // 如果没有强制刷新，不是加载更多，且已缓存该分类视频，直接返回（即使是空列表）
    if (!forceRefresh && page == 1 && _categoryVideosMap.containsKey(categoryId)) {
      print('使用缓存的分类视频，分类ID: $categoryId，视频数量: ${_categoryVideosMap[categoryId]!.length}');
      return _categoryVideosMap[categoryId]!;
    }
    
    try {
      print('开始加载分类 $categoryId 的视频，页码: $page, 目前已缓存数量: ${_categoryVideosMap.containsKey(categoryId) ? _categoryVideosMap[categoryId]!.length : 0}');
      
      // 如果是加载更多，设置加载更多状态
      if (page > 1) {
        setLoadingMore(true);
      }
      
      final videos = await _apiService.getVideoList(category: categoryId, page: page, pageSize: 18, forceRefresh: forceRefresh);
      print('成功从API获取 ${videos.length} 个分类 $categoryId 的视频，页码: $page');
      
      // 判断是否有更多数据
      if (videos.isEmpty) {
        // API返回空列表，表示确实没有更多数据了
        _categoryHasMore[categoryId] = false;
        // 标记为没有更多数据
        _categoryNoMoreData[categoryId] = true;
        print('❌ 分类 $categoryId 的第$page页返回空列表，确认没有更多数据');
        
        // 如果是第一页且缓存不存在，初始化为空列表
        if (page == 1 && !_categoryVideosMap.containsKey(categoryId)) {
          _categoryVideosMap[categoryId] = [];
        }
      } else {
        // 有数据时仍然允许加载更多
        _categoryHasMore[categoryId] = true;
        // 更新当前页码
        _categoryCurrentPage[categoryId] = page;
        print('✅ 分类 $categoryId 返回了 ${videos.length} 个视频，还可继续加载更多');
        
        // 如果是第一页且是强制刷新，替换缓存
        if (page == 1 && forceRefresh) {
          _categoryVideosMap[categoryId] = videos;
        } 
        // 如果是第一页但非强制刷新，且缓存为空，则直接设置
        else if (page == 1 && !_categoryVideosMap.containsKey(categoryId)) {
          _categoryVideosMap[categoryId] = videos;
        }
        // 如果是加载更多，追加到现有缓存
        else if (page > 1) {
          // 确保缓存存在
          if (!_categoryVideosMap.containsKey(categoryId)) {
            _categoryVideosMap[categoryId] = [];
          }
          
          // 去重添加
          final existingIds = _categoryVideosMap[categoryId]!.map((v) => v.id).toSet();
          final newVideos = videos.where((v) => !existingIds.contains(v.id)).toList();
          
          // 检查是否有新的不重复视频
          if (newVideos.isEmpty) {
            // 没有新的不重复视频，递增空页计数
            if (_consecutiveEmptyPages.containsKey(categoryId)) {
              _consecutiveEmptyPages[categoryId] = (_consecutiveEmptyPages[categoryId] ?? 0) + 1;
            } else {
              _consecutiveEmptyPages[categoryId] = 1;
            }
            
            print('⚠️ 警告：第$page页没有新的不重复视频，目前已连续${_consecutiveEmptyPages[categoryId]}页无新内容');
            
            // 如果连续2页都没有新视频，则判断没有更多数据
            if ((_consecutiveEmptyPages[categoryId] ?? 0) >= 2) {
              _categoryHasMore[categoryId] = false;
              _categoryNoMoreData[categoryId] = true;
              print('❌ 连续${_consecutiveEmptyPages[categoryId]}页都没有新视频，标记为没有更多数据');
            }
          } else {
            // 有新视频，重置连续空页计数
            _consecutiveEmptyPages[categoryId] = 0;
            
            _categoryVideosMap[categoryId]!.addAll(newVideos);
            print('✅ 成功追加了 ${newVideos.length} 个新视频到分类 $categoryId，当前总数: ${_categoryVideosMap[categoryId]!.length}');
          }
        }
      }
      
      // 确保该分类有一个缓存项，即使是空列表
      if (!_categoryVideosMap.containsKey(categoryId)) {
        _categoryVideosMap[categoryId] = [];
      }
      
      // 返回结果
      return _categoryVideosMap[categoryId]!;
    } catch (e) {
      print('❌ 加载分类 $categoryId 的视频失败: $e');
      // 如果加载失败，尝试返回已缓存的视频（如果有）
      if (_categoryVideosMap.containsKey(categoryId)) {
        return _categoryVideosMap[categoryId]!;
      }
      // 如果没有缓存，返回空列表并更新缓存
      _categoryVideosMap[categoryId] = [];
      // 标记为没有更多数据（加载失败时）
      _categoryNoMoreData[categoryId] = true;
      return []; // 如果没有缓存，返回空列表
    } finally {
      // 如果是加载更多，重置加载更多状态
      if (page > 1) {
        setLoadingMore(false);
      }
    }
  }
  
  // 根据分类名称加载视频
  Future<List<Video>> loadVideosByCategory(String category, {int page = 1}) async {
    // 查找分类ID
    String categoryId = '0';
    if (category != '推荐') {
      final categoryObj = _categories.firstWhere(
        (item) => item.name == category,
        orElse: () => model.Category(id: '0', name: '推荐')
      );
      categoryId = categoryObj.id;
    }
    
    print('通过分类名称加载视频: $category, ID: $categoryId');
    return loadVideosByCategoryId(categoryId, forceRefresh: false, page: page);
  }
  
  // 搜索视频
  Future<void> searchVideos(String keyword) async {
    if (keyword.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    setLoading(true);
    try {
      _searchResults = await _apiService.searchVideos(keyword);
      notifyListeners();
    } catch (e) {
      print('搜索视频失败: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // 加载更多视频 (当前分类)
  Future<bool> loadMoreVideosForCurrentCategory() async {
    if (_currentCategoryId == null || _isLoading) return false;

    try {
      _isLoading = true;
      notifyListeners();

      // 获取当前分类的页码
      int currentPage = _categoryCurrentPage.containsKey(_currentCategoryId) ? 
          _categoryCurrentPage[_currentCategoryId]! : 1;
      int nextPage = currentPage + 1;
      
      print('加载分类[$_currentCategoryId]的第$nextPage页数据');
      
      final videos = await loadVideosByCategoryId(_currentCategoryId, page: nextPage);
      
      // 如果返回的视频列表为空，表示没有更多数据了
      if (videos.isEmpty) {
        print('分类[$_currentCategoryId]第$nextPage页没有数据，标记为没有更多数据');
        _categoryNoMoreData[_currentCategoryId] = true;
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // 更新页码
      _categoryCurrentPage[_currentCategoryId] = nextPage;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('加载更多数据失败: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // 判断当前分类是否有更多数据
  bool hasMoreVideosForCurrentCategory() {
    // 推荐分类不支持加载更多
    if (_currentCategoryId == '0') {
      return false;
    }
    
    // 检查该分类是否被标记为没有更多数据
    if (_categoryNoMoreData.containsKey(_currentCategoryId) && 
        _categoryNoMoreData[_currentCategoryId] == true) {
      print('分类[$_currentCategoryId]已标记为没有更多数据');
      return false;
    }
    
    return true;
  }
  
  // 更新当前播放列表 - 用于切换播放源
  Map<String, List<String>> updateCurrentPlaylist(Video video, int sourceIndex) {
    // 返回值包含两个键值对：'urls'和'notes'
    Map<String, List<String>> result = {
      'urls': [],
      'notes': []
    };
    
    if (video.playSources.isEmpty || sourceIndex >= video.playSources.length) {
      return result;
    }
    
    try {
      final playSource = video.playSources[sourceIndex];
      
      // 获取播放源对应的URL列表和选集名称列表
      List<String> currentPlayUrls = [];
      List<String> currentPlayNotes = [];
      
      // 根据API格式解析播放地址
      if (video.playUrl.isNotEmpty) {
        final List<String> sourceGroups = video.playUrl.split(r'$$$');
        
        // 判断是否有多个播放源
        if (sourceGroups.length > sourceIndex) {
          final String sourceUrlsStr = sourceGroups[sourceIndex];
          // 解析当前播放源的所有集的URL
          final List<String> episodeUrls = sourceUrlsStr.split('#')
              .where((url) => url.trim().isNotEmpty)
              .map((urlItem) {
                // 处理可能的"名称$地址"格式
                final parts = urlItem.split(r'$');
                // 如果包含"$"分隔符，取最后一部分作为URL
                return parts.length > 1 ? parts.last.trim() : urlItem.trim();
              }).toList();
          
          if (episodeUrls.isNotEmpty) {
            currentPlayUrls = episodeUrls;
          }
        }
      }
      
      // 如果未能从playUrl解析出地址（可能是旧格式），尝试使用playUrlList
      if (currentPlayUrls.isEmpty && video.playUrlList.isNotEmpty) {
        // 使用现有的playUrlList
        currentPlayUrls = video.playUrlList;
      }
      
      // 处理选集名称 - 使用API提供的数据或简单编号
      if (video.playNotes.isNotEmpty) {
        // 尝试按播放源拆分选集名称
        List<String> allNotes = video.playNotes;
        
        // 如果有足够的选集名称与URL匹配，则使用
        if (allNotes.length == currentPlayUrls.length) {
          currentPlayNotes = allNotes;
        } else {
          // 否则生成简单的数字编号
          currentPlayNotes = _generateSimpleEpisodeNames(currentPlayUrls.length);
        }
      } else {
        // 生成简单的数字编号作为选集名称
        currentPlayNotes = _generateSimpleEpisodeNames(currentPlayUrls.length);
      }
      
      // 设置返回值
      result['urls'] = currentPlayUrls;
      result['notes'] = currentPlayNotes;
      
      // 通知UI更新
      notifyListeners();
      
      return result;
    } catch (e) {
      return result;
    }
  }
  
  // 生成简单的选集编号
  List<String> _generateSimpleEpisodeNames(int count) {
    if (count <= 0) return [];
    
    if (count == 1) {
      return ['1'];
    }
    
    return List.generate(count, (index) => '${index + 1}');
  }
  
  // 获取指定分类ID的视频列表
  List<Video> getCategoryVideos(String categoryId) {
    // 如果是首页推荐，直接返回首页视频列表
    if (categoryId == '0') {
      return _homeVideos;
    }
    
    // 如果分类ID的视频已经加载过，直接从缓存返回
    if (_categoryVideosMap.containsKey(categoryId)) {
      return _categoryVideosMap[categoryId] ?? [];
    }
    
    // 未加载过该分类的视频，返回空列表
    return [];
  }
} 