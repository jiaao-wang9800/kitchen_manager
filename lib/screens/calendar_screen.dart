// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart'; 
import '../providers/recipe_provider.dart';
import '../providers/meal_plan_provider.dart';

// 🌟 导入刚才拆分出去的模块
import '../widgets/calendar_meal_list.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isOverviewMode = false;
  bool _isGroupedByMealType = false;
  final PageController _weekPageController = PageController(initialPage: 500);

  @override
  void dispose() {
    _weekPageController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime d1, DateTime d2) => d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  DateTime _getStartOfWeek(DateTime date) => date.subtract(Duration(days: date.weekday - 1));
  String _getWeekdayName(int weekday) => ['一', '二', '三', '四', '五', '六', '日'][weekday - 1];

  // 添加菜谱的弹窗逻辑保留在主页面
  void _showRecipePicker(MealType mealType, List<Recipe> allRecipes) {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredRecipes = allRecipes.where((r) => r.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
          return AlertDialog(
            title: Text('安排 ${mealType.displayName}'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(decoration: const InputDecoration(hintText: '搜索菜谱...', prefixIcon: Icon(Icons.search), isDense: true), onChanged: (val) => setDialogState(() => searchQuery = val)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true, itemCount: filteredRecipes.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(filteredRecipes[index].name),
                          onTap: () async {
                            final newPlan = MealPlan(id: generateId(), date: _selectedDate, type: mealType, recipeId: filteredRecipes[index].id);
                            await ref.read(mealPlanProvider.notifier).addMealPlan(newPlan);
                            if (context.mounted) Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealPlans = ref.watch(mealPlanProvider);
    final allRecipes = ref.watch(recipeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            if (_isOverviewMode) 
              Expanded(child: _buildGridCalendarMode(mealPlans, allRecipes))
            else ...[
              _buildWeeklySlider(),
              const SizedBox(height: 16),
              // 🌟 这里直接调用分离出去的组件，主文件瞬间精简数百行！
              Expanded(
                child: CalendarMealList(
                  selectedDate: _selectedDate,
                  isGroupedByMealType: _isGroupedByMealType,
                  onGroupedChanged: (val) => setState(() => _isGroupedByMealType = val),
                  onAddRecipe: (mealType) => _showRecipePicker(mealType, allRecipes),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))]),
            child: const Text('饮食搭配', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))]),
            child: IconButton(
              icon: Icon(_isOverviewMode ? Icons.view_agenda_outlined : Icons.calendar_month_outlined, color: Colors.black87),
              onPressed: () => setState(() => _isOverviewMode = !_isOverviewMode),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWeeklySlider() {
    return SizedBox(
      height: 80,
      child: PageView.builder(
        controller: _weekPageController,
        itemBuilder: (context, index) {
          int weekOffset = index - 500;
          DateTime startOfWeek = _getStartOfWeek(DateTime.now()).add(Duration(days: weekOffset * 7));
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (dayIndex) {
                DateTime date = startOfWeek.add(Duration(days: dayIndex));
                bool isSelected = _isSameDay(date, _selectedDate);
                bool isToday = _isSameDay(date, DateTime.now());
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 45, decoration: BoxDecoration(color: isSelected ? const Color(0xFF4A5D4E) : Colors.white, borderRadius: BorderRadius.circular(24), border: isToday && !isSelected ? Border.all(color: const Color(0xFF4A5D4E), width: 1.5) : null, boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF4A5D4E).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : []),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_getWeekdayName(date.weekday), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.grey.shade500)), const SizedBox(height: 4), Text('${date.day}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87))]),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  // 网格模式可以留在主文件，或者你之后也可以用同样的方法把它抽出去
  Widget _buildGridCalendarMode(List<MealPlan> mealPlans, List<Recipe> allRecipes) {
    int year = _selectedDate.year; int month = _selectedDate.month;
    int daysInMonth = DateTime(year, month + 1, 0).day;
    int firstWeekday = DateTime(year, month, 1).weekday; 
    int emptySlotsAtStart = firstWeekday - 1; 

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selectedDate = DateTime(year, month - 1, 1))),
              Text('${month}月 $year', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _selectedDate = DateTime(year, month + 1, 1))),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.6),
            itemCount: emptySlotsAtStart + daysInMonth,
            itemBuilder: (context, index) {
              if (index < emptySlotsAtStart) return const SizedBox.shrink();
              int day = index - emptySlotsAtStart + 1;
              DateTime cellDate = DateTime(year, month, day);
              var dayPlans = mealPlans.where((m) => _isSameDay(m.date, cellDate)).toList();

              return GestureDetector(
                onTap: () => setState(() { _selectedDate = cellDate; _isOverviewMode = false; }),
                child: Container(
                  decoration: BoxDecoration(color: _isSameDay(cellDate, _selectedDate) ? const Color(0xFF4A5D4E).withValues(alpha: 0.1) : Colors.white, border: Border.all(color: Colors.grey.shade200, width: 1)),
                  child: Column(
                    children: [
                      Text('$day', style: TextStyle(fontWeight: _isSameDay(cellDate, DateTime.now()) ? FontWeight.bold : FontWeight.normal)),
                      ...dayPlans.map((p) {
                        final recipe = allRecipes.where((r) => r.id == p.recipeId).firstOrNull;
                        // 网格里如果做完了，可以变绿
                        return Container(margin: const EdgeInsets.symmetric(vertical: 1), padding: const EdgeInsets.all(2), color: p.isCompleted ? const Color(0xFF10C07B).withValues(alpha: 0.2) : const Color(0xFF4A5D4E).withValues(alpha: 0.1), child: Text(recipe?.name ?? '', style: const TextStyle(fontSize: 8), overflow: TextOverflow.ellipsis));
                      }),
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