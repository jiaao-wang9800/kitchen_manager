// lib/services/ai_receipt_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart'; 
import '../config/api_keys.dart'; 
import '../providers/kitchen_provider.dart'; 
import '../providers/recipe_provider.dart';  

class AiService {
  static const String _apiKey = ApiConfig.openAiKey;

  static Future<Recipe?> importRecipeFromAi({
    String? textContent, 
    List<Uint8List>? imageBytesList, // 🌟 修改这里：直接接收字节列表
    required List<IngredientCategory> allCategories,
    required List<Ingredient> currentInventory,
    required InventoryNotifier inventoryNotifier,
  }) async {
    
    if (_apiKey == 'YOUR_API_KEY_HERE' || _apiKey.isEmpty) {
      if (kDebugMode) print('AI Parsing Error: API Key is missing.');
      return null;
    }

    final model = GenerativeModel(
      model: 'gemini-flash-latest', 
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    String categoryListStr = allCategories.map((c) => '{"id": "${c.id}", "name": "${c.name}", "location": "${c.location.displayName}"}').join(',\n');

    // 🌟 恢复所有你需要的详细营养字段
    final prompt = TextPart('''
Analyze the provided text or image to extract recipe information.
Return ONLY a valid JSON object. Do not use Markdown formatting.
Use English keys, but all values MUST be in the original language (e.g., Chinese).

CRITICAL CLASSIFICATION & SORTING RULES:
1. "main_ingredients": Core ingredients (meat, vegetables). Include defining spices here if essential.
2. "seasonings": Everyday spices.
3. "categoryId": For EVERY ingredient, assign the most logical storage category "id" from the user's existing categories below:
[$categoryListStr]
If nothing matches perfectly, pick the closest logical category. Do NOT make up new IDs.

CRITICAL RULES FOR VALUES:
1. Human-readable text (recipe name, ingredient names, amounts, steps) MUST be in Chinese.

2. System identifiers ("categoryId") MUST strictly use the exact "id" string from the list below. DO NOT translate, modify, or hallucinate the ID.

3. BASE FORM NORMALIZATION: When extracting ingredient names, you MUST strip away any preparation states, cuts, or physical forms (e.g., 末, 丝, 片, 丁, 块, 花, 碎). Return ONLY the base ingredient name.

Examples:

- "蒜末" -> "大蒜" (or "蒜")

- "姜丝" -> "生姜" (or "姜")

- "葱花" -> "葱"

- "土豆块" -> "土豆"

- "五花肉片" -> "五花肉"

- "鸡蛋液" -> "鸡蛋"
For EACH ingredient, provide these exact fields:

1. "name": Standardized base name in Chinese. STRIP all adjectives, brand names, and state modifiers (e.g., "土", "有机", "新鲜", "冷冻", "特级", "野生").

Example: "土鸡" MUST become "鸡", "野生土鸡翅" MUST become "鸡翅", "冷冻猪里脊肉" MUST become "猪里脊肉". Retain essential culinary parts (e.g., wings, breast, ribs).

2. "amount": Numeric quantity matching the unit rules (Use double).

3. "unit": Strictly "g", "ml", or "个".

4. "categoryId": The id from the provided categories list.

5. "group": Exactly ONE of: [grains, potatoes, vegetables, fruits, meatAndPoultry, seafood, eggs, dairy, soy, nuts, oils, saltAndCondiments, others]

6. "subGroup": Specific sub-category in Chinese (e.g., "深色蔬菜").

7. "cal": Calories per 100g (double).

8. "pro": Protein per 100g (double).

9. "carb": Carbs per 100g (double).

10. "fat": Fat per 100g (double).

11. "tags": Array of 1-3 short Chinese health benefits (e.g., ["高蛋白"]).

Required Exact JSON structure:
{
  "name": "Recipe Name Here",
  "main_ingredients": [
    {
      "name": "Ingredient Name", 
      "amount": 500.0, 
      "unit": "g",
      "categoryId": "cat_123",
      "group": "meatAndPoultry",
      "subGroup": "猪肉",
      "cal": 143.0,
      "pro": 20.0,
      "carb": 0.0,
      "fat": 7.0,
      "tags": ["高蛋白", "富含铁"]
    }
  ],
  "seasonings": [
    {
      "name": "Seasoning Name", 
      "amount": 1.0, 
      "unit": "勺",
      "categoryId": "cat_456",
      "group": "saltAndCondiments",
      "subGroup": "调味汁",
      "cal": 15.0,
      "pro": 0.5,
      "carb": 1.0,
      "fat": 0.0,
      "tags": ["高蛋白", "低脂肪"]

    }
  ],
  "steps": ["step 1", "step 2"]
}
''');

    final contentParts = <Part>[prompt];

    if (textContent != null && textContent.isNotEmpty) contentParts.add(TextPart(textContent));

    // 🌟 修改这里：直接处理字节，不再需要 await file.readAsBytes()
    if (imageBytesList != null && imageBytesList.isNotEmpty) {
      for (var bytes in imageBytesList) {
        contentParts.add(DataPart('image/jpeg', bytes));
      }
    }

    try {
      final response = await model.generateContent([Content.multi(contentParts)]);
      final String? responseText = response.text?.trim();
      
      if (responseText == null || responseText.isEmpty) return null;

      final Map<String, dynamic> data = jsonDecode(responseText);
      final String recipeName = data['name'] ?? 'AI Imported Recipe';
      
      final List<dynamic> rawMains = data['main_ingredients'] is List ? data['main_ingredients'] : [];
      final List<dynamic> rawSeasonings = data['seasonings'] is List ? data['seasonings'] : [];
      final List<dynamic> rawSteps = data['steps'] is List ? data['steps'] : [];

      List<RecipeIngredient> finalRecipeIngredients = [];
      String defaultCategoryId = allCategories.isNotEmpty ? allCategories.first.id : 'default';
      Set<String> addedIngredientIds = {}; 

      Future<void> processItems(List<dynamic> items, bool isMain) async {
        for (var item in items) {
          if (item is! Map) continue;
          String nameStr = (item['name'] ?? '').toString().trim();
          
          if (nameStr.isEmpty) continue;
          
          // 解析数量和单位，用于菜谱展示 (例如: "500g")
          double? parsedAmount = (item['amount'] as num?)?.toDouble();
          String parsedUnit = (item['unit'] ?? '').toString();
          String displayQuantity = parsedAmount != null ? '${parsedAmount == parsedAmount.truncateToDouble() ? parsedAmount.toInt() : parsedAmount}$parsedUnit' : '适量';
          
          final existing = currentInventory.where((i) => i.name.toLowerCase() == nameStr.toLowerCase()).firstOrNull;
          String ingId;

          // 🌟 提取全部营养大礼包
          DietaryGroup? parsedGroup = _parseDietaryGroup(item['group']?.toString());
          String? parsedSubGroup = item['subGroup']?.toString();
          double? parsedCal = (item['cal'] as num?)?.toDouble();
          double? parsedPro = (item['pro'] as num?)?.toDouble();
          double? parsedCarb = (item['carb'] as num?)?.toDouble();
          double? parsedFat = (item['fat'] as num?)?.toDouble();
          List<String> parsedTags = List<String>.from(item['tags'] ?? []);
          
          if (existing != null) {
            ingId = existing.id;
            // 如果已有食材没有营养信息，趁机补全三大营养素！
            if (existing.dietaryGroup == null || existing.caloriesPer100g == null) {
              existing.dietaryGroup = parsedGroup;
              existing.dietarySubGroup = parsedSubGroup;
              existing.caloriesPer100g = parsedCal;
              existing.proteinPer100g = parsedPro;
              existing.carbsPer100g = parsedCarb;
              existing.fatPer100g = parsedFat;
              existing.nutritionalTags = parsedTags;
              await inventoryNotifier.addOrUpdateIngredient(existing);
            }
          } else {
            // 库里没有，直接带着所有的宏量营养素新建
            String aiSuggestedCatId = (item['categoryId'] ?? '').toString();
            bool catExists = allCategories.any((c) => c.id == aiSuggestedCatId);
            String finalCatId = catExists ? aiSuggestedCatId : defaultCategoryId;

            final newIng = Ingredient(
              id: generateId(), 
              name: nameStr, 
              categoryId: finalCatId, 
              inStock: false, 
              unit: parsedUnit.isNotEmpty ? parsedUnit : null, // 存入单位
              dietaryGroup: parsedGroup,
              dietarySubGroup: parsedSubGroup,
              caloriesPer100g: parsedCal,
              proteinPer100g: parsedPro,
              carbsPer100g: parsedCarb,
              fatPer100g: parsedFat,
              nutritionalTags: parsedTags,
              isAiAnalyzing: false,
            );
            await inventoryNotifier.addOrUpdateIngredient(newIng);
            ingId = newIng.id;
          }
          
          if (!addedIngredientIds.contains(ingId)) {
            addedIngredientIds.add(ingId);
            finalRecipeIngredients.add(RecipeIngredient(
              ingredientId: ingId, 
              quantity: displayQuantity, // 例如 "500g" 或 "适量"
              isMain: isMain
            ));
          }
        }
      }

      await processItems(rawMains, true);
      await processItems(rawSeasonings, false);

      return Recipe(
        id: generateId(),
        name: recipeName,
        ingredients: finalRecipeIngredients, 
        steps: rawSteps.map((s) => s.toString()).toList(),
        categoryIds: [], 
      );

    } catch (e) {
      if (kDebugMode) print('AI Parsing Error: $e'); 
      return null;
    }
  }

  static DietaryGroup? _parseDietaryGroup(String? groupStr) {
    if (groupStr == null) return null;
    return DietaryGroup.values.firstWhere(
      (v) => v.name == groupStr, 
      orElse: () => DietaryGroup.others
    );
  }
}