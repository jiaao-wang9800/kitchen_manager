import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart'; // 暂时引入旧的数据库文件以兼容现有数据

class DatabaseService {
  static Future<void> init() async {
    try {
      // 1. 初始化 Hive 引擎
      await Hive.initFlutter();

      // 2. 注册所有的 TypeAdapters
      Hive.registerAdapter(StorageLocationAdapter());
      Hive.registerAdapter(IngredientCategoryAdapter());
      Hive.registerAdapter(IngredientAdapter());
      Hive.registerAdapter(RecipeCategoryAdapter());
      Hive.registerAdapter(RecipeAdapter());
      Hive.registerAdapter(MealTypeAdapter());
      Hive.registerAdapter(MealPlanAdapter());
      Hive.registerAdapter(ShoppingItemAdapter());
      Hive.registerAdapter(RecipeIngredientAdapter());

      // 3. 执行旧版的数据打开和填充逻辑 (现在它是被安全包裹的)
      await initDatabase();

      // [可选] 增加一点点人为延迟，让你的星露谷加载屏能展示一下，防止画面闪烁
      await Future.delayed(const Duration(milliseconds: 800));
      
    } catch (e, stackTrace) {
      // 捕获到任何错误都不会直接白屏崩溃，而是将错误抛给 UI 层展示
      throw Exception("本地数据库初始化失败: $e");
    }
  }
}