// lib/widgets/recipe_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart'; // 用于 generateId()
import '../providers/recipe_provider.dart';
import '../providers/kitchen_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/meal_plan_provider.dart'; // 🌟 引入日历 Provider
import '../screens/recipe_detail_screen.dart';

class RecipeCard extends ConsumerWidget {
  final Recipe recipe;
  final DateTime? quickAddDate; // 🌟 关键修复：在这里定义参数！

  // 🌟 关键修复：在构造函数中接收它！
  const RecipeCard({super.key, required this.recipe, this.quickAddDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // 点击卡片跳转到详情页
          Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipeId: recipe.id)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 顶部图片区域
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal.shade100, Colors.teal.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: recipe.imagePath != null 
                ? Image.network(recipe.imagePath!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.restaurant, size: 48, color: Colors.white54))
                : const Icon(Icons.restaurant, size: 48, color: Colors.white54),
            ),
            
            // 2. 底部文字与操作区域
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Text('${recipe.ingredients.length} 种食材 · ${recipe.steps.length} 个步骤', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  
                  // 3. 右侧操作按钮组
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🌟 神仙联动：如果这是从日历推荐跳过来的，就显示“排入今日”的快捷按钮！
                      if (quickAddDate != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A5D4E), // 你的高级深绿
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              minimumSize: const Size(0, 32),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add_task, size: 14),
                            label: const Text('排入今日', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final mealType = await showDialog<MealType>(
                                context: context,
                                builder: (c) => SimpleDialog(
                                  title: const Text('排入哪个餐段?'),
                                  children: MealType.values.map((t) => SimpleDialogOption(
                                    onPressed: () => Navigator.pop(c, t),
                                    child: Text(t.displayName, style: const TextStyle(fontSize: 15)),
                                  )).toList(),
                                )
                              );
                              if (mealType != null) {
                                // 写入日历
                                final plan = MealPlan(id: generateId(), date: quickAddDate!, type: mealType, recipeId: recipe.id);
                                await ref.read(mealPlanProvider.notifier).addMealPlan(plan);
                                
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已将 ${recipe.name} 安排上啦！'), backgroundColor: const Color(0xFF10C07B)));
                                  // 顺滑体验：直接退回日历页
                                  Navigator.pop(context); 
                                }
                              }
                            },
                          ),
                        ),

                      // 一键加入购物车按钮
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, color: Colors.teal),
                        tooltip: '一键将缺货食材加入购物车',
                        onPressed: () async {
                          final inventory = ref.read(inventoryProvider);
                          final addedCount = await ref.read(cartProvider.notifier).addMissingIngredientsForRecipe(recipe, inventory);
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(addedCount > 0 ? '已将 $addedCount 种缺货食材加入购物车！' : '家里食材充足，无需购买！'),
                                backgroundColor: addedCount > 0 ? const Color(0xFF10C07B) : Colors.blueGrey,
                                duration: const Duration(seconds: 2),
                              )
                            );
                          }
                        },
                      ),
                      // 收藏按钮
                      IconButton(
                        icon: Icon(recipe.isFavorite ? Icons.favorite : Icons.favorite_border, color: recipe.isFavorite ? Colors.redAccent : Colors.grey.shade400),
                        onPressed: () => ref.read(recipeProvider.notifier).toggleFavorite(recipe),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}