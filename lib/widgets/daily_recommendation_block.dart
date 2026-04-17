// lib/widgets/daily_recommendation_block.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart'; 
import '../providers/recipe_provider.dart';
import '../providers/kitchen_provider.dart';
import '../providers/meal_plan_provider.dart';
import '../screens/recipe_detail_screen.dart';

class DailyRecommendationBlock extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const DailyRecommendationBlock({super.key, required this.selectedDate});

  @override
  ConsumerState<DailyRecommendationBlock> createState() => _DailyRecommendationBlockState();
}

class _DailyRecommendationBlockState extends ConsumerState<DailyRecommendationBlock> {
  DietaryGroup? _selectedRecommendGroup;

  bool _isSameDay(DateTime d1, DateTime d2) => d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  Set<DietaryGroup> _getConsumedGroupsForToday(List<MealPlan> mealPlans, List<Recipe> allRecipes, List<Ingredient> inventory) {
    Set<DietaryGroup> consumed = {};
    final dayPlans = mealPlans.where((m) => _isSameDay(m.date, widget.selectedDate)).toList();
    for (var plan in dayPlans) {
      final recipe = allRecipes.where((r) => r.id == plan.recipeId).firstOrNull;
      if (recipe != null) {
        for (var req in recipe.ingredients) {
          final ing = inventory.where((i) => i.id == req.ingredientId || i.name == req.ingredientId).firstOrNull;
          if (ing != null && ing.dietaryGroup != null) consumed.add(ing.dietaryGroup!);
        }
      }
    }
    return consumed;
  }

