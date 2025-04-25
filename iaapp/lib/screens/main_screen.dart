import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'home_screen.dart';
import 'rank_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = const [
    HomeScreen(),
    RankScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon('assets/dhmin/首页_home.png', false),
            activeIcon: _buildNavIcon('assets/dhmin/首页_home.png', true),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon('assets/dhmin/排行_ranking.png', false),
            activeIcon: _buildNavIcon('assets/dhmin/排行_ranking.png', true),
            label: '排行',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon('assets/dhmin/我的_reduce-user.png', false),
            activeIcon: _buildNavIcon('assets/dhmin/我的_reduce-user.png', true),
            label: '我的',
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(String assetPath, bool isActive) {
    final color = isActive ? AppConstants.primaryColor : Colors.grey.shade600;
    
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        color,
        BlendMode.srcIn,
      ),
      child: Image.asset(
        assetPath,
        width: 22,
        height: 22,
      ),
    );
  }
} 