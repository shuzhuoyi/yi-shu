import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_model.dart';
import '../providers/video_provider.dart';

/// HomeScreen 数据加载服务
class HomeLoaderService {
  final BuildContext context;
  
  // 存储各分类的视频，直接从API获取
  final Map<String, List<Video>> categoryVideosCache = {};
  // 存储轮播图数据
  List<Video> carouselVideos = [];
  bool isLoadingCategoryVideos = false;
  
  // 已加载的分类ID集合，用于避免重复加载
  final Set<String> loadedCategoryIds = {};
  bool initialDataLoaded = false;
  
  HomeLoaderService(this.context);
  
  VideoProvider get videoProvider => Provider.of<VideoProvider>(context, listen: false);
  
  // 初始化数据
  Future<void> initializeData({required Function(bool isLoading) updateLoadingState}) async {
    print('开始初始化数据...');
    
    // 创建临时缓存，不直接清空原有缓存
    final Map<String, List<Video>> tempCache = {};
    final Set<String> tempLoadedIds = {};
    bool tempInitialDataLoaded = false;
    
    updateLoadingState(true);
    
    try {
      // 检查VideoProvider中是否已经有数据
      final categories = videoProvider.categories;
      final categoryVideosMap = videoProvider.categoryVideosMap;
      
      if (categories.isNotEmpty && categoryVideosMap.isNotEmpty) {
        print('VideoProvider中已有数据，使用现有数据');
        
        // 使用已有数据更新缓存
        categoryVideosCache.clear();
        categoryVideosCache.addAll(categoryVideosMap);
        
        // 标记所有分类为已加载
        loadedCategoryIds.clear();
        for (final category in categories) {
          loadedCategoryIds.add(category.id);
        }
        
        // 标记初始化完成
        initialDataLoaded = true;
        print('成功使用现有数据初始化，共${categories.length}个分类');
        return;
      }
      
      // 1. 先强制加载分类列表
      print('强制重新加载分类列表');
        await videoProvider.loadCategories();
      
      final updatedCategories = videoProvider.categories;
      if (updatedCategories.isEmpty) {
        print('分类列表为空，无法加载视频内容');
        return;
      }
      
      // 输出已加载的分类
      print('已加载 ${updatedCategories.length} 个分类:');
      for (int i = 0; i < updatedCategories.length; i++) {
        print('  ${i+1}. ${updatedCategories[i].name} (ID: ${updatedCategories[i].id})');
      }
      
      // 创建并行加载任务列表
      List<Future<List<Video>>> loadTasks = [];
      List<String> categoryIds = [];
      List<String> categoryNames = [];
      
      // 2. 为每个分类创建加载任务（不限制固定数量）
      for (int i = 0; i < updatedCategories.length; i++) {
        final categoryId = updatedCategories[i].id;
        final categoryName = updatedCategories[i].name;
        
        // 添加到任务列表
        print('准备加载分类[$categoryName]的视频');
        categoryIds.add(categoryId);
        categoryNames.add(categoryName);
        loadTasks.add(videoProvider.loadVideosByCategoryId(categoryId, forceRefresh: true));
      }
      
      // 3. 并行执行所有加载任务
      print('开始并行加载所有分类视频');
      final results = await Future.wait(loadTasks);
      
      // 4. 处理加载结果
      for (int i = 0; i < results.length; i++) {
        final videos = results[i];
        final categoryId = categoryIds[i];
        final categoryName = categoryNames[i];
        
        // 即使视频列表为空，也保存到临时缓存中
        tempCache[categoryId] = videos;
        // 标记该分类已加载
        tempLoadedIds.add(categoryId);
        print('成功加载分类[$categoryName]的${videos.length}个视频');
      }
      
      print('所有分类视频加载完成');
      
      // 加载成功后，才更新真正的缓存
      categoryVideosCache.clear();
      categoryVideosCache.addAll(tempCache);
      
      loadedCategoryIds.clear();
      loadedCategoryIds.addAll(tempLoadedIds);
      
      // 标记初始化完成
      initialDataLoaded = true;
      
    } catch (e) {
      print('初始化数据失败: $e');
      // 失败时不清空现有数据
    } finally {
      updateLoadingState(false);
      print('数据初始化完成');
    }
  }
  
