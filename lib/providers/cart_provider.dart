// lib/providers/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';

class CartNotifier extends Notifier<List<ShoppingItem>> {
  @override
  List<ShoppingItem> build() => shoppingCartBox.values.toList();

  void refresh() => state = shoppingCartBox.values.toList();

  // 核心功能：智能一键将菜谱中缺货的食材加入购物车
  Future<int> addMissingIngredientsForRecipe(Recipe recipe, List<Ingredient> inventory) async {
    int addedCount = 0;
    
    for (var ri in recipe.ingredients) {
      final targetIng = inventory.where((i) => i.id == ri.ingredientId).firstOrNull;
      final inStock = targetIng?.inStock ?? false;
      
      // 如果家里没有这个食材，且购物车里也还没加过
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
    return addedCount; // 返回添加的数量，用于 UI 提示
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<ShoppingItem>>(() => CartNotifier());