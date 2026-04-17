// lib/widgets/calendar_meal_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../providers/recipe_provider.dart';
import '../providers/meal_plan_provider.dart';
// 🌟 引入我们上一步刚写好的迷你结算弹窗
import 'recipe_consume_dialog.dart'; 
import 'daily_recommendation_block.dart';

class CalendarMealList extends ConsumerWidget {
  final DateTime selectedDate;
  final bool isGroupedByMealType;
  final Function(bool) onGroupedChanged;
  final Function(MealType) onAddRecipe;

  const CalendarMealList({
    super.key,
    required this.selectedDate,
    required this.isGroupedByMealType,
    required this.onGroupedChanged,
    required this.onAddRecipe,
  });

  String _getWeekdayName(int weekday) => ['一', '二', '三', '四', '五', '六', '日'][weekday - 1];
  bool _isSameDay(DateTime d1, DateTime d2) => d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlans = ref.watch(mealPlanProvider);
    final allRecipes = ref.watch(recipeProvider);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)), 
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]
      ),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('周${_getWeekdayName(selectedDate.weekday)}吃什么', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                Row(children: [
                  Text('三餐展示', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)), 
                  const SizedBox(width: 8), 
                  Switch(value: isGroupedByMealType, activeColor: const Color(0xFF4A5D4E), onChanged: onGroupedChanged)
                ])
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                if (isGroupedByMealType) ...[
                  _buildGroupedMealSlot(MealType.breakfast, mealPlans, allRecipes, context, ref), 
                  _buildGroupedMealSlot(MealType.lunch, mealPlans, allRecipes, context, ref), 
                  _buildGroupedMealSlot(MealType.dinner, mealPlans, allRecipes, context, ref),
                ] else 
                  _buildFlatMealList(mealPlans, allRecipes, context, ref),
                
                const SizedBox(height: 24),
                DailyRecommendationBlock(selectedDate: selectedDate),              
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedMealSlot(MealType type, List<MealPlan> mealPlans, List<Recipe> allRecipes, BuildContext context, WidgetRef ref) {
    final currentPlans = mealPlans.where((m) => _isSameDay(m.date, selectedDate) && m.type == type).toList();
    IconData slotIcon = type == MealType.breakfast ? Icons.free_breakfast_outlined : (type == MealType.lunch ? Icons.lunch_dining_outlined : Icons.dinner_dining_outlined);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(children: [Icon(slotIcon, size: 20, color: Colors.orange), const SizedBox(width: 8), Text(type.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)), const Spacer(), IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF4A5D4E)), onPressed: () => onAddRecipe(type))]),
        ),
        if (currentPlans.isEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0), child: Text('No meals planned yet.', style: TextStyle(color: Colors.grey.shade400, fontSize: 13))),
        ...currentPlans.map((plan) => _buildPlanListItem(plan, allRecipes, context, ref)),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Divider()),
      ],
    );
  }

  Widget _buildFlatMealList(List<MealPlan> mealPlans, List<Recipe> allRecipes, BuildContext context, WidgetRef ref) {
    final dayPlans = mealPlans.where((m) => _isSameDay(m.date, selectedDate)).toList();
    return Column(
      children: [
        if (dayPlans.isEmpty) 
          Padding(padding: const EdgeInsets.all(24.0), child: Text('今天还没有安排菜谱哦', style: TextStyle(color: Colors.grey.shade400))),
        ...dayPlans.map((p) => _buildPlanListItem(p, allRecipes, context, ref)),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add), label: const Text('添加菜谱'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D4E), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => onAddRecipe(MealType.lunch),
          ),
        )
      ],
    );
  }

  // 🌟 核心：改造这里的 Checkbox 逻辑
  Widget _buildPlanListItem(MealPlan plan, List<Recipe> allRecipes, BuildContext context, WidgetRef ref) {
    final recipe = allRecipes.where((r) => r.id == plan.recipeId).firstOrNull;
    if (recipe == null) return const SizedBox(); // 保护逻辑

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(
        recipe.name, 
        style: TextStyle(
          fontWeight: FontWeight.w600, 
          color: plan.isCompleted ? Colors.grey : Colors.black87,
          decoration: plan.isCompleted ? TextDecoration.lineThrough : null, // 做完的菜划掉
        )
      ),
      leading: Checkbox(
        value: plan.isCompleted, 
        activeColor: const Color(0xFF10C07B), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), 
        onChanged: (val) async { 
          if (val == true) {
            // 🌟 勾选完成时：弹出结算窗口
            final result = await showDialog(
              context: context,
              builder: (c) => RecipeConsumeDialog(recipe: recipe),
            );
            // 如果用户在弹窗里点了“完成并打勾”
            if (result == true) {
              await ref.read(mealPlanProvider.notifier).toggleCompletion(plan.id, true);
            }
          } else {
            // 取消打勾：直接改状态即可
            await ref.read(mealPlanProvider.notifier).toggleCompletion(plan.id, false);
          }
        }
      ),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20), 
        onPressed: () async { 
          await ref.read(mealPlanProvider.notifier).deleteMealPlan(plan.id); 
        }
      ),
    );
  }
}