// lib/screens/main_tab_screen.dart
import 'package:flutter/material.dart';
import 'inventory_screen.dart'; 
import 'recipe_list_screen.dart'; // 👈 [新增] 引入刚刚建好的菜谱列表页面
import 'calendar_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});
  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    // 将第二个页面替换为真实的 RecipeListScreen
    final List<Widget> screens = [
      const InventoryScreen(), 
      const RecipeListScreen(), // 👈 [关键修改]
      const CalendarScreen(),
      const Center(child: Text('购物车页面 (准备迁移中...)', style: TextStyle(fontSize: 24))),
    ];

    return Scaffold(
      body: screens[_selectedIndex], 
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, 
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Kitchen'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Planner'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}