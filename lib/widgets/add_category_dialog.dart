// lib/widgets/add_category_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../providers/kitchen_provider.dart';
import '../data/mock_database.dart'; // 用于 generateId 和 categoryBox

class AddCategoryDialog extends ConsumerStatefulWidget {
  final StorageLocation currentLocation;
  final ValueChanged<String> onCategoryAdded; // 成功后的回调函数

  const AddCategoryDialog({
    super.key,
    required this.currentLocation,
    required this.onCategoryAdded,
  });

  @override
  ConsumerState<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<AddCategoryDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('在【${widget.currentLocation.displayName}】添加新分类', style: const TextStyle(fontSize: 16)),
      content: TextField(
        controller: _nameController,
        autofocus: true, // 自动弹出键盘
        decoration: const InputDecoration(
          hintText: '例如：水果、甜品...',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10C07B),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          onPressed: () async {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              final newCategory = IngredientCategory(
                id: generateId(), 
                name: name,
                location: widget.currentLocation,
              );
              
              // 1. 存入物理数据库
              await categoryBox.put(newCategory.id, newCategory);
              
              // 2. 刷新 Riverpod 状态
              ref.invalidate(categoryProvider);

              if (context.mounted) {
                Navigator.pop(context); // 关闭弹窗
                widget.onCategoryAdded(newCategory.id); // 触发回调，把新ID传给父组件
              }
            }
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}