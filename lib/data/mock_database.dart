// lib/data/mock_database.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_models.dart';
import 'my_initial_inventory.dart';

// Global variables for UI to read from (Memory Cache)
List<IngredientCategory> allCategories = [];
List<Ingredient> myInventory = [];
List<RecipeCategory> allRecipeCategories = [];
List<Recipe> allRecipes = [];
List<MealPlan> myMealPlans = [];
List<ShoppingItem> myShoppingCart = [];

// Hive Database Boxes (The actual Hard Drive files)
late Box<IngredientCategory> categoryBox;
late Box<Ingredient> inventoryBox;
late Box<RecipeCategory> recipeCategoryBox;
late Box<Recipe> recipeBox;
late Box<MealPlan> mealPlanBox;
late Box<ShoppingItem> shoppingCartBox;

// Initialize Database on App Startup
Future<void> initDatabase() async {
  categoryBox = await Hive.openBox<IngredientCategory>('categories');
  inventoryBox = await Hive.openBox<Ingredient>('inventory');
  recipeCategoryBox = await Hive.openBox<RecipeCategory>('recipeCategories');
  recipeBox = await Hive.openBox<Recipe>('recipes');
  mealPlanBox = await Hive.openBox<MealPlan>('mealPlans');
  shoppingCartBox = await Hive.openBox<ShoppingItem>('shoppingCart');

  if (categoryBox.isEmpty) {
    await _seedInitialData();
  }

  syncMemoryWithHive();
}

void syncMemoryWithHive() {
  allCategories = categoryBox.values.toList();
  myInventory = inventoryBox.values.toList();
  allRecipeCategories = recipeCategoryBox.values.toList();
  allRecipes = recipeBox.values.toList();
  myMealPlans = mealPlanBox.values.toList();
  myShoppingCart = shoppingCartBox.values.toList();
}

