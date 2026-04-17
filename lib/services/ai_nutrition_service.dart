// lib/services/ai_nutrition_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';

class AiNutritionService {
  // IMPORTANT: Replace this with your actual API key
  static const String _apiKey = 'AIzaSyAp0N9lyLfdbZkHPTwfswNeOVybY3M6zOc';


  // ==========================================
  // 2. 🌟 全新的真·批量分析 (极大节省 Token)
  // ==========================================
  static Future<Map<String, dynamic>> batchAnalyzeIngredients(List<String> names) async {
    Map<String, dynamic> parsedResults = {};
    if (names.isEmpty || _apiKey.isEmpty) return parsedResults;
    
    try {
          final model = GenerativeModel(
          model: 'gemini-flash-latest', 
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
      ),
    );
      // 将列表变成一个用逗号分隔的字符串，一次性发给 AI
      final namesString = names.map((n) => '"$n"').join(', ');

      final prompt = TextPart('''
Analyze the nutritional profile for each of these ingredients: [$namesString].
Return a single JSON object where the keys are the exact ingredient names provided, and the values are their nutritional data.
Do NOT use Markdown formatting. All descriptive string values must be in Chinese.

CRITICAL RULES:
1. "group": MUST be exactly ONE of the following English keys: [grains, potatoes, vegetables, fruits, meatAndPoultry, seafood, eggs, dairy, soy, nuts, oils, saltAndCondiments, others]
2. "cal": Estimate the calories per 100g (Use double/number).
3. "tags": An array of 1 to 2 short Chinese strings highlighting health benefits (e.g., ["高蛋白", "富含铁"]). Limit to maximum 2 tags to be concise.

Expected JSON format:
{
  "猪肉": { "group": "meatAndPoultry", "cal": 143.0, "tags": ["补充能量", "富含铁"] },
  "菠菜": { "group": "vegetables", "cal": 23.0, "tags": ["富含维生素K", "高膳食纤维"] }
}
''');

      final response = await model.generateContent([Content.multi([prompt])]);
      final responseText = response.text?.trim();
      
      if (responseText != null && responseText.isNotEmpty) {
        final Map<String, dynamic> rawJson = jsonDecode(responseText);
        
        // 解析 AI 返回的数据，并将其转换为 UI 界面可以使用的枚举格式
        rawJson.forEach((name, data) {
           parsedResults[name] = {
             'group': _parseDietaryGroup(data['group']?.toString()),
             'cal': (data['cal'] as num?)?.toDouble() ?? 0.0,
             'tags': (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
           };
        });
      }
    } catch (e) {
      if (kDebugMode) print('Batch AI Error: $e');
    }
    return parsedResults;
  }

  // ==========================================
  // 3. 辅助方法：将字符串转回我们代码里的枚举
  // ==========================================
  static DietaryGroup? _parseDietaryGroup(String? groupStr) {
    if (groupStr == null) return null;
    for (var value in DietaryGroup.values) {
      if (value.name == groupStr) {
        return value;
      }
    }
    return DietaryGroup.others; // 如果 AI 瞎编了一个分类，就放进“其他”
  }
}
// 注意：类的大括号在这里闭合！上面的所有方法都在类里面！