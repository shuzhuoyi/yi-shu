import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../providers/user_provider.dart';
import '../constants/app_constants.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLoading = true;
  String _loadingText = "正在初始化...";
  double _progress = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    // 创建动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // 创建不透明度动画
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    // 创建缩放动画
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    // 启动动画
    _animationController.forward();
    
    // 延迟一小段时间再开始预加载数据，让用户能看到启动界面
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadAllData();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // 加载所有必要的数据
  Future<void> _loadAllData() async {
    try {
      final videoProvider = Provider.of<VideoProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // 步骤1: 初始化用户数据
      setState(() {
        _loadingText = "初始化中...";
        _progress = 0.1;
      });
      
      await userProvider.init();
      
      // 步骤2: 加载分类数据
      setState(() {
        _loadingText = "正在加载数据...";
        _progress = 0.2;
      });
      
      await videoProvider.loadCategories();
      
      // 步骤3: 加载首页视频
      setState(() {
        _loadingText = "正在加载数据...";
        _progress = 0.4;
      });
      
      await videoProvider.loadHomeVideos();
      
      // 步骤4: 预加载各分类的视频
      setState(() {
        _loadingText = "正在加载数据...";
        _progress = 0.6;
      });
      
      await videoProvider.preloadCategoryVideos();
      
      // 步骤5: 加载排行榜数据
      setState(() {
        _loadingText = "正在加载数据...";
        _progress = 0.8;
      });
      
      await videoProvider.loadRankVideos();
      
      // 完成加载
      setState(() {
        _loadingText = "初始化完成，即将进入...";
        _progress = 1.0;
        _isLoading = false;
      });
      
      // 延迟进入主界面
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        // 使用平滑过渡动画进入主界面
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = 0.0;
              const end = 1.0;
              const curve = Curves.easeInOut;
              
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var fadeAnimation = animation.drive(tween);
              
              return FadeTransition(
                opacity: fadeAnimation,
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      print('初始化数据加载失败: $e');
      setState(() {
        _loadingText = "加载失败，正在重试...";
        _progress = 0.0;
      });
      
      // 失败后延迟重试
      await Future.delayed(const Duration(seconds: 2));
      _loadAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 顶部空白
                const Spacer(flex: 2),
                
                // 应用Logo
                Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      children: [
                        // Logo图标
                        Image.asset(
                          'assets/images/Logo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 应用名称
                        Text(
                          AppConstants.appName,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // 应用标语
                        Text(
                          '十年磨一剑，只为更好的体验',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 底部加载状态
                const Spacer(flex: 1),
                
                // 加载进度条
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _loadingText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // 移除版权信息，留出空白
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
} 