  // 加载指定分类的视频
  Future<void> loadCategoryVideos(String categoryId, {Function(bool)? updateLoadingState}) async {
    if (loadedCategoryIds.contains(categoryId)) {
      print('分类[$categoryId]视频已加载，无需重复加载');
      return;
    }
    
    // 正在加载中，避免重复请求
    if (isLoadingCategoryVideos) {
      print('正在加载其他分类视频，请稍后再试');
      return;
    }
    
    try {
      isLoadingCategoryVideos = true;
      if (updateLoadingState != null) {
        updateLoadingState(true);
      }
      
      // 先检查Provider中是否已有该分类数据
      final existingVideos = videoProvider.getCategoryVideos(categoryId);
      if (existingVideos.isNotEmpty) {
        print('Provider中已有分类[$categoryId]数据，直接使用');
        categoryVideosCache[categoryId] = existingVideos;
        loadedCategoryIds.add(categoryId);
        return;
      }

      // 重新加载该分类的视频数据
      final videos = await videoProvider.loadVideosByCategoryId(categoryId);
      
      // 更新缓存
      categoryVideosCache[categoryId] = videos;
      // 标记该分类已加载
      loadedCategoryIds.add(categoryId);
      
      print('成功加载分类[$categoryId]的${videos.length}个视频');
      
    } catch (e) {
      print('加载分类[$categoryId]视频失败: $e');
    } finally {
      isLoadingCategoryVideos = false;
      if (updateLoadingState != null) {
      updateLoadingState(false);
      }
    }
  }
  
  // 加载更多视频
  Future<void> loadMoreVideos(String currentCategoryId, {
    required Function(List<Video>) updateCategoryCache,
    required Function() onNoMoreData,
    required Function(String) onLoadFailed
  }) async {
    // 如果是推荐分类，不支持加载更多
    if (currentCategoryId == '0') {
      print('推荐分类不支持加载更多');
      return;
    }
    
    // 检查是否还有更多数据
    if (!videoProvider.hasMoreVideosForCurrentCategory()) {
      print('❌ 没有更多数据了');
      onNoMoreData();
      return;
    }
    
    // 如果当前正在加载，避免重复加载
    if (videoProvider.isLoading || videoProvider.isLoadingMore) {
      print('⚠️ 当前已在加载中，跳过重复加载');
      return;
    }
    
    try {
      // 获取当前缓存视频数量
      final oldCount = categoryVideosCache.containsKey(currentCategoryId) ? 
          categoryVideosCache[currentCategoryId]!.length : 0;
      print('加载前缓存视频数量: $oldCount');
      
      // 加载更多数据
      print('开始加载更多分类[$currentCategoryId]的视频...');
      final success = await videoProvider.loadMoreVideosForCurrentCategory();
      
      if (success) {
        // 获取最新的视频列表
        final latestVideos = videoProvider.categoryVideosMap[currentCategoryId]!;
        
        // 更新本地缓存
        categoryVideosCache[currentCategoryId] = latestVideos;
        updateCategoryCache(latestVideos);
        
        // 计算新增视频数量
        final newCount = latestVideos.length;
        final addedCount = newCount - oldCount;
        
        print('✅ 加载成功！视频总数: $newCount，本次新增: $addedCount');
        
        // 再次检查是否还有更多数据
        if (!videoProvider.hasMoreVideosForCurrentCategory()) {
          print('❌ 加载完成后确认没有更多数据了');
          onNoMoreData();
          return;
        }
      } else {
        print('❌ 加载更多失败，显示没有更多数据');
        onNoMoreData();
        return;
      }
    } catch (e) {
      print('❌ 加载更多失败: $e');
      onLoadFailed(e.toString());
    }
  }
} 