Future<void> _seedInitialData() async {
  final defaultCategories = [
    IngredientCategory(id: 'cat_f1', name: '鲜肉', location: StorageLocation.fridge),
    IngredientCategory(id: 'cat_f2', name: '鸡蛋&乳制品', location: StorageLocation.fridge),
    IngredientCategory(id: 'cat_f3', name: '蔬菜', location: StorageLocation.fridge),
    IngredientCategory(id: 'cat_f4', name: '葱姜蒜', location: StorageLocation.fridge),
    IngredientCategory(id: 'cat_fz1', name: '快手早餐', location: StorageLocation.freezer),
    IngredientCategory(id: 'cat_fz2', name: '丸子', location: StorageLocation.freezer),
    IngredientCategory(id: 'cat_fz3', name: '海鲜', location: StorageLocation.freezer),
    IngredientCategory(id: 'cat_fz4', name: '冻肉', location: StorageLocation.freezer),
    IngredientCategory(id: 'cat_c1', name: '米', location: StorageLocation.cupboard),
    IngredientCategory(id: 'cat_c2', name: '面', location: StorageLocation.cupboard),
    IngredientCategory(id: 'cat_c3', name: '粉', location: StorageLocation.cupboard),
    IngredientCategory(id: 'cat_c4', name: '粗粮', location: StorageLocation.cupboard),
    IngredientCategory(id: 'cat_c5', name: '豆类', location: StorageLocation.cupboard),
    IngredientCategory(id: 'cat_c6', name: '干货', location: StorageLocation.cupboard),
    IngredientCategory(id: 'cat_c7', name: '罐头', location: StorageLocation.cupboard),
    IngredientCategory(id: 'cat_s1', name: '香料', location: StorageLocation.spices),
    IngredientCategory(id: 'cat_s2', name: '食用油', location: StorageLocation.spices),
    IngredientCategory(id: 'cat_s3', name: '基础调味料', location: StorageLocation.spices),
    IngredientCategory(id: 'cat_s4', name: '复合调味包', location: StorageLocation.spices),
    IngredientCategory(id: 'cat_p1', name: '果汁饮料', location: StorageLocation.pantry),
    IngredientCategory(id: 'cat_p2', name: '茶/咖啡', location: StorageLocation.pantry),
    IngredientCategory(id: 'cat_p3', name: '坚果', location: StorageLocation.pantry),
    IngredientCategory(id: 'cat_p4', name: '甜品', location: StorageLocation.pantry),

  ];

  for (var cat in defaultCategories) {
    await categoryBox.put(cat.id, cat);
  }
// ... (previous code remains the same)

  final rc1 = RecipeCategory(id: 'rc1', name: '家常菜');
  await recipeCategoryBox.put(rc1.id, rc1);

  // CHANGED: Added mock nutritional data and dynamic tags to test our new Data Model
  final ing1 = Ingredient(
    id: 'ing_jichi', 
    name: '鸡翅', 
    categoryId: 'cat_f1', 
    inStock: false, 
    numericAmount: 0.0, 
    unit: 'g',
    dietaryGroup: DietaryGroup.meatAndPoultry, // 肉禽类
    dietarySubGroup: '白肉',
    caloriesPer100g: 202.0,
    proteinPer100g: 17.4,
    carbsPer100g: 0.0,
    fatPer100g: 14.8,
    nutritionalTags: ['优质蛋白', '含较高脂肪'],
  );
  
  final ing2 = Ingredient(
    id: 'ing_kele', 
    name: '可乐', 
    categoryId: 'cat_c1', 
    inStock: false, 
    numericAmount: 0.0, 
    unit: 'ml',
    dietaryGroup: DietaryGroup.others, // 其他
    dietarySubGroup: '含糖饮料',
    caloriesPer100g: 43.0,
    proteinPer100g: 0.0,
    carbsPer100g: 10.6,
    fatPer100g: 0.0,
    nutritionalTags: ['高添加糖', '空热量'],
  );
  
  await inventoryBox.putAll({ing1.id: ing1, ing2.id: ing2});

  // ... (rest of the code remains the same)
  // UPDATED: Use the new RecipeIngredient structure
  final defaultRecipe = Recipe(
    id: 'rec_1',
    name: '可乐鸡翅',
    ingredients: [
      RecipeIngredient(ingredientId: ing1.id, quantity: '500g', isMain: true),
      RecipeIngredient(ingredientId: ing2.id, quantity: '1罐', isMain: false),
    ], 
    steps: [
      '鸡翅洗净划刀，冷水下锅加葱姜焯水，捞出洗净沥干。',
      '锅中倒少许油，将鸡翅煎至两面金黄。',
      '加入生抽、老抽、料酒翻炒上色。',
      '倒入一罐可乐，没过鸡翅，大火烧开后转中小火炖煮20分钟。',
      '最后大火收汁，撒上白芝麻即可出锅。'
    ],
    categoryIds: [rc1.id], 
    isFavorite: true,      
  );

  await recipeBox.put(defaultRecipe.id, defaultRecipe);

  // =====================================
  // 🌟 2. 在这里加上：灌入你的私人初始食材！
  // =====================================
  for (var item in myInitialInventory) {
    
    // 检查：遍历当前数据库里的所有食材，看看有没有名字一模一样的
    bool alreadyHasSameName = inventoryBox.values.any((existing) => existing.name == item.name);
    
    // 只有当数据库里“没有这个名字”的食材时，我才加进去
    if (!alreadyHasSameName) {
      await inventoryBox.put(item.id, item);
    }
  }
}

  // 顺便更新旧的全局变量，防止其他尚未迁移的页面报错

String generateId() => DateTime.now().millisecondsSinceEpoch.toString();

Future<void> syncMealPlansToCart(List<String> targetMealPlanIds) async {
  syncMemoryWithHive();
  
  final existingAutoItems = shoppingCartBox.values.where((item) => item.mealPlanId != null).toList();
  
  for (var item in existingAutoItems) {
    if (!targetMealPlanIds.contains(item.mealPlanId)) {
      await item.delete();
    }
  }

  for (String planId in targetMealPlanIds) {
    final plan = mealPlanBox.get(planId);
    if (plan == null) continue;

    final recipe = recipeBox.get(plan.recipeId);
    if (recipe == null) continue;

    // UPDATED: Iterate over RecipeIngredient objects instead of plain Strings
    for (RecipeIngredient recIng in recipe.ingredients) {
      final String ingId = recIng.ingredientId;
      final ingredient = inventoryBox.get(ingId);
      
      if (ingredient == null || ingredient.inStock) continue;

      bool alreadyInCart = shoppingCartBox.values.any((item) => 
        item.ingredientId == ingId && !item.isPurchased
      );

      if (!alreadyInCart) {
        final newItem = ShoppingItem(
          id: '${generateId()}_$ingId', 
          ingredientId: ingId,
          mealPlanId: planId,
          groupName: '📅 计划: ${recipe.name}', 
        );
        await shoppingCartBox.put(newItem.id, newItem);
      }
    }
  }

  syncMemoryWithHive();
}