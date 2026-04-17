// lib/providers/meal_plan_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';

class MealPlanNotifier extends Notifier<List<MealPlan>> {
  @override
  List<MealPlan> build() => mealPlanBox.values.toList();

  void refresh() => state = mealPlanBox.values.toList();

  Future<void> addMealPlan(MealPlan plan) async {
    await mealPlanBox.put(plan.id, plan);
    refresh();
  }

  Future<void> deleteMealPlan(MealPlan plan) async {
    await plan.delete();
    refresh();
  }
}

final mealPlanProvider = NotifierProvider<MealPlanNotifier, List<MealPlan>>(() => MealPlanNotifier());