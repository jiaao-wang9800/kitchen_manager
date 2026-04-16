// lib/providers/recipe_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';

// 1. 菜谱分类 Provider
class RecipeCategoryNotifier extends Notifier<List<RecipeCategory>> {
  @override
  List<RecipeCategory> build() => recipeCategoryBox.values.toList();

  void refresh() => state = recipeCategoryBox.values.toList();
}
final recipeCategoryProvider = NotifierProvider<RecipeCategoryNotifier, List<RecipeCategory>>(() => RecipeCategoryNotifier());

// 2. 菜谱列表 Provider
class RecipeNotifier extends Notifier<List<Recipe>> {
  @override
  List<Recipe> build() => recipeBox.values.toList();

  void refresh() {
    state = recipeBox.values.toList();
    syncMemoryWithHive(); // 兼容老代码
  }

  // 切换收藏状态
  Future<void> toggleFavorite(Recipe recipe) async {
    recipe.isFavorite = !recipe.isFavorite;
    await recipe.save();
    refresh(); // 触发 UI 瞬间重绘
  }

  // 添加或更新菜谱
  Future<void> addOrUpdateRecipe(Recipe recipe) async {
    await recipeBox.put(recipe.id, recipe);
    refresh();
  }

  // 删除菜谱
  Future<void> deleteRecipe(Recipe recipe) async {
    await recipe.delete();
    refresh();
  }
}
final recipeProvider = NotifierProvider<RecipeNotifier, List<Recipe>>(() => RecipeNotifier());