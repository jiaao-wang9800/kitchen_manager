// lib/screens/recipe_category_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart'; // 仅用于 generateId()
import '../providers/recipe_provider.dart';

class RecipeCategoryManagerScreen extends ConsumerStatefulWidget {
  const RecipeCategoryManagerScreen({super.key});
  @override
  ConsumerState<RecipeCategoryManagerScreen> createState() => _RecipeCategoryManagerScreenState();
}

class _RecipeCategoryManagerScreenState extends ConsumerState<RecipeCategoryManagerScreen> {
  void _showCategoryDialog({RecipeCategory? existingCategory}) {
    final bool isEdit = existingCategory != null;
    final nameController = TextEditingController(text: isEdit ? existingCategory.name : '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Tag' : 'New Tag'),
          content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tag Name (e.g. Spicy, Vegan)')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                if (isEdit) { 
                  existingCategory.name = nameController.text; 
                  await existingCategory.save(); 
                } 
                else { 
                  final newCat = RecipeCategory(id: generateId(), name: nameController.text); 
                  await recipeCategoryBox.put(newCat.id, newCat); // 兼容原代码，直接入库
                }
                ref.read(recipeCategoryProvider.notifier).refresh(); // 通知 UI 刷新
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(RecipeCategory category) async {
    await category.delete(); 
    final allRecipes = ref.read(recipeProvider);
    for (var recipe in allRecipes) { 
      if (recipe.categoryIds.contains(category.id)) { 
        recipe.categoryIds.remove(category.id); 
        await recipe.save(); 
      } 
    }
    ref.read(recipeCategoryProvider.notifier).refresh(); 
    ref.read(recipeProvider.notifier).refresh(); 
  }

  @override
  Widget build(BuildContext context) {
    final allRecipeCategories = ref.watch(recipeCategoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Recipe Tags')),
      body: ListView.builder(
        itemCount: allRecipeCategories.length,
        itemBuilder: (context, index) {
          final cat = allRecipeCategories[index];
          return ListTile(
            leading: const Icon(Icons.label), title: Text(cat.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showCategoryDialog(existingCategory: cat)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCategory(cat)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showCategoryDialog(), child: const Icon(Icons.add)),
    );
  }
}