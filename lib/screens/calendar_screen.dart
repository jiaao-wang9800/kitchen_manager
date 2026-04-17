// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart'; // 保留用于 syncMealPlansToCart 和 generateId
import 'matched_recipes_screen.dart'; // 跳转页面
import '../providers/recipe_provider.dart';
import '../providers/kitchen_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/meal_plan_provider.dart';
import '../widgets/daily_recommendation_block.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isOverviewMode = false;
  bool _isGroupedByMealType = false;
  Set<String> _syncedPlanIds = {};
  bool _isSyncSelectionMode = false;
  final PageController _weekPageController = PageController(initialPage: 500);
  @override
  void initState() {
    super.initState();
    // 🌟 从 Riverpod 的购物车数据中初始化已同步的计划
    final currentCart = ref.read(cartProvider);
    _syncedPlanIds = currentCart.where((item) => item.mealPlanId != null).map((item) => item.mealPlanId!).toSet();
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime d1, DateTime d2) => d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  Future<void> _triggerSync() async {
    await syncMealPlansToCart(_syncedPlanIds.toList());
    ref.read(cartProvider.notifier).refresh(); // 🌟 通知 Riverpod 刷新购物车状态
    setState(() {}); 
  }

  DateTime _getStartOfWeek(DateTime date) => date.subtract(Duration(days: date.weekday - 1));
  String _getWeekdayName(int weekday) => ['一', '二', '三', '四', '五', '六', '日'][weekday - 1];

  void _showRecipePicker(MealType mealType, List<Recipe> allRecipes) {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredRecipes = allRecipes.where((r) => r.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
          return AlertDialog(
            title: Text('Plan ${mealType.displayName}'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(decoration: const InputDecoration(hintText: 'Search recipes...', prefixIcon: Icon(Icons.search), isDense: true), onChanged: (val) => setDialogState(() => searchQuery = val)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true, itemCount: filteredRecipes.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(filteredRecipes[index].name),
                          onTap: () async {
                            final newPlan = MealPlan(id: generateId(), date: _selectedDate, type: mealType, recipeId: filteredRecipes[index].id);
                            // 🌟 使用 Riverpod 引擎添加计划
                            await ref.read(mealPlanProvider.notifier).addMealPlan(newPlan);
                            if (context.mounted) Navigator.pop(context);
                            setState(() {});
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
    // 🌟 全局监听最新状态
    final mealPlans = ref.watch(mealPlanProvider);
    final allRecipes = ref.watch(recipeProvider);
    final inventory = ref.watch(inventoryProvider);

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
              Expanded(child: _buildMealListContainer(mealPlans, allRecipes, inventory)),
            ]
          ],
        ),
      ),
      bottomNavigationBar: _isSyncSelectionMode ? Container(color: Colors.orange, padding: const EdgeInsets.all(8), child: Text('Sync Mode: ${_syncedPlanIds.length} plans selected', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))) : null,
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
          Row(
            children: [
              if (_isOverviewMode) 
                IconButton(icon: Icon(_isSyncSelectionMode ? Icons.shopping_cart : Icons.add_shopping_cart), color: _isSyncSelectionMode ? Colors.orange : Colors.grey.shade600, onPressed: () => setState(() => _isSyncSelectionMode = !_isSyncSelectionMode)),
              Container(
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))]),
                child: IconButton(
                  icon: Icon(_isOverviewMode ? Icons.view_agenda_outlined : Icons.calendar_month_outlined, color: Colors.black87),
                  onPressed: () => setState(() { _isOverviewMode = !_isOverviewMode; if (!_isOverviewMode) _isSyncSelectionMode = false; }),
                ),
              ),
            ],
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

  Widget _buildMealListContainer(List<MealPlan> mealPlans, List<Recipe> allRecipes, List<Ingredient> inventory) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('周${_getWeekdayName(_selectedDate.weekday)}吃什么', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                Row(children: [Text('三餐展示', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)), const SizedBox(width: 8), Switch(value: _isGroupedByMealType, activeColor: const Color(0xFF4A5D4E), onChanged: (val) => setState(() => _isGroupedByMealType = val))])
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                if (_isGroupedByMealType) ...[
                  _buildGroupedMealSlot(MealType.breakfast, mealPlans, allRecipes), 
                  _buildGroupedMealSlot(MealType.lunch, mealPlans, allRecipes), 
                  _buildGroupedMealSlot(MealType.dinner, mealPlans, allRecipes),
                ] else 
                  _buildFlatMealList(mealPlans, allRecipes),
                
                const SizedBox(height: 24),
                DailyRecommendationBlock(selectedDate: _selectedDate),              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedMealSlot(MealType type, List<MealPlan> mealPlans, List<Recipe> allRecipes) {
    final currentPlans = mealPlans.where((m) => _isSameDay(m.date, _selectedDate) && m.type == type).toList();
    IconData slotIcon = type == MealType.breakfast ? Icons.free_breakfast_outlined : (type == MealType.lunch ? Icons.lunch_dining_outlined : Icons.dinner_dining_outlined);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(children: [Icon(slotIcon, size: 20, color: Colors.orange), const SizedBox(width: 8), Text(type.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)), const Spacer(), IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF4A5D4E)), onPressed: () => _showRecipePicker(type, allRecipes))]),
        ),
        if (currentPlans.isEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0), child: Text('No meals planned yet.', style: TextStyle(color: Colors.grey.shade400, fontSize: 13))),
        ...currentPlans.map((plan) => _buildPlanListItem(plan, allRecipes)),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Divider()),
      ],
    );
  }

  Widget _buildFlatMealList(List<MealPlan> mealPlans, List<Recipe> allRecipes) {
    final dayPlans = mealPlans.where((m) => _isSameDay(m.date, _selectedDate)).toList();
    return Column(
      children: [
        if (dayPlans.isEmpty) 
          Padding(padding: const EdgeInsets.all(24.0), child: Text('今天还没有安排菜谱哦', style: TextStyle(color: Colors.grey.shade400))),
        ...dayPlans.map((p) => _buildPlanListItem(p, allRecipes)),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add), label: const Text('添加菜谱'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D4E), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => _showRecipePicker(MealType.lunch, allRecipes),
          ),
        )
      ],
    );
  }

  Widget _buildPlanListItem(MealPlan plan, List<Recipe> allRecipes) {
    final recipe = allRecipes.where((r) => r.id == plan.recipeId).firstOrNull;
    bool isSynced = _syncedPlanIds.contains(plan.id);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(recipe?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
      subtitle: Text('Swipe left to delete', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
      leading: Checkbox(value: isSynced, activeColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), onChanged: (val) async { setState(() { val! ? _syncedPlanIds.add(plan.id) : _syncedPlanIds.remove(plan.id); }); await _triggerSync(); }),
      trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20), onPressed: () async { 
        _syncedPlanIds.remove(plan.id); 
        await ref.read(mealPlanProvider.notifier).deleteMealPlan(plan); 
        await _triggerSync(); 
      }),
    );
  }

  void _showIngredientInventorySheet(DietaryGroup group, List<Ingredient> inventory) {
    final ingredients = inventory.where((i) => i.dietaryGroup == group).toList();
    
    ingredients.sort((a, b) {
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6, 
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12, bottom: 16), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Text('挑选: ${group.displayName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('点击食材查看可做菜谱', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const Divider(),
              Expanded(
                child: ingredients.isEmpty 
                  ? Center(child: Text('您的厨房数据库中还没有记录过此类食材。', style: TextStyle(color: Colors.grey.shade400)))
                  : ListView.builder(
                      itemCount: ingredients.length,
                      itemBuilder: (context, index) {
                        final ing = ingredients[index];
                        bool isExpiringSoon = ing.expirationDate != null && ing.expirationDate!.difference(DateTime.now()).inDays <= 3;
                        
                        return Opacity(
                          opacity: ing.inStock ? 1.0 : 0.4, 
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.grey.shade100, child: const Icon(Icons.kitchen, color: Colors.grey)),
                            title: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: !ing.inStock 
                                ? const Text('缺货 (Out of stock)', style: TextStyle(color: Colors.red))
                                : (ing.expirationDate != null ? Text('保质期至: ${ing.expirationDate!.toLocal().toString().split(' ')[0]}', style: TextStyle(color: isExpiringSoon ? Colors.red : Colors.grey, fontWeight: isExpiringSoon ? FontWeight.bold : FontWeight.normal)) : null),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              Navigator.pop(context); 
                              Navigator.push(context, MaterialPageRoute(builder: (_) => MatchedRecipesScreen(ingredient: ing, targetDate: _selectedDate)))
                                .then((_) => setState(() {})); 
                            },
                          ),
                        );
                      },
                    ),
              )
            ],
          ),
        );
      }
    );
  }

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
              bool dayHasSync = dayPlans.isNotEmpty && dayPlans.every((p) => _syncedPlanIds.contains(p.id));

              return GestureDetector(
                onTap: () async {
                  if (_isSyncSelectionMode) {
                    var currentDayPlans = mealPlans.where((m) => _isSameDay(m.date, cellDate)).toList();
                    if (currentDayPlans.isEmpty) return; 
                    bool allCurrentlySynced = currentDayPlans.every((p) => _syncedPlanIds.contains(p.id));
                    setState(() { if (allCurrentlySynced) { for (var p in currentDayPlans) { _syncedPlanIds.remove(p.id); } } else { for (var p in currentDayPlans) { _syncedPlanIds.add(p.id); } } });
                    await _triggerSync(); 
                  } else { setState(() { _selectedDate = cellDate; _isOverviewMode = false; }); }
                },
                child: Container(
                  decoration: BoxDecoration(color: _isSameDay(cellDate, _selectedDate) ? const Color(0xFF4A5D4E).withValues(alpha: 0.1) : Colors.white, border: Border.all(color: dayHasSync && _isSyncSelectionMode ? Colors.orange : Colors.grey.shade200, width: 2)),
                  child: Column(
                    children: [
                      Text('$day', style: TextStyle(fontWeight: _isSameDay(cellDate, DateTime.now()) ? FontWeight.bold : FontWeight.normal)),
                      ...dayPlans.map((p) {
                        final recipe = allRecipes.where((r) => r.id == p.recipeId).firstOrNull;
                        return Container(margin: const EdgeInsets.symmetric(vertical: 1), padding: const EdgeInsets.all(2), color: _syncedPlanIds.contains(p.id) ? Colors.orange.withValues(alpha: 0.2) : const Color(0xFF4A5D4E).withValues(alpha: 0.1), child: Text(recipe?.name ?? '', style: const TextStyle(fontSize: 8), overflow: TextOverflow.ellipsis));
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