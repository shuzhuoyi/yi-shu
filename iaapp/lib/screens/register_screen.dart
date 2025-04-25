import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'user_agreement_screen.dart';
import 'privacy_policy_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _register() async {
    // 检查输入是否为空
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写所有字段'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    
    // 检查是否同意用户协议和隐私政策
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请阅读并同意用户协议和隐私政策'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    
    // 检查密码是否匹配
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('两次输入的密码不一致'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 使用Dio直接调用注册接口，使用API常量
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      
      // 简单的用户名检查 - 长度和字符
      String username = _usernameController.text.trim();
      if (username.length < 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('用户名长度不能少于3个字符'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        return;
      }
      
      final RegExp validUsernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
      if (!validUsernameRegex.hasMatch(username)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('用户名只能包含字母、数字和下划线'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        return;
      }
      
      print('开始准备注册请求...');
      
      // 准备注册参数 - 使用API要求的参数
      Map<String, dynamic> registerData = {
        'user_name': username,
        'user_pwd': _passwordController.text,
        'user_pwd2': _passwordController.text, // 确认密码字段
      };
      
      print('注册请求参数: $registerData');
      
      // 创建FormData对象用于提交表单
      FormData formData = FormData.fromMap(registerData);
      
      // 实现真实注册API调用
      final String registerUrl = ApiConstants.userRegister;
      print('开始调用注册API: $registerUrl');
      
      final registerResponse = await dio.post(
        registerUrl,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );
      
      print('注册API响应: ${registerResponse.statusCode}');
      print('注册API响应数据: ${registerResponse.data}');
      
      if (registerResponse.statusCode == 200) {
        // 解析API返回的数据
        Map<String, dynamic> responseData;
        
        // 处理响应数据：可能是字符串或Map
        if (registerResponse.data is String) {
          try {
            responseData = json.decode(registerResponse.data as String);
          } catch (e) {
            print('注册响应JSON解析失败: $e');
            throw Exception('注册响应JSON解析失败');
          }
        } else if (registerResponse.data is Map) {
          responseData = registerResponse.data as Map<String, dynamic>;
        } else {
          print('注册API响应格式不支持: ${registerResponse.data.runtimeType}');
          throw Exception('注册API响应格式不支持');
        }
        
        print('注册API响应键: ${responseData.keys.toList()}');
        
        // 检查是否注册成功 - 由于API未知，使用通用检查
        if (responseData.containsKey('code') && 
            (responseData['code'] == 200 || responseData['code'] == 1)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('注册成功，请登录'),
                duration: Duration(seconds: 1),
              ),
            );
          
            // 注册成功，返回登录页
            Navigator.pop(context);
          }
        } else {
          String msg = responseData['msg'] ?? '注册失败';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('注册失败: $msg'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('注册失败，服务器返回: ${registerResponse.statusCode}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      print('注册异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('注册出错: ${e.toString()}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          '注册账号',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // 用户名输入框
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: '用户名',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
              const SizedBox(height: 20),
              
              // 密码输入框
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '设置密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
              const SizedBox(height: 20),
              
              // 确认密码输入框
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: '确认密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
              const SizedBox(height: 15),
              
              // 添加用户协议和隐私政策勾选项
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                    activeColor: AppConstants.primaryColor,
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        children: [
                          const TextSpan(text: '我已阅读并同意'),
                          TextSpan(
                            text: '《用户协议》',
                            style: TextStyle(color: AppConstants.primaryColor),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const UserAgreementScreen()),
                                );
                              },
                          ),
                          const TextSpan(text: '和'),
                          TextSpan(
                            text: '《隐私政策》',
                            style: TextStyle(color: AppConstants.primaryColor),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              
              // 注册按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_isLoading) {
                      _register();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                    '注册',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialRegisterButton(IconData icon, String text) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$text功能即将上线'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
        ],
      ),
    );
  }
}