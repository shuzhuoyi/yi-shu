import 'package:flutter/material.dart';
import '../models/video_model.dart';

class VideoSourcesWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;
  final List<String> playSources;

  const VideoSourcesWidget({
    Key? key,
    required this.selectedIndex,
    required this.onSelect,
    required this.playSources,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 如果没有播放源，则不显示此组件
    if (playSources.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 6.0),
          child: Text(
            '播放源',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: playSources.length,
            itemBuilder: (context, index) => _buildSourceItem(context, index),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceItem(BuildContext context, int index) {
    final bool isSelected = index == selectedIndex;
    final String source = playSources[index];

    return GestureDetector(
      onTap: () {
        onSelect(index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3.0),
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(5.0),
        ),
        alignment: Alignment.center,
        child: Text(
          source,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
} 