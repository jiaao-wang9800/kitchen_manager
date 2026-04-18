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
import '../data/mock_database.dart';

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

// 🌟 新增：动态添加分类的弹窗
  void _showAddCategoryDialog(BuildContext context, StorageLocation currentLocation) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('在【${currentLocation.displayName}】添加新分类', style: const TextStyle(fontSize: 16)),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '例如：水果、甜品...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10C07B), // 你的主题绿
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  // 1. 构建新的分类对象
                  final newCategory = IngredientCategory(
                    id: generateId(), 
                    name: name,
                    location: currentLocation,
                  );

                  // 2. 存入物理数据库
                  await categoryBox.put(newCategory.id, newCategory);

                  // 3. 刷新 Riverpod 状态 (让 UI 重新拉取最新数据)
                  ref.invalidate(categoryProvider);

                  if (context.mounted) {
                    Navigator.pop(context);
                    // 🌟 贴心细节：添加完成后，自动帮用户选中这个新分类
                    setState(() {
                      _selectedCategoryId = newCategory.id;
                    });
                  }
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 监听 Riverpod 数据源，替代旧的全局变量！
    final allCategories = ref.watch(categoryProvider);
    final myInventory = ref.watch(inventoryProvider);

    final locationCategories = allCategories.where((c) => c.location == _selectedLocation).toList();

    // 🌟 2. 新增排序逻辑：让新加的分类永远在最下面
    locationCategories.sort((a, b) {
      // 识别是不是默认分类（因为我们的默认分类都是 'cat_' 开头的）
      final aIsDefault = a.id.startsWith('cat_');
      final bIsDefault = b.id.startsWith('cat_');
      
      if (aIsDefault && !bIsDefault) return -1; // a 是默认，b 是新增，a 排在前面
      if (!aIsDefault && bIsDefault) return 1;  // b 是默认，a 是新增，b 排在前面
      
      // 如果都是新增的，或者都是默认的，就按它们自己的名字或 ID 排
      return a.id.compareTo(b.id); 
    });
    
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
              icon: const Icon(Icons.create_new_folder_outlined, color: Color(0xFF10C07B)), 
              tooltip: '新增分类',
              onPressed: () => _showAddCategoryDialog(context, _selectedLocation),
            ),
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