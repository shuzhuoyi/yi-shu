import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class ShareAppScreen extends StatefulWidget {
  const ShareAppScreen({super.key});

  @override
  State<ShareAppScreen> createState() => _ShareAppScreenState();
}

class _ShareAppScreenState extends State<ShareAppScreen> {
  final String _appDownloadLink = 'https://example.com/download/iaapp';
  bool _linkCopied = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分享APP'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildAppLogo(),
              const SizedBox(height: 50),
              _buildShareChannels(),
              const SizedBox(height: 50),
              _buildShareLink(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.movie,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          '影视APP',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '在线高清影视资源，随时畅快观看',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildShareChannels() {
    return Column(
      children: [
        const Text(
          '分享到',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildShareItem('微信', Icons.wechat, Colors.green),
            _buildShareItem('QQ', Icons.message, Colors.blue),
            _buildShareItem('微博', Icons.wifi_tethering, Colors.red),
            _buildShareItem('更多', Icons.more_horiz, Colors.orange),
          ],
        ),
      ],
    );
  }
  
  Widget _buildShareItem(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享到$title'),
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
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShareLink() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _appDownloadLink,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _copyLinkToClipboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _linkCopied ? Colors.grey : AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  minimumSize: const Size(70, 36),
                ),
                child: Text(_linkCopied ? '已复制' : '复制'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          '复制链接分享给好友，邀请更多人一起使用影视App',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  void _copyLinkToClipboard() {
    Clipboard.setData(ClipboardData(text: _appDownloadLink));
    setState(() {
      _linkCopied = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('链接已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // 2秒后重置按钮状态
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _linkCopied = false;
        });
      }
    });
  }
} 