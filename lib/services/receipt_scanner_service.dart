// lib/services/receipt_scanner_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/app_models.dart';
import '../config/api_keys.dart'; // 导入你的私人配置


class ReceiptScannerService {

static const String _apiKey = ApiConfig.openAiKey;

  // 🌟 NEW: Added `categories` parameter so AI knows our actual kitchen layout
  static Future<List<Map<String, dynamic>>> scanGroceries(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
    required List<IngredientCategory> categories, 
  }) async {
    List<Map<String, dynamic>> parsedItems = [];
    
    if (_apiKey.isEmpty) {
      if (kDebugMode) print('Receipt Scanner Error: API Key is missing.');
      return parsedItems;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest', 
        apiKey: _apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );

      // 🌟 NEW: Convert our dynamic categories into a string for the prompt
      String categoriesJson = categories.map((c) => '{"id": "${c.id}", "name": "${c.name}", "location": "${c.location.displayName}"}').join(',\n');

      // 🌟 UPDATED PROMPT: Added strict normalization rules for ingredient names
      final prompt = TextPart('''
You are an expert AI Grocery Assistant. Analyze the provided image (receipt or groceries).
Extract the food items and return ONLY a valid JSON ARRAY of objects. 
Do NOT use Markdown formatting. All descriptive string values must be in Chinese.

CRITICAL RULES:
A. "unit" MUST be exactly one of: ["g", "ml", "个"]. 
   - If the receipt shows "kg", convert amount to "g" (e.g., 1kg = 1000g).
   - If it shows "L", convert to "ml".
   - If it's discrete items (like 3 apples or 1 pack), use "个".
B. "categoryId" MUST be the exact "id" of the best matching category from this list:
   [$categoriesJson]

For EACH item, provide these exact fields:
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
12. "shelfLifeDays": Estimated shelf life in days in a standard fridge (int).

Expected JSON format:
[
  { 
    "name": "鸡翅", "amount": 500.0, "unit": "g", "categoryId": "cat_123",
    "group": "meatAndPoultry", "subGroup": "白肉", 
    "cal": 200.0, "pro": 18.0, "carb": 0.0, "fat": 13.0, 
    "tags": ["富含胶原蛋白", "优质蛋白"], "shelfLifeDays": 3 
  }
]
''');

      final imagePart = DataPart(mimeType, imageBytes);
      final response = await model.generateContent([Content.multi([prompt, imagePart])]);
      final responseText = response.text?.trim();

      if (responseText != null && responseText.isNotEmpty) {
        if (kDebugMode) print('AI Vision Output: $responseText');
        final List<dynamic> rawList = jsonDecode(responseText);
        
        for (var item in rawList) {
          if (item is Map<String, dynamic>) {
            parsedItems.add({
              'name': item['name']?.toString() ?? '未知食材',
              'amount': (item['amount'] as num?)?.toDouble() ?? 1.0,
              'unit': _sanitizeUnit(item['unit']?.toString()), // Extra safety layer
              'categoryId': item['categoryId']?.toString(), // Grab the AI-selected category
              'group': _parseDietaryGroup(item['group']?.toString()),
              'subGroup': item['subGroup']?.toString(),
              'cal': (item['cal'] as num?)?.toDouble(),
              'pro': (item['pro'] as num?)?.toDouble(),
              'carb': (item['carb'] as num?)?.toDouble(),
              'fat': (item['fat'] as num?)?.toDouble(),
              'tags': (item['tags'] as List?)?.map((e) => e.toString()).toList(),
              'shelfLifeDays': (item['shelfLifeDays'] as num?)?.toInt() ?? 3,
            });
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Receipt Scanner Error: $e');
    }

    return parsedItems;
  }

  // Double-check the unit just in case the AI hallucinates
  static String _sanitizeUnit(String? unitStr) {
    if (unitStr == 'g' || unitStr == 'ml' || unitStr == '个') return unitStr!;
    if (unitStr != null && unitStr.toLowerCase() == 'kg') return 'g'; // We assume amount was converted by AI, but if not it will be weird. AI prompt handles logic mostly.
    return '个'; // Default safe fallback
  }

  static DietaryGroup _parseDietaryGroup(String? groupStr) {
    if (groupStr == null) return DietaryGroup.others;
    for (var value in DietaryGroup.values) {
      if (value.name == groupStr) {
        return value;
      }
    }
    return DietaryGroup.others;
  }
}