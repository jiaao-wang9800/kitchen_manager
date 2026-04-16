// lib/screens/recipe_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recipe_provider.dart';
import '../widgets/recipe_card.dart'; 
import '../widgets/recipe_dialogs.dart'; // 引入刚才抽离的弹窗组件
import 'recipe_detail_screen.dart';
import 'recipe_category_manager_screen.dart';
import '../models/app_models.dart'; // 👈 [关键修复]：加上这一行，拯救所有的 Recipe 报错！

class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});
  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  String _mainSearchQuery = '';
  String? _selectedFilterCatId;

  @override
  Widget build(BuildContext context) {
    // [修改] 获取全局数据源
    final allRecipes = ref.watch(recipeProvider);
    final allRecipeCategories = ref.watch(recipeCategoryProvider);

    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // 浅米色/灰色底，衬托白色卡片
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 70, // 加高一点适配两行文字
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('全家共享 · 菜谱库', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              Text('家庭厨房', style: TextStyle(fontSize: 28, color: Colors.black87, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.amber), 
              tooltip: 'AI Smart Import', 
              onPressed: () => showDialog(context: context, builder: (c) => const AiImportDialog())
            ),
            IconButton(
              icon: const Icon(Icons.label_outline, color: Colors.black54), 
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecipeCategoryManagerScreen()))
            )     
          ],
        ),
        body: Column(
          children: [
            // 1. 搜索框：淡青灰色背景，无边框 (100% 还原)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索食谱、食材...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFE9EDEA), // 高级感淡青灰
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _mainSearchQuery = val),
              ),
            ),

            // 2. 分类横向滚动条 (ChoiceChip) (100% 还原)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(label: '全部', id: null),
                  ...allRecipeCategories.map((cat) => _buildFilterChip(label: cat.name, id: cat.id)),
                  // 增加一个“我的喜爱”快捷入口
                  const SizedBox(width: 8),
                  Container(width: 1, height: 20, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 4)),
                  const SizedBox(width: 8),
                  _buildFilterChip(label: '我的喜爱 ❤️', id: 'FAV_ONLY_SPECIAL_ID'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. 核心列表 (使用 Riverpod 过滤逻辑)
            Expanded(
              child: _buildRecipeList(allRecipes),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF4A5D4E), // 深橄榄绿
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: () => showDialog(context: context, builder: (c) => const RecipeEditDialog()), 
          child: const Icon(Icons.add, color: Colors.white, size: 28)
        ),
      ),
    );
  }

  // 辅助方法：构建圆角分类标签 (保持原样)
  Widget _buildFilterChip({required String label, required String? id}) {
    final bool isSelected = _selectedFilterCatId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _selectedFilterCatId = id);
        },
        selectedColor: const Color(0xFF4A5D4E), // 选中时的深绿色
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
        showCheckmark: false,
      ),
    );
  }

  // 🌟 核心重构：将 Grid 改为了直接调用 RecipeCard 的 ListView
  Widget _buildRecipeList(List<Recipe> allRecipes) {
    final bool onlyFavorites = _selectedFilterCatId == 'FAV_ONLY_SPECIAL_ID';
    
    final displayedRecipes = allRecipes.where((r) {
      final matchesSearch = r.name.toLowerCase().contains(_mainSearchQuery.toLowerCase());
      final matchesCategory = (_selectedFilterCatId == null || onlyFavorites) 
          ? true 
          : r.categoryIds.contains(_selectedFilterCatId);
      final matchesFav = !onlyFavorites || r.isFavorite; 
      return matchesSearch && matchesCategory && matchesFav;
    }).toList();

    if (displayedRecipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(onlyFavorites ? '还没有收藏的菜谱' : '没有找到相关菜谱', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100), // 底部留出 FAB 的空间
      itemCount: displayedRecipes.length,
      itemBuilder: (context, index) {
        final recipe = displayedRecipes[index];
        return RecipeCard(recipe: recipe);
      },
    );
  }
}