// lib/widgets/combine_meal_picker.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';

class CombinedMealPicker extends StatefulWidget {
  final DateTime initialDate;
  const CombinedMealPicker({super.key, required this.initialDate});

  @override
  State<CombinedMealPicker> createState() => _CombinedMealPickerState();
}

class _CombinedMealPickerState extends State<CombinedMealPicker> {
  late DateTime _selectedDate;
  MealType _selectedType = MealType.dinner;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 340, // 🌟 适合绝大多数手机屏幕的合理宽度
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🌟 纵向排列，高度根据内容自动收缩
          children: [
            // 1. 上方：日历组件
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: primaryColor),
              ),
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (date) => setState(() => _selectedDate = date),
              ),
            ),

            const Divider(height: 24),

            // 2. 下方：餐段选择 (使用 Wrap 横向排列，自动换行)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: MealType.values.map((type) {
                bool isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(_getCNName(type)),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (bool selected) {
                    if (selected) setState(() => _selectedType = type);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // 3. 底部操作按钮
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('取消', style: TextStyle(color: Colors.grey.shade600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context, {'date': _selectedDate, 'type': _selectedType}),
                    child: const Text('确认添加'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCNName(MealType type) {
    switch (type) {
      case MealType.breakfast: return '早餐';
      case MealType.lunch: return '午餐';
      case MealType.dinner: return '晚餐';
      default: return '加餐';
    }
  }
}