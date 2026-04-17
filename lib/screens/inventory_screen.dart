// lib/screens/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../providers/kitchen_provider.dart';
import '../widgets/stardew_panel.dart';
import '../widgets/ingredient_edit_dialog.dart';
import '../main.dart'; // for isStardewTheme
import 'matched_recipes_screen.dart'; // 👈 新增导入
import '../widgets/ingredient_card.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  StorageLocation _selectedLocation = StorageLocation.fridge;
  String? _selectedCategoryId;

  void _showIngredientDialog({Ingredient? existingIngredient, String? defaultCategoryId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IngredientEditDialog(
        existingIngredient: existingIngredient,
        defaultCategoryId: defaultCategoryId ?? _selectedCategoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 监听 Riverpod 数据源，替代旧的全局变量！
    final allCategories = ref.watch(categoryProvider);
    final myInventory = ref.watch(inventoryProvider);

    final locationCategories = allCategories.where((c) => c.location == _selectedLocation).toList();
    
    // 自动选中当前位置的第一个分类
    if (_selectedCategoryId == null && locationCategories.isNotEmpty) {
      _selectedCategoryId = locationCategories.first.id;
    }

    return StardewPanelContainer(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // 现代简洁浅灰背景
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('My Kitchen', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            IconButton(
              icon: const Icon(Icons.bolt, color: Colors.orangeAccent), 
              tooltip: '一键刷新营养成分', 
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🤖 AI 正在分析库中食材，请稍候...'))
                );
                try {
                  // 🌟 呼叫 Riverpod 后台执行 AI 任务
                  final count = await ref.read(inventoryProvider.notifier).batchAnalyzeNutrition();
                  
                  if (context.mounted) {
                    if (count > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✨ 成功为 $count 项食材匹配营养标签！'), backgroundColor: const Color(0xFF10C07B))
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('所有食材都已分析完毕，无需刷新啦 ✨'))
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('分析失败，请检查网络或 API 设置'), backgroundColor: Colors.red)
                    );
                  }
                }
              },
            ),
          ],
        ),  
        body: Column(
          children: [
            _buildTopLocationBar(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeftCategoryMenu(locationCategories),
                  Expanded(child: _buildRightContentArea(locationCategories, myInventory)),
                ],
              ),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF10C07B), // 你的核心强调色
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
          elevation: 2,
          onPressed: () => _showIngredientDialog(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildTopLocationBar() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: StorageLocation.values.length,
        itemBuilder: (context, index) {
          final loc = StorageLocation.values[index];
          final isSelected = loc == _selectedLocation;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedLocation = loc;
                _selectedCategoryId = null; // 切换位置时重置选中的分类
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF10C07B) : Colors.grey.shade600, // 修改为绿色高亮
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 3,
                      width: 24,
                      decoration: BoxDecoration(color: const Color(0xFF10C07B), borderRadius: BorderRadius.circular(2)),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeftCategoryMenu(List<IngredientCategory> categories) {
    return Container(
      width: 90,
      color: const Color(0xFFF5F5F5),
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.id == _selectedCategoryId;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryId = cat.id),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border(left: BorderSide(color: isSelected ? const Color(0xFF10C07B) : Colors.transparent, width: 4))
              ),
              alignment: Alignment.center,
              child: Text(
                cat.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightContentArea(List<IngredientCategory> categories, List<Ingredient> myInventory) {
    if (categories.isEmpty) return const Center(child: Text('此位置暂无分类', style: TextStyle(color: Colors.grey)));

    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          // 仅过滤当前分类下的食材
          final ingredients = myInventory.where((i) => i.categoryId == cat.id).toList();

          ingredients.sort((a, b) {
            if (a.inStock && !b.inStock) return -1;
            if (!a.inStock && b.inStock) return 1;
            return a.name.compareTo(b.name); 
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                child: Text(cat.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black45)),
              ),
              
              if (ingredients.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text('还没有添加食材哦', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                )
              else
                ...ingredients.map((ing) => IngredientCard(ingredient: ing)),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 4.0),
                child: InkWell(
                  onTap: () => _showIngredientDialog(defaultCategoryId: cat.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text('+ 添加到 ${cat.name}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

}