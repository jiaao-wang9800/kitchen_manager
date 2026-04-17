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
        padding: const EdgeInsets.all(12), // 减小内边距
        width: 500, // 压缩总宽度
        child: IntrinsicHeight( // 🌟 让容器高度根据内容自动收缩
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 左侧日历 (紧凑型)
              SizedBox(
                width: 280,
                child: Theme(
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
              ),

              // 中间细线
              VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade100, indent: 10, endIndent: 10),

              // 2. 右侧餐段及操作
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // 🌟 顶开间距
                    children: [
                      // 餐段按钮组
                      Column(
                        children: MealType.values.map((type) {
                          bool isSelected = _selectedType == type;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => setState(() => _selectedType = type),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _getCNName(type),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // 🌟 操作按钮直接放在右侧底部，省去下方一整行
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
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
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('取消', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCNName(MealType type) {
    switch (type) {
      case MealType.breakfast: return '早餐';
      case MealType.lunch: return '午餐';
      case MealType.dinner: return '晚餐';
      default: return '其他';
    }
  }
}