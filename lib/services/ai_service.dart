// lib/services/ai_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';
//import 'ai_nutrition_service.dart'; // NEW: Import the nutrition service

class AiService {
  // IMPORTANT: Ensure your actual API key is here
  static const String _apiKey = 'AIzaSyAp0N9lyLfdbZkHPTwfswNeOVybY3M6zOc'; 

  static Future<Recipe?> importRecipeFromAi({String? textContent, List<XFile>? imageFiles}) async {
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

    // ==========================================
    // NEW: Inject user's live physical categories into the prompt
    // ==========================================
    String categoryListStr = allCategories.map((c) => '{"id": "${c.id}", "name": "${c.name}", "location": "${c.location.displayName}"}').join(',\n');

    final prompt = TextPart('''
Analyze the provided text or image to extract recipe information.
Return ONLY a valid JSON object. Do not use Markdown formatting.
Use English keys, but all values MUST be in the original language (e.g., Chinese).

CRITICAL CLASSIFICATION & SORTING RULES:
1. "main_ingredients": This must include core ingredients (meat, vegetables). Include defining spices here if essential.
2. "seasonings": Liquid condiments and everyday spices. Sort by scarcity.
3. Extract the quantity/amount. If not specified, use "适量".
4. "categoryId": For EVERY ingredient and seasoning, you MUST assign the most logical storage category "id" from the user's existing categories below:
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

Required Exact JSON structure:
{
  "name": "Recipe Name Here",
  "main_ingredients": [
    {"name": "Ingredient Name", "amount": "e.g., 500g", "categoryId": "cat_123"}
  ],
  "seasonings": [
    {"name": "Seasoning Name", "amount": "e.g., 1 tbsp", "categoryId": "cat_456"}
  ],
  "steps": ["step 1", "step 2"]
}
''');

    final contentParts = <Part>[prompt];
    
    if (textContent != null && textContent.isNotEmpty) {
      contentParts.add(TextPart(textContent));
    }
    
    if (imageFiles != null && imageFiles.isNotEmpty) {
      for (var file in imageFiles) {
        final bytes = await file.readAsBytes();
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
          String amountStr = (item['amount'] ?? '适量').toString().trim();
          
          if (nameStr.isEmpty) continue;
          
          final existing = myInventory.where((i) => i.name.toLowerCase() == nameStr.toLowerCase()).firstOrNull;
          String ingId;
          
          if (existing != null) {
            ingId = existing.id;
          } else {
            // NEW: Read the smart category ID assigned by AI, fallback to default if it hallucinates
            String aiSuggestedCatId = (item['categoryId'] ?? '').toString();
            bool catExists = allCategories.any((c) => c.id == aiSuggestedCatId);
            String finalCatId = catExists ? aiSuggestedCatId : defaultCategoryId;

            // Create missing ingredient in DB with the SMART category
            final newIng = Ingredient(id: generateId(), name: nameStr, categoryId: finalCatId, inStock: false);
            await inventoryBox.put(newIng.id, newIng);
            
            syncMemoryWithHive(); 
            ingId = newIng.id;

          
          }
          
          if (!addedIngredientIds.contains(ingId)) {
            addedIngredientIds.add(ingId);
            finalRecipeIngredients.add(RecipeIngredient(
              ingredientId: ingId, 
              quantity: amountStr, 
              isMain: isMain
            ));
          }
        }
      }

      await processItems(rawMains, true);
      await processItems(rawSeasonings, false);

      final newRecipe = Recipe(
        id: generateId(),
        name: recipeName,
        ingredients: finalRecipeIngredients, 
        steps: rawSteps.map((s) => s.toString()).toList(),
        categoryIds: [], 
      );
      
      await recipeBox.put(newRecipe.id, newRecipe);
      syncMemoryWithHive();
      
      return newRecipe;

    } catch (e) {
      if (kDebugMode) print('AI Parsing Error: $e'); 
      return null;
    }
  }
}