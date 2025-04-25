import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../models/category_model.dart' as model;

class CategoryList extends StatelessWidget {
  final String currentCategory;
  final Function(String) onCategorySelected;
  
  const CategoryList({
    super.key,
    required this.currentCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, child) {
        final categories = videoProvider.categories;
        final currentCategoryId = videoProvider.currentCategoryId;
        
        // 调试日志
        print('CategoryList.build: 当前选中分类=$currentCategory, ID=$currentCategoryId, 获取到分类数量=${categories.length}');
        
        if (categories.isEmpty) {
          print('CategoryList: 分类列表为空，显示加载指示器');
          return const SizedBox(
            height: 44,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }
        
        print('CategoryList: 开始构建分类列表UI，项目数量=${categories.length}');
        
        // 使用居中方式一: 计算ListView总宽度，确保能在屏幕中央对齐
        double screenWidth = MediaQuery.of(context).size.width;
        
        return Container(
          height: 44,
          width: screenWidth,
          alignment: Alignment.center,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: categories.map((category) {
                final isSelected = category.id == currentCategoryId;
                
                return GestureDetector(
                  onTap: () => onCategorySelected(category.id),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            color: isSelected ? Colors.blue : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 选中指示器
                        if (isSelected)
                          Container(
                            width: 18,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        else
                          const SizedBox(height: 3) // 占位，保持高度一致
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }
    );
  }
} 