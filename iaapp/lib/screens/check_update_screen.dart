import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/app_constants.dart';

class CheckUpdateScreen extends StatefulWidget {
  const CheckUpdateScreen({super.key});

  @override
  State<CheckUpdateScreen> createState() => _CheckUpdateScreenState();
}

class _CheckUpdateScreenState extends State<CheckUpdateScreen> {
  final String _currentVersion = '1.0.0';
  final String _buildNumber = '202304001';
  final String _updateDate = '2023-04-01';
  
  bool _isChecking = false;
  bool _hasUpdate = false;
  String _latestVersion = '';
  String _updateDescription = '';
  double _updateSize = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('检查更新'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 当前版本信息
          _buildCurrentVersionSection(),
          
          const Divider(height: 0.5),
          
          // 检查更新按钮
          _buildCheckUpdateSection(),
          
          // 更新内容区域
          if (_hasUpdate) _buildUpdateInfoSection(),
          
          const Spacer(),
          
          // 底部文字
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '已是最新版本',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCurrentVersionSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // 应用图标
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.movie,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 15),
          
          // 版本信息
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '影视APP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '当前版本：$_currentVersion',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '更新日期：$_updateDate',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCheckUpdateSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: ElevatedButton(
        onPressed: _isChecking ? null : _checkForUpdates,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isChecking
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('检查中...'),
                ],
              )
            : const Text('检查更新'),
      ),
    );
  }
  
  Widget _buildUpdateInfoSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '发现新版本 $_latestVersion',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_updateSize}MB',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '更新内容',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _updateDescription,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('立即更新'),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _checkForUpdates() async {
    // 模拟网络请求
    setState(() {
      _isChecking = true;
    });
    
    // 延迟2秒模拟网络请求
    await Future.delayed(const Duration(seconds: 2));
    
    // 模拟有更新的情况
    setState(() {
      _isChecking = false;
      _hasUpdate = true;
      _latestVersion = '1.1.0';
      _updateSize = 15.8;
      _updateDescription = '1. 修复了部分视频无法播放的问题\n'
          '2. 优化了首页加载速度，提升了用户体验\n'
          '3. 新增了收藏功能，更方便管理喜欢的视频\n'
          '4. 调整了界面布局，使用更加便捷\n'
          '5. 修复了其他已知问题';
    });
    
    // 显示操作成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('发现新版本，请及时更新'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _startUpdate() {
    // 模拟开始更新
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开始更新'),
        content: const Text('是否下载并安装新版本？下载过程中请保持网络连接。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDownloadingDialog();
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
  
  void _showDownloadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // 模拟下载进度
            double progress = 0.0;
            
            // 启动定时器更新进度
            Timer.periodic(const Duration(milliseconds: 100), (timer) {
              if (progress < 1.0) {
                setState(() {
                  progress += 0.01;
                });
              } else {
                timer.cancel();
                Navigator.of(context).pop();
                // 下载完成后显示安装确认
                _showInstallDialog();
              }
            });
            
            return AlertDialog(
              title: const Text('正在下载更新'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 16),
                  Text('已下载 ${(progress * 100).toInt()}%'),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  void _showInstallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('下载完成'),
        content: const Text('新版本已下载完成，是否立即安装？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍后安装'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('正在安装新版本...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('立即安装'),
          ),
        ],
      ),
    );
  }
} 