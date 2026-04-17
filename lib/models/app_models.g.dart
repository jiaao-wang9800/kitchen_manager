// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IngredientCategoryAdapter extends TypeAdapter<IngredientCategory> {
  @override
  final int typeId = 1;

  @override
  IngredientCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IngredientCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      location: fields[2] as StorageLocation,
    );
  }

  @override
  void write(BinaryWriter writer, IngredientCategory obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.location);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IngredientAdapter extends TypeAdapter<Ingredient> {
  @override
  final int typeId = 2;

  @override
  Ingredient read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Ingredient(
      id: fields[0] as String,
      name: fields[1] as String,
      categoryId: fields[2] as String,
      inStock: fields[3] as bool,
      addedDate: fields[4] as DateTime?,
      expirationDate: fields[5] as DateTime?,
      numericAmount: fields[6] as double?,
      unit: fields[7] as String?,
      dietaryGroup: fields[8] as DietaryGroup?,
      caloriesPer100g: fields[9] as double?,
      proteinPer100g: fields[10] as double?,
      carbsPer100g: fields[11] as double?,
      fatPer100g: fields[12] as double?,
      dietarySubGroup: fields[13] as String?,
      nutritionalTags: (fields[14] as List?)?.cast<String>(),
      isAiAnalyzing: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Ingredient obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.inStock)
      ..writeByte(4)
      ..write(obj.addedDate)
      ..writeByte(5)
      ..write(obj.expirationDate)
      ..writeByte(6)
      ..write(obj.numericAmount)
      ..writeByte(7)
      ..write(obj.unit)
      ..writeByte(8)
      ..write(obj.dietaryGroup)
      ..writeByte(9)
      ..write(obj.caloriesPer100g)
      ..writeByte(10)
      ..write(obj.proteinPer100g)
      ..writeByte(11)
      ..write(obj.carbsPer100g)
      ..writeByte(12)
      ..write(obj.fatPer100g)
      ..writeByte(13)
      ..write(obj.dietarySubGroup)
      ..writeByte(14)
      ..write(obj.nutritionalTags)
      ..writeByte(15)
      ..write(obj.isAiAnalyzing);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecipeCategoryAdapter extends TypeAdapter<RecipeCategory> {
  @override
  final int typeId = 3;

  @override
  RecipeCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecipeCategory(
      id: fields[0] as String,
      name: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RecipeCategory obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecipeAdapter extends TypeAdapter<Recipe> {
  @override
  final int typeId = 4;

  @override
  Recipe read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Recipe(
      id: fields[0] as String,
      name: fields[1] as String,
      ingredients: (fields[2] as List).cast<RecipeIngredient>(),
      steps: (fields[3] as List).cast<String>(),
      imagePath: fields[4] as String?,
      categoryIds: (fields[5] as List).cast<String>(),
      isFavorite: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Recipe obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.ingredients)
      ..writeByte(3)
      ..write(obj.steps)
      ..writeByte(4)
      ..write(obj.imagePath)
      ..writeByte(5)
      ..write(obj.categoryIds)
      ..writeByte(6)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealPlanAdapter extends TypeAdapter<MealPlan> {
  @override
  final int typeId = 6;

  @override
  MealPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealPlan(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      type: fields[2] as MealType,
      recipeId: fields[3] as String,
      isCompleted: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MealPlan obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.recipeId)
      ..writeByte(4)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ShoppingItemAdapter extends TypeAdapter<ShoppingItem> {
  @override
  final int typeId = 7;

  @override
  ShoppingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShoppingItem(
      id: fields[0] as String,
      ingredientId: fields[1] as String,
      isPurchased: fields[2] as bool,
      groupName: fields[3] as String?,
      mealPlanId: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ingredientId)
      ..writeByte(2)
      ..write(obj.isPurchased)
      ..writeByte(3)
      ..write(obj.groupName)
      ..writeByte(4)
      ..write(obj.mealPlanId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecipeIngredientAdapter extends TypeAdapter<RecipeIngredient> {
  @override
  final int typeId = 8;

  @override
  RecipeIngredient read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecipeIngredient(
      ingredientId: fields[0] as String,
      quantity: fields[1] as String?,
      isMain: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RecipeIngredient obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.ingredientId)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.isMain);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIngredientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StorageLocationAdapter extends TypeAdapter<StorageLocation> {
  @override
  final int typeId = 0;

  @override
  StorageLocation read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StorageLocation.fridge;
      case 1:
        return StorageLocation.freezer;
      case 2:
        return StorageLocation.cupboard;
      case 3:
        return StorageLocation.spices;
      default:
        return StorageLocation.fridge;
    }
  }

  @override
  void write(BinaryWriter writer, StorageLocation obj) {
    switch (obj) {
      case StorageLocation.fridge:
        writer.writeByte(0);
        break;
      case StorageLocation.freezer:
        writer.writeByte(1);
        break;
      case StorageLocation.cupboard:
        writer.writeByte(2);
        break;
      case StorageLocation.spices:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DietaryGroupAdapter extends TypeAdapter<DietaryGroup> {
  @override
  final int typeId = 9;

  @override
  DietaryGroup read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DietaryGroup.grains;
      case 1:
        return DietaryGroup.potatoes;
      case 2:
        return DietaryGroup.vegetables;
      case 3:
        return DietaryGroup.fruits;
      case 4:
        return DietaryGroup.meatAndPoultry;
      case 5:
        return DietaryGroup.seafood;
      case 6:
        return DietaryGroup.eggs;
      case 7:
        return DietaryGroup.dairy;
      case 8:
        return DietaryGroup.soy;
      case 9:
        return DietaryGroup.nuts;
      case 10:
        return DietaryGroup.oils;
      case 11:
        return DietaryGroup.saltAndCondiments;
      case 12:
        return DietaryGroup.others;
      default:
        return DietaryGroup.grains;
    }
  }

  @override
  void write(BinaryWriter writer, DietaryGroup obj) {
    switch (obj) {
      case DietaryGroup.grains:
        writer.writeByte(0);
        break;
      case DietaryGroup.potatoes:
        writer.writeByte(1);
        break;
      case DietaryGroup.vegetables:
        writer.writeByte(2);
        break;
      case DietaryGroup.fruits:
        writer.writeByte(3);
        break;
      case DietaryGroup.meatAndPoultry:
        writer.writeByte(4);
        break;
      case DietaryGroup.seafood:
        writer.writeByte(5);
        break;
      case DietaryGroup.eggs:
        writer.writeByte(6);
        break;
      case DietaryGroup.dairy:
        writer.writeByte(7);
        break;
      case DietaryGroup.soy:
        writer.writeByte(8);
        break;
      case DietaryGroup.nuts:
        writer.writeByte(9);
        break;
      case DietaryGroup.oils:
        writer.writeByte(10);
        break;
      case DietaryGroup.saltAndCondiments:
        writer.writeByte(11);
        break;
      case DietaryGroup.others:
        writer.writeByte(12);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DietaryGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealTypeAdapter extends TypeAdapter<MealType> {
  @override
  final int typeId = 5;

  @override
  MealType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MealType.breakfast;
      case 1:
        return MealType.lunch;
      case 2:
        return MealType.dinner;
      default:
        return MealType.breakfast;
    }
  }

  @override
  void write(BinaryWriter writer, MealType obj) {
    switch (obj) {
      case MealType.breakfast:
        writer.writeByte(0);
        break;
      case MealType.lunch:
        writer.writeByte(1);
        break;
      case MealType.dinner:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
