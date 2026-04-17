// lib/providers/kitchen_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';
import '../services/ai_nutrition_service.dart';

// 管理分类状态
class CategoryNotifier extends Notifier<List<IngredientCategory>> {
  @override
  List<IngredientCategory> build() => categoryBox.values.toList();

  void refresh() => state = categoryBox.values.toList();
}
final categoryProvider = NotifierProvider<CategoryNotifier, List<IngredientCategory>>(() => CategoryNotifier());

// 管理食材库存状态
class InventoryNotifier extends Notifier<List<Ingredient>> {
  @override
  List<Ingredient> build() {
    return inventoryBox.values.toList();
  }

  // 刷新 UI
  void refresh() {
    state = inventoryBox.values.toList();
    // 顺便更新旧的全局变量，防止其他尚未迁移的页面报错
    syncMemoryWithHive(); 
  }

  // 增/改食材
  Future<void> addOrUpdateIngredient(Ingredient ingredient) async {
    await inventoryBox.put(ingredient.id, ingredient);
    refresh();
  }

  // 彻底删除食材
  Future<void> deleteIngredient(Ingredient ingredient) async {
    await ingredient.delete();
    refresh();
  }

  // 消耗食材 (标记为缺货并放入购物车)
  Future<void> consumeIngredient(Ingredient ingredient, {bool addToCart = false}) async {
    ingredient.inStock = false;
    await ingredient.save();
    
    if (addToCart) {
      final shoppingItem = ShoppingItem(
        id: generateId(), 
        ingredientId: ingredient.id, 
        groupName: 'Restock'
      );
      await shoppingCartBox.put(shoppingItem.id, shoppingItem);
    }
    refresh();
  }

  Future<int> batchAnalyzeNutrition() async {
    // 1. 找出所有还没有膳食分类的食材
    final needsAnalysis = state.where((ing) => ing.dietaryGroup == null).toList();
    if (needsAnalysis.isEmpty) return 0; // 如果都分析过了，直接返回 0

    // 2. 开启 Loading 状态 (通知 UI 转圈圈)
    for (var ing in needsAnalysis) {
      ing.isAiAnalyzing = true;
    }
    state = [...state]; // 触发 UI 刷新

    try {
      // 3. 提取名字，发送给 AI 服务
      final namesToAnalyze = needsAnalysis.map((i) => i.name).toList();
      final results = await AiNutritionService.batchAnalyzeIngredients(namesToAnalyze);

      // 4. 将 AI 结果写入实体并保存到 Hive
      for (var ing in needsAnalysis) {
        ing.isAiAnalyzing = false;
        if (results.containsKey(ing.name)) {
          final data = results[ing.name];
          ing.dietaryGroup = data['group'];
          ing.caloriesPer100g = data['cal'];
          ing.nutritionalTags = data['tags'];
        }
        await inventoryBox.put(ing.id, ing);
      }
      
      // 5. 更新全局状态
      state = inventoryBox.values.toList();
      return needsAnalysis.length;

    } catch (e) {
      // 失败了也要把转圈圈关掉
      for (var ing in needsAnalysis) {
        ing.isAiAnalyzing = false;
      }
      state = [...state];
      throw Exception('AI Analysis Failed: $e');
    }
  }
}
final inventoryProvider = NotifierProvider<InventoryNotifier, List<Ingredient>>(() {
  return InventoryNotifier();
});