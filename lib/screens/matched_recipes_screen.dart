// lib/screens/matched_recipes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../providers/recipe_provider.dart';
import '../providers/kitchen_provider.dart';
import '../widgets/recipe_card.dart';

class MatchedRecipesScreen extends ConsumerWidget {
  final Ingredient ingredient;
  final DateTime? targetDate; 

  const MatchedRecipesScreen({super.key, required this.ingredient, this.targetDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取全局状态
    final allRecipes = ref.watch(recipeProvider);
    final inventory = ref.watch(inventoryProvider);

    // 🌟 保留你极其优秀的智能多重匹配逻辑
    final matchedRecipes = allRecipes.where((recipe) {
      return recipe.ingredients.any((ri) {
        // 条件 A: ID 直接匹配
        if (ri.ingredientId == ingredient.id) return true;
        
        // 条件 B: 名称匹配（兼容手动输入的旧数据）
        final String currentIngName = ingredient.name.trim().toLowerCase();
        final recipeIngDetails = inventory.where((inv) => inv.id == ri.ingredientId).firstOrNull;
        if (recipeIngDetails != null) {
          return recipeIngDetails.name.trim().toLowerCase() == currentIngName;
        }
        
        // 条件 C: 如果 ingredientId 本身存的就是名称字符串
        return ri.ingredientId.trim().toLowerCase() == currentIngName;
      });
    }).toList();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 浅米色底色，衬托白色卡片
      appBar: AppBar(
        title: Text(
          '包含 "${ingredient.name}" 的菜谱', 
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)
        ), 
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: matchedRecipes.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    '暂无包含此食材的菜谱', 
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16)
                  ),
                ],
              ),
            ) 
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: matchedRecipes.length,
              itemBuilder: (context, index) {
                // 复用我们强大的共享组件
                return RecipeCard(recipe: matchedRecipes[index]);
              },
            ),
    );
  }
}