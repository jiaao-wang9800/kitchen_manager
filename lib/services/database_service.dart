// lib/services/database_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart'; 

class DatabaseService {
  static Future<void> init() async {
    try {
      // 1. 初始化 Hive 引擎
      await Hive.initFlutter();

      // 2. 安全注册 TypeAdapters (防止“重新启动”时重复注册导致红屏崩溃)
      // 我们用 typeId 0 (StorageLocationAdapter) 作为检查基准
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(StorageLocationAdapter());
        Hive.registerAdapter(IngredientCategoryAdapter());
        Hive.registerAdapter(IngredientAdapter());
        Hive.registerAdapter(RecipeCategoryAdapter());
        Hive.registerAdapter(RecipeAdapter());
        Hive.registerAdapter(MealTypeAdapter());
        Hive.registerAdapter(MealPlanAdapter());
        Hive.registerAdapter(ShoppingItemAdapter());
        Hive.registerAdapter(RecipeIngredientAdapter());
        Hive.registerAdapter(DietaryGroupAdapter());
      }

      // 3. 执行旧版的数据打开和填充逻辑 (被安全包裹)
      await initDatabase();


    } catch (e, stackTrace) {
      // 捕获到任何错误抛给 UI 层展示，不会直接死锁白屏
      throw Exception("本地数据库初始化失败: $e");
    }
  }
}