// lib/screens/main_tab_screen.dart
import 'package:flutter/material.dart';
import 'inventory_screen.dart'; 
import 'recipe_list_screen.dart'; // 👈 [新增] 引入刚刚建好的菜谱列表页面
import 'calendar_screen.dart';
import 'shopping_cart_screen.dart';
import 'settings_screen.dart';


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
      const ShoppingCartScreen(), // 👈 [新增]
      const SettingsScreen(), // 👈 [新增]
    ];

    return Scaffold(
      body: screens[_selectedIndex], 
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 超过4个必须要设为 fixed，否则会变成奇怪的白色透明底
        selectedItemColor: const Color(0xFF4A5D4E), // 选中时的深绿色
        unselectedItemColor: Colors.grey.shade400,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Kitchen'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Planner'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'), // 🌟 第 5 个 Tab
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}