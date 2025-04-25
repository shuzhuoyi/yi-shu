import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_model.dart';
import 'dart:async';
import 'dart:math';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class VideoPlayerWidget extends StatefulWidget {
  final Video video;
  final bool isPlaying;
  final VoidCallback onTogglePlaying;
  final VoidCallback onBack;

  const VideoPlayerWidget({
    Key? key,
    required this.video,
    required this.isPlaying,
    required this.onTogglePlaying,
    required this.onBack,
  }) : super(key: key);

  @override
  VideoPlayerWidgetState createState() => VideoPlayerWidgetState();
}

class VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _controlsVisible = true;
  double _progress = 0.0;
  bool _isFullScreen = false;
  double _brightness = 0.7; 
  double _volume = 0.8;
  bool _showBrightnessIndicator = false;
  bool _showVolumeIndicator = false;
  bool _isBuffering = false;
  bool _showCoverImage = true;
  bool _isLoadingVideo = true;
  String _currentTime = '00:00';
  String _totalTime = '00:00';
  
  Timer? _controlsTimer;
  VideoPlayerController? _videoController;
  final VolumeController _volumeController = VolumeController.instance;
  final ApiService _apiService = ApiService();

  bool _draggingBrightness = false;
  bool _draggingVolume = false;

  double _cumulativeBrightnessDelta = 0.0;
  double _cumulativeVolumeDelta = 0.0;
  double _lastUsableBrightness = 0.7;
  bool _useFallbackBrightness = false;

  // 添加一个重试标志
  bool _retried = false;

  // 新增取消标志和请求ID，用于防止并发请求
  bool _isCancelled = false;
  int _requestId = 0;
  
  // 公开访问视频控制器的getter
  VideoPlayerController? get videoController => _videoController;

  @override
  void initState() {
    super.initState();
    _initScreenBrightness();
    _initVolumeController();
    _startControlsTimer();
    _initVideoPlayer();
  }
  
  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 检查播放状态是否变化
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _videoController?.play();
      } else {
        _videoController?.pause();
      }
    }
    
    // 检查视频是否变化或播放地址是否变化
    if (widget.video.id != oldWidget.video.id || 
        !_arePlayUrlListsEqual(widget.video.playUrlList, oldWidget.video.playUrlList)) {
      print('视频或播放地址已更新，重新初始化播放器');
      print('旧地址: ${oldWidget.video.playUrlList}');
      print('新地址: ${widget.video.playUrlList}');
      
      // 先取消当前正在处理的请求
      _isCancelled = true;
      
      // 完全释放旧的控制器资源
      _disposeVideoController();
      
      // 延迟一小段时间确保旧的请求被完全取消
      Future.delayed(const Duration(milliseconds: 50), () {
        // 重新初始化视频播放器
        if (mounted) {
      _initVideoPlayer();
        }
      });
    }
  }

  String? _currentEpisodeUrl;
  
  // 初始化视频播放器
  Future<void> _initVideoPlayer() async {
    // 生成新的请求ID并重置取消标志
    final int thisRequestId = ++_requestId;
    _isCancelled = false;
    
    print('开始初始化视频播放器，请求ID: $thisRequestId, 地址: ${widget.video.playUrlList}');
    
    setState(() {
      _isLoadingVideo = true;
      _showCoverImage = true;
    });
    
    // 从视频列表中获取第一个播放地址
    if (widget.video.playUrlList.isNotEmpty) {
      final originalUrl = widget.video.playUrlList.first;
      _currentEpisodeUrl = originalUrl;
      
      // 检查请求是否已被取消
      if (!mounted || _isCancelled || thisRequestId != _requestId) {
        print('请求ID $thisRequestId 已被取消，不继续处理');
        return;
      }
      
      // 尝试通过解析接口获取真实播放地址
      try {
        final parsedData = await _apiService.getVideoParsingConfig(originalUrl);
        
        // 再次检查请求是否已被取消
        if (!mounted || _isCancelled || thisRequestId != _requestId) {
          print('请求ID $thisRequestId 在获取解析配置后被取消');
          return;
        }
        
        String videoUrl = originalUrl; // 默认使用原地址
        
        if (parsedData != null && 
            parsedData.containsKey('data') && 
            parsedData['data'] is Map) {
          final data = parsedData['data'] as Map<String, dynamic>;
          if (data.containsKey('url') && data['url'] is String && data['url'].toString().isNotEmpty) {
            videoUrl = data['url'].toString();
          }
        }
        
        if (mounted && !_isCancelled && thisRequestId == _requestId) {
          await _initVideoWithUrl(videoUrl, thisRequestId);
        } else {
          print('请求ID $thisRequestId 在准备初始化视频前被取消');
        }
      } catch (e) {
        // 如果解析失败，直接尝试播放原地址
        if (mounted && !_isCancelled && thisRequestId == _requestId) {
          await _initVideoWithUrl(originalUrl, thisRequestId);
        } else {
          print('请求ID $thisRequestId 在处理解析失败时被取消');
        }
      }
    } else {
      // 没有播放地址
      if (mounted && !_isCancelled && thisRequestId == _requestId) {
      setState(() {
        _isLoadingVideo = false;
        _showCoverImage = true;
      });
      }
    }
  }
  
  // 使用URL初始化视频播放器
  Future<void> _initVideoWithUrl(String url, int requestId) async {
    try {
      print('正在初始化视频播放器，请求ID: $requestId, URL: $url');
      
      // 检查请求是否已被取消
      if (!mounted || _isCancelled || requestId != _requestId) {
        print('请求ID $requestId 在初始化视频前已被取消');
        return;
      }
      
      // 检查URL是否为HLS格式(m3u8)
      final bool isHLS = url.toLowerCase().contains('.m3u8');
      print('视频格式: ${isHLS ? "HLS(m3u8)" : "普通视频"}');
      
      // 创建请求头
      final Map<String, String> headers = {
        'Referer': ApiConstants.baseUrl,
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X)',
      };
      
      // 如果有之前的控制器，先释放它
      if (_videoController != null) {
        print('请求ID $requestId 释放旧的视频控制器');
        await _videoController!.pause();
        _videoController!.removeListener(_videoListener);
        await _videoController!.dispose();
        _videoController = null;
      }
      
      // 创建新的视频控制器
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
        httpHeaders: headers,
      );
      
      print('请求ID $requestId 视频控制器创建完成，开始初始化...');
      
      // 初始化
      await controller.initialize().timeout(
        const Duration(seconds: 30), 
        onTimeout: () {
          print('视频初始化超时！');
          throw Exception('视频初始化超时');
        }
      );
      
      print('视频控制器初始化成功，时长: ${controller.value.duration.inSeconds}秒');
      
      if (mounted) {
        // 设置循环播放
        await controller.setLooping(true);
        
        // 如果有保存的观看进度，尝试跳转到对应位置
        if (widget.video.watchPosition != null && widget.video.watchPosition!.isNotEmpty) {
          try {
            final seconds = int.tryParse(widget.video.watchPosition!);
            if (seconds != null && seconds > 0) {
              // 确保不超过视频时长
              if (seconds < controller.value.duration.inSeconds) {
                print('恢复到上次观看位置: $seconds 秒');
                await controller.seekTo(Duration(seconds: seconds));
              }
            }
          } catch (e) {
            print('恢复观看进度失败: $e');
          }
        }
        
        // 如果初始状态为播放，则开始播放
        if (widget.isPlaying) {
          print('开始播放视频...');
          await controller.play();
        }
        
        // 更新状态
        setState(() {
          _videoController = controller;
          _isLoadingVideo = false;
          _showCoverImage = false;
          _totalTime = _formatDuration(controller.value.duration);
        });
        
        // 监听进度变化
        _videoController!.addListener(_videoListener);
        
        print('视频播放器设置完成');
      } else {
        print('组件已销毁，取消视频初始化');
        await controller.dispose();
      }
    } catch (e) {
      print('视频播放器初始化失败: $e');
      
      // 尝试加载第二次（有时网络问题导致的失败可通过重试解决）
      if (!_retried && mounted) {
        print('正在重试视频初始化...');
        _retried = true;
        await Future.delayed(const Duration(seconds: 1));
        await _initVideoWithUrl(url, requestId);
        return;
      }
      
      if (mounted) {
        setState(() {
          _isLoadingVideo = false;
          _showCoverImage = true;
        });
        
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('视频加载失败: ${e.toString().substring(0, min(e.toString().length, 100))}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  // 视频控制器监听器
  void _videoListener() {
    if (_videoController != null && mounted) {
      final position = _videoController!.value.position;
      final duration = _videoController!.value.duration;
      
      if (duration.inMilliseconds > 0) {
        final progress = position.inMilliseconds / duration.inMilliseconds;
        
        setState(() {
          _progress = progress;
          _currentTime = _formatDuration(position);
          _totalTime = _formatDuration(duration);
          // 不再更新缓冲状态
          // _isBuffering = _videoController!.value.isBuffering;
        });
      }
    }
  }
  
  // 格式化时间
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    return duration.inHours > 0 
        ? '$hours:$minutes:$seconds' 
        : '$minutes:$seconds';
  }

  // 初始化亮度控制器
  Future<void> _initScreenBrightness() async {
    try {
      _brightness = await ScreenBrightness().current;
      _lastUsableBrightness = _brightness;
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _brightness = 0.7;
      _useFallbackBrightness = true;
      
      if (mounted) {
        setState(() {});
      }
    }
  }

  // 初始化音量控制器
  void _initVolumeController() {
    try {
      _volumeController.addListener((volume) {
        if (mounted) {
          setState(() {
            _volume = volume;
          });
        }
      });
      
      _volumeController.getVolume().then((volume) {
        if (mounted) {
          setState(() {
            _volume = volume;
          });
        }
      }).catchError((e) {
        _volume = 0.8;
      });
    } catch (e) {
      _volume = 0.8;
    }
  }

  // 启动控制栏自动隐藏计时器
  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  void _toggleControlsVisibility() {
    setState(() {
      _controlsVisible = !_controlsVisible;
      
      if (_controlsVisible) {
        _startControlsTimer();
      } else {
        _controlsTimer?.cancel();
      }
    });
  }

  // 切换全屏/非全屏模式
  void _toggleFullScreen() async {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    
    if (_isFullScreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  // 处理屏幕左侧垂直拖动手势（亮度调节）
  void _onBrightnessChange(double delta) async {
    delta = delta * 5.0;
    
    try {
      setState(() {
        _brightness = (_brightness - delta).clamp(0.0, 1.0);
        _showBrightnessIndicator = true;
      });
      
      if (!_useFallbackBrightness) {
        try {
          await ScreenBrightness().setScreenBrightness(_brightness);
          _lastUsableBrightness = _brightness;
        } catch (e) {
          _useFallbackBrightness = true;
        }
      }
    } catch (e) {
      // 处理错误
    }
  }

  // 处理屏幕右侧垂直拖动手势（音量调节）
  void _onVolumeChange(double delta) async {
    delta = delta * 5.0;
    
    try {
      setState(() {
        _volume = (_volume - delta).clamp(0.0, 1.0);
        _showVolumeIndicator = true;
      });
      
      try {
        await _volumeController.setVolume(_volume);
      } catch (e) {
        // 处理错误
      }
    } catch (e) {
      // 处理错误
    }
  }
  
  // 处理播放位置变化
  void _onProgressChanged(double value) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final duration = _videoController!.value.duration;
      final position = duration * value;
      _videoController!.seekTo(position);
      
      setState(() {
        _progress = value;
        _currentTime = _formatDuration(position);
      });
    }
  }
  
  // 处理播放/暂停
  void _togglePlayPause() {
    widget.onTogglePlaying();
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (widget.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _volumeController.removeListener();
    _disposeVideoController();
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
  
  // 释放视频控制器资源
  void _disposeVideoController() {
    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
      _videoController!.dispose();
      _videoController = null;
    }
  }

  // 比较两个播放URL列表是否相同
  bool _arePlayUrlListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    if (list1.isEmpty && list2.isEmpty) return true;
    
    // 直接比较第一个URL是否相同，确保正确检测到URL变化
    if (list1.isNotEmpty && list2.isNotEmpty) {
      return list1.first == list2.first;
    }
    
    return false;
  }

  // 公开方法以便外部调用停止并释放视频资源
  void disposeVideoPlayer() {
    print('手动释放视频播放器资源');
    // 先暂停播放
    _videoController?.pause();
    // 释放资源
    _disposeVideoController();
  }
  
  // 强制刷新播放器，用于在选集切换时确保视频更新
  void refreshPlayer() {
    print('强制刷新视频播放器，当前地址: ${widget.video.playUrlList}');
    
    // 取消当前正在处理的视频请求
    _isCancelled = true;
    
    // 先退出全屏模式（如果处于全屏状态）
    if (_isFullScreen) {
      _toggleFullScreen();
    }
    
    // 停止当前播放
    if (_videoController != null) {
      print('暂停并释放当前播放的视频');
      _videoController!.pause();
    }
    
    // 完全释放当前播放器资源
    _disposeVideoController();
    
    // 重置状态
    setState(() {
      _isLoadingVideo = true;
      _showCoverImage = true;
      _progress = 0.0;
      _currentTime = '00:00';
      _retried = false;
    });
    
    // 使用短暂延迟确保UI更新后再初始化
    Future.delayed(const Duration(milliseconds: 100), () {
    // 重新初始化
    _initVideoPlayer();
    });
  }

  // 从指定位置开始播放
  Future<void> seekToPosition(String? position) async {
    if (_videoController == null || 
        !_videoController!.value.isInitialized || 
        position == null) {
      return;
    }
    
    try {
      // 将字符串转换为秒数
      final seconds = int.tryParse(position);
      if (seconds != null && seconds > 0) {
        // 检查是否超过视频时长
        final duration = _videoController!.value.duration;
        if (seconds < duration.inSeconds) {
          print('正在跳转到 $seconds 秒');
          await _videoController!.seekTo(Duration(seconds: seconds));
        }
      }
    } catch (e) {
      print('跳转到指定位置失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据是否全屏调整播放器尺寸
    final screenSize = MediaQuery.of(context).size;
    final containerWidth = _isFullScreen ? screenSize.width : double.infinity;
    // 非全屏模式下也考虑状态栏高度，让播放器充满整个顶部区域
    final statusBarHeight = MediaQuery.of(context).padding.top;
    // 在竖屏模式下使播放器高度更紧凑
    final containerHeight = _isFullScreen ? 
        screenSize.height : 
        (180.0 + statusBarHeight); // 进一步减小高度使其更紧凑

    return GestureDetector(
      onTap: _toggleControlsVisibility,
      child: Container(
        width: containerWidth,
        height: containerHeight,
        color: Colors.black,
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 首先添加一个黑色背景铺满整个容器
            Container(
                width: double.infinity,
                height: double.infinity,
              color: Colors.black,
                    ),
            
            // 视频画面 - 确保铺满整个区域
            _videoController != null && _videoController!.value.isInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                    ),
                      )
                : Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('视频加载中...', style: TextStyle(color: Colors.white)),
                  ],
                      ),
                ),
              ),
              
            // 左侧亮度调节区域
            if (_isFullScreen)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: containerWidth * 0.5,
                child: GestureDetector(
                  onVerticalDragStart: (_) {
                    setState(() {
                      _draggingBrightness = true;
                      _showBrightnessIndicator = true;
                      _cumulativeBrightnessDelta = 0.0;
                    });
                  },
                  onVerticalDragUpdate: (details) {
                    final delta = details.delta.dy / containerHeight;
                    _cumulativeBrightnessDelta += delta;
                    
                    if (delta.abs() > 0.0005 || _cumulativeBrightnessDelta.abs() > 0.001) {
                      _onBrightnessChange(_cumulativeBrightnessDelta);
                      _cumulativeBrightnessDelta = 0.0;
                    }
                  },
                  onVerticalDragEnd: (_) {
                    setState(() {
                      _draggingBrightness = false;
                      _showBrightnessIndicator = false;
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: _draggingBrightness 
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        )
                      : null,
                  ),
                ),
              ),
              
            // 右侧音量调节区域
            if (_isFullScreen)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: containerWidth * 0.5,
                child: GestureDetector(
                  onVerticalDragStart: (_) {
                    setState(() {
                      _draggingVolume = true;
                      _showVolumeIndicator = true;
                      _cumulativeVolumeDelta = 0.0;
                    });
                  },
                  onVerticalDragUpdate: (details) {
                    final delta = details.delta.dy / containerHeight;
                    _cumulativeVolumeDelta += delta;
                    
                    if (delta.abs() > 0.0005 || _cumulativeVolumeDelta.abs() > 0.001) {
                      _onVolumeChange(_cumulativeVolumeDelta);
                      _cumulativeVolumeDelta = 0.0;
                    }
                  },
                  onVerticalDragEnd: (_) {
                    setState(() {
                      _draggingVolume = false;
                      _showVolumeIndicator = false;
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: _draggingVolume
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        )
                      : null,
                  ),
                ),
              ),
            
            // 亮度指示器
            if (_isFullScreen && _showBrightnessIndicator)
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 150),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(left: 30),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.brightness_6, color: Colors.white.withOpacity(0.9), size: 28),
                        const SizedBox(height: 8),
                        Container(
                          height: 100,
                          width: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                heightFactor: _brightness,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withOpacity(0.7),
                                        Colors.white.withOpacity(0.9),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 0.5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ...List.generate(5, (index) {
                                return Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: (100 / 4) * index.toDouble(),
                                  child: Container(
                                    height: 0.5,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_brightness * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // 音量指示器
            if (_isFullScreen && _showVolumeIndicator)
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 150),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(right: 30),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up, color: Colors.white.withOpacity(0.9), size: 28),
                        const SizedBox(height: 8),
                        Container(
                          height: 100,
                          width: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                heightFactor: _volume,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withOpacity(0.7),
                                        Colors.white.withOpacity(0.9),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 0.5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ...List.generate(5, (index) {
                                return Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: (100 / 4) * index.toDouble(),
                                  child: Container(
                                    height: 0.5,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_volume * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // 顶部工具栏 - 带更强的渐变效果
            if (_controlsVisible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top, 4, 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.9), 
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.3),
                        Colors.transparent
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        onPressed: () {
                          if (_isFullScreen) {
                            _toggleFullScreen();
                          } else {
                            widget.onBack();
                          }
                          _startControlsTimer();
                        },
                        padding: const EdgeInsets.all(1),
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                      Expanded(
                        child: Text(
                          widget.video.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
            // 底部控制栏
            if (_controlsVisible)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      // 播放/暂停按钮
                      IconButton(
                        icon: Icon(
                          widget.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          _togglePlayPause();
                          _startControlsTimer();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      
                      // 当前时间
                      const SizedBox(width: 4),
                      Text(
                        _currentTime,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      
                      // 进度条
                          const SizedBox(width: 4),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                trackHeight: 1.5,
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white.withOpacity(0.3),
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                            value: _progress,
                            onChanged: (value) {
                              _onProgressChanged(value);
                              _startControlsTimer();
                            },
                          ),
                        ),
                      ),
                      
                      // 总时间
                      const SizedBox(width: 4),
                      Text(
                        _totalTime,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      
                      // 全屏按钮
                          const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          _toggleFullScreen();
                          _startControlsTimer();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 