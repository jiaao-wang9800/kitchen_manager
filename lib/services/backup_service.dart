// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // 🌟 新增：处理字节流
import 'package:flutter/foundation.dart' show kIsWeb; // 🌟 新增：判断是否在 Web 端
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/mock_database.dart';
import '../models/app_models.dart';

class BackupService {
  /// Exports all Hive data into a single JSON file and triggers the system share sheet or Web download.
  static Future<void> exportAllData() async {
    try {
      // 1. 直接从底层的 Hive Box 收集所有数据
      final data = {
        'ingredients': inventoryBox.values.map((e) => _ingredientToJson(e)).toList(),
        'categories': categoryBox.values.map((e) => _categoryToJson(e)).toList(), 
        'recipes': recipeBox.values.map((e) => _recipeToJson(e)).toList(),
        'shopping_items': shoppingCartBox.values.map((e) => _shoppingItemToJson(e)).toList(),
        'meal_plans': mealPlanBox.values.map((e) => _mealPlanToJson(e)).toList(),
        'export_date': DateTime.now().toIso8601String(),
      };

      // 2. 转换为 JSON 字符串
      String jsonString = jsonEncode(data);

      // 🌟 3. 跨平台分叉处理
      if (kIsWeb) {
        // 【Web 端逻辑】：将字符串转为二进制字节，利用 XFile 触发浏览器的直接下载行为
        final bytes = utf8.encode(jsonString);
        final xFile = XFile.fromData(
          Uint8List.fromList(bytes), 
          name: 'my_kitchen_backup.json', 
          mimeType: 'application/json'
        );
        // 在 Web 上调用 saveTo 会自动生成一个虚拟的下载链接并触发浏览器的下载弹窗
        await xFile.saveTo('my_kitchen_backup.json');
        
      } else {
        // 【移动端逻辑 (iOS/Android)】：保存到本地临时目录，唤起系统分享面板
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/my_kitchen_backup.json');
        await file.writeAsString(jsonString);

        await Share.shareXFiles([XFile(file.path)], text: 'My Kitchen App Data Backup');
      }
      
    } catch (e) {
      print('Export Error: $e');
    }
  }

  // --- Helper methods to convert models to JSON-ready maps ---

  static Map<String, dynamic> _ingredientToJson(Ingredient ing) => {
    'id': ing.id,
    'name': ing.name,
    'categoryId': ing.categoryId,
    'inStock': ing.inStock,
    'addedDate': ing.addedDate.toIso8601String(),
    'expirationDate': ing.expirationDate?.toIso8601String(),
    'numericAmount': ing.numericAmount,
    'unit': ing.unit,
    'dietaryGroup': ing.dietaryGroup?.name,
    'cal': ing.caloriesPer100g,
    'pro': ing.proteinPer100g,
    'carb': ing.carbsPer100g,
    'fat': ing.fatPer100g,
    'tags': ing.nutritionalTags,
  };

  static Map<String, dynamic> _categoryToJson(IngredientCategory cat) => {
    'id': cat.id,
    'name': cat.name,
    'location': cat.location.name,
  };

  static Map<String, dynamic> _recipeToJson(Recipe rec) => {
    'id': rec.id,
    'name': rec.name,
    'steps': rec.steps,
    'categoryIds': rec.categoryIds,
    'ingredients': rec.ingredients.map((ri) => {
      'ingredientId': ri.ingredientId,
      'quantity': ri.quantity,
      'isMain': ri.isMain,
    }).toList(),
  };

  static Map<String, dynamic> _shoppingItemToJson(ShoppingItem item) => {
    'id': item.id,
    'ingredientId': item.ingredientId,
    'isPurchased': item.isPurchased,
    'groupName': item.groupName,
  };

  static Map<String, dynamic> _mealPlanToJson(MealPlan plan) => {
    'id': plan.id,
    'date': plan.date.toIso8601String(),
    'type': plan.type.name,
    'recipeId': plan.recipeId,
  };
}