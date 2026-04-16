// lib/providers/kitchen_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';

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
}
final inventoryProvider = NotifierProvider<InventoryNotifier, List<Ingredient>>(() {
  return InventoryNotifier();
});