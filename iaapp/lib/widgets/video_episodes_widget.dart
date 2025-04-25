import 'package:flutter/material.dart';

class VideoEpisodesWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;
  final List<String> episodes;
  final List<String> episodeNames; // 选集名称列表，来自vod_play_note

  const VideoEpisodesWidget({
    Key? key,
    required this.selectedIndex,
    required this.onSelect,
    required this.episodes,
    this.episodeNames = const [], // 设置为可选参数，默认为空列表
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 如果没有选集，则不显示此组件
    if (episodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            '选集',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              String episodeName;
              
              // 优先使用API返回的选集名称
              if (episodeNames.isNotEmpty && index < episodeNames.length) {
                episodeName = episodeNames[index];
              } else {
                // 如果没有选集名称，使用简单编号
                if (episodes.length == 1) {
                  episodeName = '1';
                } else {
                  episodeName = '${index + 1}';
                }
              }
              
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () {
                    // 打印点击日志
                    print('选集点击: $episodeName (索引: $index)');
                    
                    // 如果已经是选中状态，忽略点击
                    if (index == selectedIndex) {
                      print('忽略重复点击当前选集');
                      return;
                    }
                    
                    // 延迟一小段时间确保能正确触发切换
                    Future.delayed(const Duration(milliseconds: 50), () {
                      print('触发选集切换回调: index=$index');
                      onSelect(index);
                    });
                  },
                  child: _buildEpisodeItem(
                    episodeName,
                    index == selectedIndex,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeItem(String name, bool isSelected) {
    // 为版本类型名称定制适当的宽度
    double minWidth = 48.0; // 基础最小宽度
    
    // 根据名称长度增加最小宽度
    if (name.length > 2) {
      minWidth += (name.length - 2) * 8.0;
    }
    
    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
        ),
      ),
      child: Center(
        child: Text(
          name,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.black87,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
} 