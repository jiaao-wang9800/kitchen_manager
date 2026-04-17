// lib/providers/meal_plan_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';

class MealPlanNotifier extends Notifier<List<MealPlan>> {
  @override
  List<MealPlan> build() => mealPlanBox.values.toList();

  void refresh() => state = mealPlanBox.values.toList();

  // 🌟 新增：切换完成状态
  Future<void> toggleCompletion(String id, bool completed) async {
    final plan = mealPlanBox.get(id);
    if (plan != null) {
      plan.isCompleted = completed;
      await mealPlanBox.put(id, plan);
      // 刷新 Riverpod 状态
      state = state.map((p) => p.id == id ? plan : p).toList();
    }
  }

// 🌟 修复后的添加方法
  Future<void> addMealPlan(MealPlan plan) async {
    // 1. 写入物理数据库 (Hive)
    await mealPlanBox.put(plan.id, plan);
    
    // 2. 🌟 关键：更新 Riverpod 的内存状态 (state)
    // 在 Riverpod 中，必须通过赋一个全新的 List 对象来触发 UI 刷新
    state = [...state, plan]; 
    
    // 这样，任何 watch(mealPlanProvider) 的页面（比如日历页）都会瞬间收到通知并重绘
  }

// 🌟 顺便把删除方法也修好
  Future<void> deleteMealPlan(String id) async {
    await mealPlanBox.delete(id);
    // 过滤掉被删除的那一项，重新赋值 state
    state = state.where((p) => p.id != id).toList();
  }

}

final mealPlanProvider = NotifierProvider<MealPlanNotifier, List<MealPlan>>(() => MealPlanNotifier());