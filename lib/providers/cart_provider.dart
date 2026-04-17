// lib/providers/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart'; // 仅用于 generateId

class CartNotifier extends Notifier<List<ShoppingItem>> {
  @override
  List<ShoppingItem> build() => shoppingCartBox.values.toList();

  void refresh() => state = shoppingCartBox.values.toList();

  // 添加或更新单项
  Future<void> addOrUpdateItem(ShoppingItem item) async {
    await shoppingCartBox.put(item.id, item);
    refresh();
  }

  // 删除单项
  Future<void> deleteItem(ShoppingItem item) async {
    await item.delete();
    refresh();
  }

  // 一键清空已购物品
  Future<void> clearPurchased() async {
    final purchasedItems = state.where((item) => item.isPurchased).toList();
    for (var item in purchasedItems) {
      await item.delete();
    }
    refresh();
  }

  // 智能一键将菜谱中缺货的食材加入购物车
  Future<int> addMissingIngredientsForRecipe(Recipe recipe, List<Ingredient> inventory) async {
    int addedCount = 0;
    for (var ri in recipe.ingredients) {
      final targetIng = inventory.where((i) => i.id == ri.ingredientId).firstOrNull;
      final inStock = targetIng?.inStock ?? false;
      if (!inStock) {
        final alreadyInCart = state.any((item) => item.ingredientId == ri.ingredientId && !item.isPurchased);
        if (!alreadyInCart) {
          final newItem = ShoppingItem(
            id: '${generateId()}_${ri.ingredientId}',
            ingredientId: ri.ingredientId,
            groupName: '🛒 菜谱补货: ${recipe.name}',
          );
          await shoppingCartBox.put(newItem.id, newItem);
          addedCount++;
        }
      }
    }
    refresh();
    return addedCount;
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<ShoppingItem>>(() => CartNotifier());