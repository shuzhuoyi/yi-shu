import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/video_model.dart';
import '../models/category_model.dart' as model;

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  
  // 获取视频列表
  Future<List<Video>> getVideoList({String category = '', int page = 1, int pageSize = 20, bool forceRefresh = false}) async {
    try {
      print('获取视频列表: 分类ID=$category, 页码=$page, 每页数量=$pageSize, 强制刷新=$forceRefresh');
      
      // 添加时间戳参数，确保请求不会被缓存
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final response = await _dio.get(
        ApiConstants.movieDetail, // 使用详情接口获取视频
        queryParameters: {
          'ac': 'detail',
          't': category, // 这里使用的是分类ID
          'pg': page,
          'limit': pageSize,
          '_t': timestamp, // 添加时间戳防止缓存
        },
      );
      
      if (response.statusCode == 200) {
        // 打印响应以便调试
        print('视频详情API响应状态码: ${response.statusCode}');
        
        // 解析API返回的数据
        Map<String, dynamic> responseData;
        
        // 处理响应数据：可能是字符串或Map
        if (response.data is String) {
          try {
            // 如果是字符串，尝试解析成JSON
            print('API返回的是字符串格式数据，尝试解析JSON...');
            responseData = json.decode(response.data as String);
          } catch (e) {
            print('JSON字符串解析失败: $e');
            return [];
          }
        } else if (response.data is Map) {
          // 如果已经是Map，直接使用
          responseData = response.data as Map<String, dynamic>;
        } else {
          print('API响应格式不支持: ${response.data.runtimeType}');
          return [];
        }
        
        // 打印响应中的顶级键
        print('API响应键: ${responseData.keys.toList()}');
        
        // 尝试获取列表数据
        List<dynamic> videoList = [];
        
        if (responseData.containsKey('list') && responseData['list'] is List) {
          videoList = responseData['list'] as List;
          print('找到视频列表，包含 ${videoList.length} 个项目');
          
          // 打印第一个视频数据
          if (videoList.isNotEmpty) {
            final firstVideo = videoList.first;
            print('第一个视频数据: $firstVideo');
            
            // 打印详情数据中的所有字段，特别关注封面图字段
            if (firstVideo is Map) {
              print('详情API中的封面图字段:');
              // 检查所有可能的封面图字段
              List<String> possibleCoverFields = ['vod_pic', 'pic', 'cover', 'image', 'img', 'thumb'];
              for (var field in possibleCoverFields) {
                if (firstVideo.containsKey(field)) {
                  print('- $field: ${firstVideo[field]}');
                }
              }
            }
          }
        } else {
          print('API响应中没有找到list字段或list不是数组');
        }
        
        // 转换为Video对象列表
        final videos = videoList.map<Video>((json) {
          try {
            return Video.fromJson(json);
          } catch (e) {
            print('解析单个视频失败: $e');
            return Video(
              id: 'error',
              title: '解析错误',
              cover: '',
              category: '未知'
            );
          }
        }).toList();
        
        print('成功解析 ${videos.length} 个视频数据');
        return videos;
      }
      
      print('视频列表API请求失败: ${response.statusCode}');
      return [];
    } catch (e) {
      print('获取视频列表失败: $e');
      return [];
    }
  }
  
  // 获取视频详情
  Future<Video?> getVideoDetail(String id) async {
    try {
      final response = await _dio.get(
        ApiConstants.movieDetail,
        queryParameters: {'ids': id},
      );
      
      if (response.statusCode == 200) {
        print('视频详情API响应状态码: ${response.statusCode}');
        
        // 解析API返回的数据
        Map<String, dynamic> responseData;
        
        // 处理响应数据：可能是字符串或Map
        if (response.data is String) {
          try {
            // 如果是字符串，尝试解析成JSON
            print('API返回的是字符串格式数据，尝试解析JSON...');
            responseData = json.decode(response.data as String);
          } catch (e) {
            print('视频详情JSON字符串解析失败: $e');
            return null;
          }
        } else if (response.data is Map) {
          // 如果已经是Map，直接使用
          responseData = response.data as Map<String, dynamic>;
        } else {
          print('视频详情API响应格式不支持: ${response.data.runtimeType}');
          return null;
        }
        
        // 尝试获取列表数据
        List<dynamic> videoList = [];
        
        if (responseData.containsKey('list') && responseData['list'] is List) {
          videoList = responseData['list'] as List;
          print('找到视频详情，列表包含 ${videoList.length} 个项目');
        } else {
          print('视频详情API响应中没有找到list字段或list不是数组');
        }
        
        if (videoList.isNotEmpty) {
          try {
            return Video.fromJson(videoList[0]);
          } catch (e) {
            print('解析视频详情失败: $e');
          }
        }
      }
      return null;
    } catch (e) {
      print('获取视频详情失败: $e');
      return null;
    }
  }
  
  // 搜索视频
  Future<List<Video>> searchVideos(String keyword, {int page = 1, int pageSize = 20}) async {
    try {
      if (keyword.isEmpty) return [];
      
      final response = await _dio.get(
        ApiConstants.movieSearch,
        queryParameters: {
          'wd': keyword,
          'pg': page,
          'limit': pageSize,
        },
      );
      
      if (response.statusCode == 200) {
        print('搜索API响应状态码: ${response.statusCode}');
        
        // 解析API返回的数据
        Map<String, dynamic> responseData;
        
        // 处理响应数据：可能是字符串或Map
        if (response.data is String) {
          try {
            // 如果是字符串，尝试解析成JSON
            print('API返回的是字符串格式数据，尝试解析JSON...');
            responseData = json.decode(response.data as String);
          } catch (e) {
            print('搜索结果JSON字符串解析失败: $e');
            return [];
          }
        } else if (response.data is Map) {
          // 如果已经是Map，直接使用
          responseData = response.data as Map<String, dynamic>;
        } else {
          print('搜索API响应格式不支持: ${response.data.runtimeType}');
          return [];
        }
        
        // 尝试获取列表数据
        List<dynamic> videoList = [];
        
        if (responseData.containsKey('list') && responseData['list'] is List) {
          videoList = responseData['list'] as List;
          print('找到搜索结果，包含 ${videoList.length} 个视频');
        } else {
          print('搜索API响应中没有找到list字段或list不是数组');
        }
        
        // 转换为Video对象列表
        final videos = videoList.map<Video>((json) {
          try {
            return Video.fromJson(json);
          } catch (e) {
            print('解析搜索结果失败: $e');
            return Video(
              id: 'error',
              title: '解析错误',
              cover: '',
              category: '未知'
            );
          }
        }).toList();
        
        print('成功解析 ${videos.length} 个搜索结果');
        return videos;
      }
      return [];
    } catch (e) {
      print('搜索视频失败: $e');
      return [];
    }
  }
  
  // 获取分类列表
  Future<List<model.Category>> getNewCategoryList() async {
    try {
      print('开始请求分类列表 API: ${ApiConstants.categoryList}');
      
      // 设置超时时间
      final options = Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      );
      
      final response = await _dio.get(
        ApiConstants.categoryList,
        options: options,
      );
      
      print('分类列表 API 请求完成，状态码: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // 解析API返回的数据
        Map<String, dynamic> responseData;
        
        // 详细记录原始响应数据类型和部分内容
        final responseType = response.data.runtimeType;
        print('分类列表 API 响应数据类型: $responseType');
        
        // 处理响应数据：可能是字符串或Map
        if (response.data is String) {
          try {
            // 如果是字符串，尝试解析成JSON
            print('分类列表 API 返回字符串数据，尝试解析为 JSON...');
            responseData = json.decode(response.data as String);
            print('成功将字符串解析为 JSON 数据');
          } catch (e) {
            print('分类列表 JSON 字符串解析失败: $e');
            return [model.Category(id: '0', name: '推荐')];
          }
        } else if (response.data is Map) {
          // 如果已经是Map，直接使用
          responseData = response.data as Map<String, dynamic>;
          print('分类列表 API 直接返回 Map 数据');
        } else {
          print('分类列表 API 响应格式不支持: $responseType');
          return [model.Category(id: '0', name: '推荐')];
        }
        
        // 打印响应数据的顶层键，帮助调试
        print('分类列表 API 响应顶层键: ${responseData.keys.toList()}');
        
        // 尝试获取分类数据
        List<dynamic> categoryList = [];
        String foundPath = '无法找到分类数据';
        
        // 用于跟踪尝试的路径
        final attemptedPaths = <String>[];
        
        // 检查关键路径: info.rows
        if (responseData.containsKey('info') && responseData['info'] is Map) {
          attemptedPaths.add('info.rows');
          final info = responseData['info'] as Map<String, dynamic>;
          
          if (info.containsKey('rows') && info['rows'] is List) {
            categoryList = info['rows'] as List;
            foundPath = 'info.rows';
            print('在 info.rows 中找到 ${categoryList.length} 个分类');
          }
        }
        
        // 其他路径检查
        final additionalPaths = [
          {'path': 'list', 'label': 'list'},
          {'path': 'data', 'isArray': true, 'label': 'data列表'},
          {'path': 'data.list', 'nestedMap': 'data', 'nestedKey': 'list', 'label': 'data.list'},
          {'path': 'class', 'label': 'class'},
          {'path': 'categories', 'label': 'categories'},
          {'path': 'types', 'label': 'types'},
          {'path': 'data.types', 'nestedMap': 'data', 'nestedKey': 'types', 'label': 'data.types'},
        ];
        
        // 尝试每个路径，直到找到分类列表
        for (final pathInfo in additionalPaths) {
          if (categoryList.isNotEmpty) break;
          
          final path = pathInfo['path'] as String;
          attemptedPaths.add(path);
          
          if (pathInfo.containsKey('nestedMap') && pathInfo.containsKey('nestedKey')) {
            // 处理嵌套路径，如 data.list
            final outerKey = pathInfo['nestedMap'] as String;
            final innerKey = pathInfo['nestedKey'] as String;
            
            if (responseData.containsKey(outerKey) && responseData[outerKey] is Map) {
              final nestedMap = responseData[outerKey] as Map<String, dynamic>;
              if (nestedMap.containsKey(innerKey) && nestedMap[innerKey] is List) {
                categoryList = nestedMap[innerKey] as List;
                foundPath = path;
                print('在 $path 中找到 ${categoryList.length} 个分类');
              }
            }
          } else if (pathInfo.containsKey('isArray') && pathInfo['isArray'] == true) {
            // 直接检查是否为数组
            final key = path;
            if (responseData.containsKey(key) && responseData[key] is List) {
              categoryList = responseData[key] as List;
              foundPath = key;
              print('在 $key 中找到 ${categoryList.length} 个分类');
            }
          } else {
            // 普通键值检查
            final key = path;
            if (responseData.containsKey(key) && responseData[key] is List) {
              categoryList = responseData[key] as List;
              foundPath = key;
              print('在 $key 中找到 ${categoryList.length} 个分类');
            }
          }
        }
        
        if (categoryList.isEmpty) {
          print('尝试了以下路径但未找到分类数据: ${attemptedPaths.join(", ")}');
          return [model.Category(id: '0', name: '推荐')];
        }
        
        print('成功在 $foundPath 路径中找到 ${categoryList.length} 个分类');
        
        // 创建两个列表：主分类和子分类
        List<model.Category> mainCategories = [];
        List<model.Category> subCategories = [];
        
        // 添加"推荐"分类
        mainCategories.add(model.Category(id: '0', name: '推荐'));
        
        // 解析分类数据
        int successCount = 0;
        int errorCount = 0;
        
        for (var item in categoryList) {
          try {
            if (item is Map<String, dynamic>) {
              // 尝试多种可能的键名
              String? id;
              if (item.containsKey('type_id')) id = item['type_id']?.toString();
              else if (item.containsKey('id')) id = item['id']?.toString();
              else if (item.containsKey('category_id')) id = item['category_id']?.toString();
              
              String? name;
              if (item.containsKey('type_name')) name = item['type_name'];
              else if (item.containsKey('name')) name = item['name'];
              else if (item.containsKey('title')) name = item['title'];
              else if (item.containsKey('category_name')) name = item['category_name'];
              
              if (id != null && id.isNotEmpty && name != null && name.isNotEmpty) {
                mainCategories.add(model.Category(id: id, name: name));
                successCount++;
                
                // 检查是否有子分类
                if (item.containsKey('child') && item['child'] is List) {
                  final childList = item['child'] as List;
                  
                  // 添加子分类到子分类列表
                  for (var child in childList) {
                    try {
                      if (child is Map<String, dynamic>) {
                        String? childId;
                        if (child.containsKey('type_id')) childId = child['type_id']?.toString();
                        else if (child.containsKey('id')) childId = child['id']?.toString();
                        
                        String? childName;
                        if (child.containsKey('type_name')) childName = child['type_name'];
                        else if (child.containsKey('name')) childName = child['name'];
                        
                        if (childId != null && childId.isNotEmpty && 
                            childName != null && childName.isNotEmpty) {
                          subCategories.add(model.Category(id: childId, name: childName));
                          successCount++;
                        }
                      }
                    } catch (e) {
                      errorCount++;
                      print('解析子分类出错: $e');
                    }
                  }
                }
              } else {
                errorCount++;
              }
            } else {
              errorCount++;
            }
          } catch (e) {
            errorCount++;
            print('解析分类项出错: $e');
          }
        }
        
        print('分类解析结果: 成功 $successCount 个, 失败 $errorCount 个');
        
        // 对主分类按ID排序（确保正确的ID顺序）
        mainCategories.sort((a, b) {
          // "推荐"类别始终排在第一位
          if (a.id == '0') return -1;
          if (b.id == '0') return 1;
          
          // 尝试将ID转换为整数进行比较
          try {
            // 提取纯数字部分
            int aId = int.parse(a.id.replaceAll(RegExp(r'[^0-9]'), ''));
            int bId = int.parse(b.id.replaceAll(RegExp(r'[^0-9]'), ''));
            
            // 返回从小到大排序的结果
            return aId.compareTo(bId);
          } catch (e) {
            // 如果无法解析为整数，则按字符串比较
            return a.id.compareTo(b.id);
          }
        });
        
        // 合并主分类和子分类，确保主分类优先显示
        List<model.Category> allCategories = [...mainCategories, ...subCategories];
        
        // 打印最终分类列表（仅用于调试）
        print('最终分类列表 (${allCategories.length} 个):');
        for (int i = 0; i < allCategories.length && i < 10; i++) {
          print('  ${i+1}. ${allCategories[i].name} (ID: ${allCategories[i].id})');
        }
        if (allCategories.length > 10) {
          print('  ... 及其他 ${allCategories.length - 10} 个分类');
        }
        
        return allCategories;
      }
      
      print('分类列表 API 请求失败，状态码: ${response.statusCode}');
      return [model.Category(id: '0', name: '推荐')];
    } catch (e) {
      print('获取分类列表失败，错误详情: $e');
      // 只返回推荐分类，不再硬编码其他分类
      return [model.Category(id: '0', name: '推荐')];
    }
  }
  
  // 获取视频解析配置
  Future<Map<String, dynamic>?> getVideoParsingConfig(String url) async {
    try {
      print('开始获取视频解析配置，原始URL: $url');
      
      // 获取所有解析器配置
      final configResponse = await _dio.get(
        ApiConstants.videoParsingConfig,
      );
      
      if (configResponse.statusCode != 200) {
        print('视频解析配置API响应失败: ${configResponse.statusCode}');
        return null;
      }
      
      // 解析API返回的数据
      Map<String, dynamic> configData;
      if (configResponse.data is String) {
        try {
          configData = json.decode(configResponse.data as String);
        } catch (e) {
          print('解析配置JSON解析失败: $e');
          return null;
        }
      } else if (configResponse.data is Map) {
        configData = configResponse.data as Map<String, dynamic>;
      } else {
        print('解析配置API响应格式不支持: ${configResponse.data.runtimeType}');
        return null;
      }
      
      if (configData['status'] != 0 || !configData.containsKey('data') || !(configData['data'] is List)) {
        print('解析配置数据格式错误或状态非成功');
        return null;
      }
      
      // 视频URL转小写，便于匹配
      final lowerUrl = url.toLowerCase();
      
      // 从配置中获取解析接口URL
      List<dynamic> parsers = configData['data'];
      if (parsers.isEmpty) {
        print('没有可用的解析接口');
        return null;
      }
      
      // 遍历所有解析器配置，查找适合当前URL的解析器
      Map<String, dynamic>? selectedParser;
      for (var parser in parsers) {
        if (parser is Map && 
            parser.containsKey('state') && 
            parser['state'] == true &&
            parser.containsKey('key') && 
            parser.containsKey('name')) {
          
          final String key = parser['key'].toString().toLowerCase();
          
          // 检查URL是否包含当前解析器的关键字
          if (lowerUrl.contains(key)) {
            print('URL包含解析器关键字: $key，选择解析器: ${parser['name']}');
            selectedParser = parser as Map<String, dynamic>;
            break;
          }
        }
      }
      
      // 如果没有找到匹配的解析器，使用第一个启用的解析器
      if (selectedParser == null) {
        for (var parser in parsers) {
          if (parser is Map && 
              parser.containsKey('state') && 
              parser['state'] == true) {
            print('使用默认解析器: ${parser['name']}');
            selectedParser = parser as Map<String, dynamic>;
            break;
          }
        }
      }
      
      // 如果仍未找到可用解析器，返回错误
      if (selectedParser == null) {
        print('未找到可用的解析器配置');
        return null;
      }
      
      // 获取解析器配置
      if (!selectedParser.containsKey('config') || 
          !(selectedParser['config'] is List) || 
          selectedParser['config'].isEmpty) {
        print('解析器配置无效: ${selectedParser['name']}');
        return null;
      }
      
      final config = selectedParser['config'][0];
      if (!(config is Map) || !config.containsKey('url')) {
        print('解析器URL配置无效: ${selectedParser['name']}');
        return null;
      }
      
      // 获取解析URL
      final String parseUrl = config['url'].toString().replaceAll(r'\\/', '/');
      print('使用解析器: ${selectedParser['name']}, URL: $parseUrl');
      
      // 调用解析接口获取真实播放地址
      print('调用解析接口: $parseUrl$url');
      final parseResponse = await _dio.get('$parseUrl$url');
      
      if (parseResponse.statusCode != 200) {
        print('视频解析API响应失败: ${parseResponse.statusCode}');
        return null;
      }
      
      // 解析响应数据
      Map<String, dynamic> parsedData;
      if (parseResponse.data is String) {
        try {
          parsedData = json.decode(parseResponse.data as String);
        } catch (e) {
          print('解析结果JSON解析失败: $e');
          return null;
        }
      } else if (parseResponse.data is Map) {
        parsedData = parseResponse.data as Map<String, dynamic>;
      } else {
        print('解析结果API响应格式不支持: ${parseResponse.data.runtimeType}');
        return null;
      }
      
      // 检查解析结果
      if (parsedData.containsKey('url') && 
          parsedData['url'] is String && 
          parsedData['url'].toString().isNotEmpty) {
        
        final realUrl = parsedData['url'].toString();
        print('成功解析到真实播放地址: $realUrl');
        
        // 构造统一格式的返回数据
        return {
          'code': 200,
          'msg': 'ok',
          'data': {
            'url': realUrl,
            'headers': parsedData.containsKey('header') ? parsedData['header'] : {},
            'original_url': url,
            'parser_name': selectedParser['name'],
          }
        };
      } else {
        print('解析结果中未找到有效的url字段');
        return null;
      }
    } catch (e) {
      print('获取视频解析配置失败: $e');
      return null;
    }
  }
}
  
