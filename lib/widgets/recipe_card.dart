// lib/widgets/recipe_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart'; 
import '../providers/recipe_provider.dart';
import '../providers/kitchen_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/meal_plan_provider.dart';
import '../screens/recipe_detail_screen.dart';

class RecipeCard extends ConsumerWidget {
  final Recipe recipe;
  final DateTime? quickAddDate;

  const RecipeCard({super.key, required this.recipe, this.quickAddDate});

  // 🌟 修复：重新实现日历添加逻辑（Riverpod 版）
  Future<void> _handleCalendarTap(BuildContext context, WidgetRef ref) async {
    // 1. 如果有快捷日期，直接弹窗选餐段
    DateTime? selectedDate = quickAddDate;
    
    // 2. 如果没有快捷日期，先选日期
    if (selectedDate == null) {
      selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 30)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
    }

    if (selectedDate == null || !context.mounted) return;

    // 3. 选择餐段
    final mealType = await showDialog<MealType>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('选择餐段 (Meal Type)'),
        children: MealType.values.map((t) => SimpleDialogOption(
          onPressed: () => Navigator.pop(c, t),
          child: Text(t.displayName, style: const TextStyle(fontSize: 16)),
        )).toList(),
      ),
    );

    if (mealType != null) {
      final plan = MealPlan(
        id: generateId(), 
        date: selectedDate, 
        type: mealType, 
        recipeId: recipe.id
      );
      // 使用 Provider 写入数据库
      await ref.read(mealPlanProvider.notifier).addMealPlan(plan);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已加入 ${selectedDate.month}月${selectedDate.day}日 菜单'), backgroundColor: Colors.teal)
        );
        if (quickAddDate != null) Navigator.pop(context); // 快捷模式下自动关闭搜索
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    // 这里假设你有一个 Provider 提供所有菜谱分类，或者直接用 Mock 数据里的
    final allCategories = allRecipeCategories; 

    // 计算缺失食材
    int missingCount = 0;
    for (var req in recipe.ingredients) {
      final inStock = inventory.any((inv) => 
        (inv.id == req.ingredientId || inv.name == req.ingredientId) && inv.inStock
      );
      if (!inStock) missingCount++;
    }
    final bool isFull = missingCount == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipeId: recipe.id))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 1. 左侧信息区
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      
                      // 🌟 核心修改：状态胶囊 + 食谱标签 并在同一行
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // 状态胶囊
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isFull ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isFull ? Icons.check_circle : Icons.error_outline, size: 14, color: isFull ? Colors.green : Colors.orange),
                                const SizedBox(width: 4),
                                Text(isFull ? '食材齐全' : '缺 $missingCount 样', style: TextStyle(color: isFull ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          
                          // 补货小按钮
                          if (!isFull)
                            GestureDetector(
                              onTap: () async {
                                final added = await ref.read(cartProvider.notifier).addMissingIngredientsForRecipe(recipe, inventory);
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已将 $added 种食材加入购物车 🛒')));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.add_shopping_cart, size: 14, color: Colors.orange),
                              ),
                            ),

                          // 🌟 食谱原有的 Tag (紧随其后)
                          ...allCategories
                              .where((cat) => recipe.categoryIds.contains(cat.id))
                              .map((cat) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                                    child: Text(cat.name, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500)),
                                  )),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 2. 右侧图片与叠层按钮区
                const SizedBox(width: 12),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: recipe.imagePath != null
                          ? (recipe.imagePath!.startsWith('http') 
                              ? Image.network(recipe.imagePath!, width: 90, height: 90, fit: BoxFit.cover)
                              : Image.asset(recipe.imagePath!, width: 90, height: 90, fit: BoxFit.cover))
                          : Container(color: Colors.grey.shade100, width: 90, height: 90, child: const Icon(Icons.restaurant, color: Colors.grey)),
                    ),
                    
                    // 收藏按钮
                    Positioned(
                      top: -4, right: -4,
                      child: GestureDetector(
                        onTap: () => ref.read(recipeProvider.notifier).toggleFavorite(recipe),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                          child: Icon(recipe.isFavorite ? Icons.favorite : Icons.favorite_border, size: 16, color: recipe.isFavorite ? Colors.pinkAccent : Colors.grey),
                        ),
                      ),
                    ),

                    // 🌟 修复后的日历添加按钮
                    Positioned(
                      bottom: 4, right: 4,
                      child: GestureDetector(
                        onTap: () => _handleCalendarTap(context, ref),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: quickAddDate != null ? const Color(0xFF4A5D4E) : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Icon(
                            quickAddDate != null ? Icons.add : Icons.event_available, 
                            size: 18, 
                            color: quickAddDate != null ? Colors.white : const Color(0xFF4A5D4E)
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}