import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoggedIn = false;
  String _username = '';
  String _userId = '';
  Map<String, dynamic> _userData = {};
  bool _isLoading = false;
  
  // 存储用户信息的键名
  static const String userKey = 'user_data';
  
  // getter
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  String get userId => _userId;
  Map<String, dynamic> get userData => _userData;
  bool get isLoading => _isLoading;
  
  // 初始化，从本地存储加载用户状态
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 从SharedPreferences获取保存的用户数据
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(userKey);
      
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        _currentUser = User.fromJson(userData);
        _isLoggedIn = true;
        _username = _currentUser!.username;
        _userId = _currentUser!.id;
        _userData = _currentUser!.toJson();
      } else {
        _isLoggedIn = false;
        _username = '';
        _userId = '';
        _userData = {};
      }
    } catch (e) {
      print('加载用户数据失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 登录
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 实现真实API登录
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      
      // 调用登录API
      print('开始调用登录API: ${ApiConstants.userLogin}');
      
      final response = await dio.post(
        ApiConstants.userLogin,
        data: {
          'user_name': username,
          'user_pwd': password,
        },
        options: Options(
          // 确保能够接收cookie
          receiveTimeout: const Duration(seconds: 15),
          followRedirects: true,
          validateStatus: (status) {
            return status != null && status < 500;
          },
          responseType: ResponseType.json,
        ),
      );
      
      print('登录API响应: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // 解析API返回的数据
        Map<String, dynamic> responseData;
        
        // 处理响应数据：可能是字符串或Map
        if (response.data is String) {
          try {
            responseData = json.decode(response.data as String);
          } catch (e) {
            print('登录响应JSON解析失败: $e');
            return false;
          }
        } else if (response.data is Map) {
          responseData = response.data as Map<String, dynamic>;
        } else {
          print('登录API响应格式不支持: ${response.data.runtimeType}');
          return false;
        }
        
        print('登录API响应键: ${responseData.keys.toList()}');
        
        // 检查是否登录成功
        if (responseData.containsKey('code') && (responseData['code'] == 200 || responseData['code'] == 1)) {
          print('登录验证通过，检查Cookie');
          
          // 从响应头中获取cookie信息
          Map<String, String> cookieData = {};
          
          // 解析Set-Cookie头
          if (response.headers['set-cookie'] != null) {
            List<String> cookies = response.headers['set-cookie']!;
            for (String cookie in cookies) {
              print('处理Cookie: $cookie');
              // 解析每个cookie
              List<String> parts = cookie.split(';')[0].split('=');
              if (parts.length == 2) {
                String key = parts[0].trim();
                String value = parts[1].trim();
                cookieData[key] = value;
              }
            }
          }
          
          print('提取的Cookie数据: $cookieData');
          
          // 获取用户ID和用户名
          String userId = cookieData['user_id'] ?? '1';
          String actualUsername = cookieData['user_name'] ?? username;
          String userPortrait = cookieData['user_portrait'] ?? '/static_new/images/touxiang.png';
          
          // 对URL编码的数据进行解码
          if (userPortrait.contains('%')) {
            try {
              userPortrait = Uri.decodeComponent(userPortrait);
            } catch (e) {
              print('解码头像URL失败: $e');
            }
          }
          
          try {
            _currentUser = User.fromJson({
              'id': userId,
              'username': actualUsername,
              'email': '',
              'avatar': userPortrait,
              'is_premium': cookieData['group_id'] == '3', // 假设组ID 3是高级会员
              'last_login_time': DateTime.now().toString(),
            });
            
            _isLoggedIn = true;
            _username = actualUsername;
            _userId = userId;
            _userData = _currentUser!.toJson();
            
            // 保存用户数据到本地存储
            if (_currentUser != null) {
              await _saveUserToStorage(_currentUser!);
              print('用户数据已保存到本地存储');
            }
            
            notifyListeners();
            print('登录成功，用户名: $actualUsername');
            return true;
          } catch (e) {
            print('处理用户信息时出错: $e');
            return false;
          }
        } else {
          String msg = responseData['msg'] ?? '登录失败';
          print('登录失败: $msg');
          return false;
        }
      }
      
      return false;
    } catch (e) {
      print('登录异常: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 注销
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 实现真实API注销
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      
      // 如果已登录且有userId，则调用注销API
      if (_isLoggedIn && _userId.isNotEmpty) {
        // 注意：这里的注销API路径可能需要根据实际情况调整
        final logoutUrl = '/api.php/user/logout/';
        print('准备调用注销API: $logoutUrl');
        
        try {
          // 注销API一般需要用户ID或token信息
          await dio.post(
            logoutUrl,
            data: {
              'user_id': _userId,
            },
          );
        } catch (e) {
          // 注销失败不影响本地清除
          print('注销API调用失败: $e');
        }
      }
      
      // 清除本地存储的用户数据
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(userKey);
      
      // 清除用户数据
      _currentUser = null;
      _isLoggedIn = false;
      _username = '';
      _userId = '';
      _userData = {};
      
      notifyListeners();
    } catch (e) {
      print('注销失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 保存用户数据到本地存储
  Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(userKey, userJson);
    } catch (e) {
      print('保存用户数据失败: $e');
    }
  }

  // 获取用户列表
  Future<List<User>> getUserList({int page = 1, int limit = 20}) async {
    _isLoading = true;
    notifyListeners();
    
    List<User> userList = [];
    
    try {
      // 导入 dio 和 api_constants
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      
      // 使用API常量定义的URL
      final String url = ApiConstants.userGetList;
      
      print('开始获取用户列表: $url');
      
      // 发送请求
      final response = await dio.get(url, queryParameters: {
        'pg': page,
        'limit': limit,
      });
      
      if (response.statusCode == 200) {
        print('获取用户列表成功: 状态码 ${response.statusCode}');
        
        // 解析API返回的数据
        Map<String, dynamic> responseData;
        
        // 处理响应数据：可能是字符串或Map
        if (response.data is String) {
          try {
            responseData = json.decode(response.data as String);
          } catch (e) {
            print('用户列表JSON解析失败: $e');
            return [];
          }
        } else if (response.data is Map) {
          responseData = response.data as Map<String, dynamic>;
        } else {
          print('用户列表API响应格式不支持: ${response.data.runtimeType}');
          return [];
        }
        
        // 打印响应数据结构以便调试
        print('用户列表API响应键: ${responseData.keys.toList()}');
        
        // 解析用户列表
        if (responseData.containsKey('info') && responseData['info'] is Map) {
          var info = responseData['info'] as Map<String, dynamic>;
          if (info.containsKey('rows') && info['rows'] is List) {
            final rows = info['rows'] as List;
            print('找到用户列表，包含 ${rows.length} 个用户');
            
            userList = rows.map((item) {
              try {
                return User.fromJson({
                  'id': item['user_id']?.toString() ?? '',
                  'username': item['user_name'] ?? '',
                  'email': item['user_email'] ?? '',
                  'avatar': item['user_portrait'] ?? '/static_new/images/touxiang.png',
                  'last_login_time': item['user_reg_time'] != null 
                      ? DateTime.fromMillisecondsSinceEpoch(
                          (item['user_reg_time'] as int) * 1000).toString() 
                      : '',
                });
              } catch (e) {
                print('解析单个用户数据失败: $e');
                return User(
                  id: 'error',
                  username: '解析错误',
                  email: '',
                );
              }
            }).toList();
          } else {
            print('用户列表在info中未找到rows字段或rows不是数组');
          }
        } else {
          print('用户列表API响应中没有找到info字段或info不是Map');
          print('获取到 0 个用户');
        }
      } else {
        print('获取用户列表失败: 状态码 ${response.statusCode}');
      }
    } catch (e) {
      print('获取用户列表异常: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return userList;
  }
} 