  @override
  Widget build(BuildContext context) {
    final mealPlans = ref.watch(mealPlanProvider);
    final allRecipes = ref.watch(recipeProvider);
    final inventory = ref.watch(inventoryProvider);

    final consumedGroups = _getConsumedGroupsForToday(mealPlans, allRecipes, inventory);
    final displayGroups = DietaryGroup.values.where((g) => g != DietaryGroup.oils && g != DietaryGroup.saltAndCondiments && g != DietaryGroup.others).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF9FAEB), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E9C5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.lightbulb_outline, color: Color(0xFF8B9D3C), size: 20), SizedBox(width: 8), Text('今日餐食推荐', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A5D4E)))]),
          const SizedBox(height: 16),
          
          // 🌟 核心布局修改：完美的左右双栏布局
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左栏：整个左侧的膳食指南图 (高度自适应内容或给定最小高度)
              Container(
                width: 90, 
                constraints: const BoxConstraints(minHeight: 120), // 保证基础高度
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE5E9C5), Color(0xFFD4DCA3)]), borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.health_and_safety, color: Color(0xFF4A5D4E), size: 36),
                    SizedBox(height: 8),
                    Text('中国居民\n膳食指南', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4A5D4E)))
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // 右栏：标签 + 展开的内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 上部分：标签 Wrap
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: displayGroups.map((group) {
                        bool isConsumed = consumedGroups.contains(group);
                        bool isSelected = _selectedRecommendGroup == group;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRecommendGroup = (_selectedRecommendGroup == group) ? null : group;
                            });
                          }, 
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF4A5D4E) : (isConsumed ? Colors.grey.shade200 : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? const Color(0xFF4A5D4E) : (isConsumed ? Colors.transparent : const Color(0xFF8B9D3C).withValues(alpha: 0.5))),
                            ),
                            child: Text(
                              group.displayName, 
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: (isConsumed && !isSelected) ? FontWeight.normal : FontWeight.bold, 
                                color: isSelected ? Colors.white : (isConsumed ? Colors.grey.shade500 : const Color(0xFF4A5D4E))
                              )
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    // 下部分：🌟 直接填补在标签正下方空缺的展开区域
                    if (_selectedRecommendGroup != null)
                      _buildInlineExpansionArea(_selectedRecommendGroup!, allRecipes, inventory),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  // 内部辅助组件：由于在右栏空间变窄，对卡片尺寸进行了精致微调
  Widget _buildInlineExpansionArea(DietaryGroup group, List<Recipe> allRecipes, List<Ingredient> inventory) {
    final groupIngredients = inventory.where((i) => i.dietaryGroup == group).toList();
    groupIngredients.sort((a, b) {
      if (a.inStock && !b.inStock) return -1;
      if (!a.inStock && b.inStock) return 1;
      if (a.inStock && b.inStock) {
        if (a.expirationDate == null && b.expirationDate == null) return a.name.compareTo(b.name);
        if (a.expirationDate == null) return 1;
        if (b.expirationDate == null) return -1;
        return a.expirationDate!.compareTo(b.expirationDate!);
      }
      return a.name.compareTo(b.name);
    });

    final matchingRecipes = allRecipes.where((r) {
      return r.ingredients.any((ri) {
        final matchIng = groupIngredients.firstWhere((i) => i.id == ri.ingredientId || i.name == ri.ingredientId, orElse: () => Ingredient(id: '', name: '', categoryId: ''));
        return matchIng.id.isNotEmpty;
      });
    }).toList();
    matchingRecipes.shuffle(); 
    final recommendRecipes = matchingRecipes.take(3).toList(); 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Divider(color: Color(0xFFD4DCA3), height: 1),
        const SizedBox(height: 12),
        
        // --- 优先消耗（缩小了卡片体积以适应右侧） ---
        const Text('✨ 优先消耗 (您的库存)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B9D3C))),
        const SizedBox(height: 8),
        if (groupIngredients.isEmpty)
          Text('没有找到“${group.displayName}”的记录。', style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
        else
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: groupIngredients.length,
              itemBuilder: (context, index) {
                final ing = groupIngredients[index];
                bool isExpiringSoon = ing.expirationDate != null && ing.expirationDate!.difference(DateTime.now()).inDays <= 3;
                return Opacity(
                  opacity: ing.inStock ? 1.0 : 0.4,
                  child: Container(
                    width: 75, // 变窄一点
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isExpiringSoon && ing.inStock ? Colors.red.shade200 : Colors.transparent)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.kitchen, color: ing.inStock ? const Color(0xFF4A5D4E) : Colors.grey, size: 20),
                        const SizedBox(height: 4),
                        Text(ing.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          !ing.inStock ? '缺货' : (ing.expirationDate != null ? '保质期近' : '有货'), 
                          style: TextStyle(fontSize: 9, color: !ing.inStock ? Colors.red : (isExpiringSoon ? Colors.red : Colors.grey.shade500))
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 12),

        // --- 灵感菜谱 ---
        const Text('🍲 灵感菜谱', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B9D3C))),
        const SizedBox(height: 8),
        if (recommendRecipes.isEmpty)
          Text('暂无包含这些食材的菜谱。', style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recommendRecipes.length,
              itemBuilder: (context, index) {
                final recipe = recommendRecipes[index];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: recipe.id))),
                  child: Container(
                    width: 120, // 变窄一点
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))]),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 55, width: double.infinity,
                          decoration: BoxDecoration(color: Colors.teal.shade50),
                          child: recipe.imagePath != null 
                            ? Image.network(recipe.imagePath!, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.restaurant, size: 24, color: Colors.white54))
                            : const Icon(Icons.restaurant, size: 24, color: Colors.white54),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(recipe.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                height: 26,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D4E), foregroundColor: Colors.white, padding: EdgeInsets.zero, elevation: 0),
                                  onPressed: () async {
                                    final mealType = await showDialog<MealType>(
                                      context: context, builder: (c) => SimpleDialog(title: const Text('排入哪个餐段?'), children: MealType.values.map((t) => SimpleDialogOption(onPressed: () => Navigator.pop(c, t), child: Text(t.displayName))).toList())
                                    );
                                    if (mealType != null) {
                                      final plan = MealPlan(id: generateId(), date: widget.selectedDate, type: mealType, recipeId: recipe.id);
                                      await ref.read(mealPlanProvider.notifier).addMealPlan(plan);
                                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已安排 ${recipe.name}'), backgroundColor: const Color(0xFF10C07B)));
                                    }
                                  },
                                  child: const Text('排入今日', style: TextStyle(fontSize: 10)),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}