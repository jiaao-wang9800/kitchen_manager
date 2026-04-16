// lib/widgets/recipe_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../providers/recipe_provider.dart';
import '../providers/kitchen_provider.dart'; // [新增]
import '../providers/cart_provider.dart';    // [新增]
import '../screens/recipe_detail_screen.dart';

class RecipeCard extends ConsumerWidget {
  final Recipe recipe;
  
  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      // ... 外层装饰代码保持不变 ...
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipeId: recipe.id)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部图片区域 (保持不变)
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal.shade100, Colors.teal.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: recipe.imagePath != null 
                ? Image.network(recipe.imagePath!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.restaurant, size: 48, color: Colors.white54))
                : const Icon(Icons.restaurant, size: 48, color: Colors.white54),
            ),
            
            // 底部文字信息区域
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
                  
                  // [修改] 右侧操作按钮组 (购物车 + 收藏)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 添加到购物车按钮
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