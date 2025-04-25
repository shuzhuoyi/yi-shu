import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_constants.dart';

class SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onDownloadTap;
  final VoidCallback onUserTap;
  
  const SearchBox({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onDownloadTap,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 搜索框
        Expanded(
          child: Container(
            height: 35,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(Icons.search, color: Colors.grey, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSearch(),
                    decoration: const InputDecoration(
                      hintText: '请输入关键字',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 5),
        // 下载按钮
        IconButton(
          onPressed: onDownloadTap,
          icon: Image.asset(
            'assets/sytbmin/下载_download_副本.png',
            width: 22,
            height: 22,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        // 历史按钮
        IconButton(
          onPressed: onUserTap,
          icon: Image.asset(
            'assets/sytbmin/历史记录_history.png',
            width: 22,
            height: 22,
          ),
          padding: const EdgeInsets.only(left: 10),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
} 