// lib/models/app_models.dart
import 'package:hive/hive.dart';

// IMPORTANT: This line connects to the auto-generated database file we will create next.
// It will show a red error for now, which is completely normal!
part 'app_models.g.dart'; 

@HiveType(typeId: 0)
enum StorageLocation {
  @HiveField(0) fridge,
  @HiveField(1) freezer,
  @HiveField(2) cupboard,
  @HiveField(3) spices
}

extension StorageLocationExtension on StorageLocation {
  String get displayName {
    switch (this) {
      case StorageLocation.fridge: return 'Fridge';
      case StorageLocation.freezer: return 'Freezer';
      case StorageLocation.cupboard: return 'Cupboard';
      case StorageLocation.spices: return 'Spices';
    }
  }
}

@HiveType(typeId: 1)
class IngredientCategory extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) StorageLocation location;
  
  IngredientCategory({required this.id, required this.name, required this.location});
}

// NEW: Granular Dietary classification based on the 2023 Chinese Dietary Guidelines
@HiveType(typeId: 9)
enum DietaryGroup {
  @HiveField(0) grains,              
  @HiveField(1) potatoes,            
  @HiveField(2) vegetables,          
  @HiveField(3) fruits,              
  @HiveField(4) meatAndPoultry,      
  @HiveField(5) seafood,             
  @HiveField(6) eggs,                
  @HiveField(7) dairy,               
  @HiveField(8) soy,                 
  @HiveField(9) nuts,                
  @HiveField(10) oils,               
  @HiveField(11) saltAndCondiments,  
  @HiveField(12) others              
}

extension DietaryGroupExtension on DietaryGroup {
  // Used for displaying the small tag in the UI
  String get displayName {
    switch (this) {
      case DietaryGroup.grains: return '谷类';
      case DietaryGroup.potatoes: return '薯类';
      case DietaryGroup.vegetables: return '蔬菜';
      case DietaryGroup.fruits: return '水果';
      case DietaryGroup.meatAndPoultry: return '肉禽类';
      case DietaryGroup.seafood: return '水产品';
      case DietaryGroup.eggs: return '蛋类';
      case DietaryGroup.dairy: return '奶制品';
      case DietaryGroup.soy: return '大豆及制品';
      case DietaryGroup.nuts: return '坚果类';
      case DietaryGroup.oils: return '油';
      case DietaryGroup.saltAndCondiments: return '盐';
      case DietaryGroup.others: return '其他';
    }
  }
}


@HiveType(typeId: 2)
class Ingredient extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String categoryId;
  @HiveField(3) bool inStock;
  @HiveField(4) DateTime addedDate;
  @HiveField(5) DateTime? expirationDate;
  @HiveField(6) double? numericAmount; 
  @HiveField(7) String? unit; 

  // Nutritional Attributes
  @HiveField(8) DietaryGroup? dietaryGroup; 
  
  // Macronutrients (Values per 100g or 100ml)
  @HiveField(9) double? caloriesPer100g; 
  @HiveField(10) double? proteinPer100g; 
  @HiveField(11) double? carbsPer100g;   
  @HiveField(12) double? fatPer100g;     

  // NEW: Flexible sub-category (e.g., "全谷物", "深色蔬菜")
  @HiveField(13) String? dietarySubGroup;

  // Dynamic tags for micronutrients or special features (e.g., "Rich in Iron", "High Fiber")
  @HiveField(14) List<String>? nutritionalTags;

  // Flag to indicate if AI is currently analyzing this ingredient
  @HiveField(15) bool isAiAnalyzing; 

  Ingredient({
    required this.id, 
    required this.name, 
    required this.categoryId, 
    this.inStock = true,
    DateTime? addedDate,
    this.expirationDate,
    this.numericAmount,
    this.unit,
    this.dietaryGroup,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.dietarySubGroup,
    this.nutritionalTags,
    this.isAiAnalyzing = false, 
  }) : addedDate = addedDate ?? DateTime.now();
}
@HiveType(typeId: 3)
class RecipeCategory extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  
  RecipeCategory({required this.id, required this.name});
}

@HiveType(typeId: 4)
class Recipe extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  
  @HiveField(2) List<RecipeIngredient> ingredients; 
  
  @HiveField(3) List<String> steps;
  @HiveField(4) String? imagePath;
  @HiveField(5) List<String> categoryIds;
  @HiveField(6) bool isFavorite;
  

  Recipe({
    required this.id, 
    required this.name, 
    required this.ingredients, 
    this.steps = const [], 
    this.imagePath, 
    this.categoryIds = const [],
    this.isFavorite = false, 
  });
}

@HiveType(typeId: 5)
enum MealType {
  @HiveField(0) breakfast,
  @HiveField(1) lunch,
  @HiveField(2) dinner
}

extension MealTypeExtension on MealType {
  String get displayName {
    switch (this) {
      case MealType.breakfast: return 'Breakfast';
      case MealType.lunch: return 'Lunch';
      case MealType.dinner: return 'Dinner';
    }
  }
}

@HiveType(typeId: 6)
class MealPlan extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) DateTime date;
  @HiveField(2) MealType type;
  @HiveField(3) String recipeId;
  @HiveField(4) bool isCompleted;
  
  MealPlan({required this.id, required this.date, required this.type, required this.recipeId, this.isCompleted = false});
}

@HiveType(typeId: 7)
class ShoppingItem extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String ingredientId; 
  @HiveField(2) bool isPurchased;
  @HiveField(3) String? groupName; 
  @HiveField(4) String? mealPlanId; 

  ShoppingItem({
    required this.id, 
    required this.ingredientId, 
    this.isPurchased = false, 
    this.groupName,
    this.mealPlanId, 
  });
}

@HiveType(typeId: 8)
class RecipeIngredient extends HiveObject {
  @HiveField(0) String ingredientId; 
  @HiveField(1) String? quantity;    
  @HiveField(2) bool isMain;         

  RecipeIngredient({
    required this.ingredientId,
    this.quantity,
    this.isMain = true,
  });
}
