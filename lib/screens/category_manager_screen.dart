// lib/screens/category_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lpinyin/lpinyin.dart'; // 🌟 引入拼音库，保持排序一致性
import '../models/app_models.dart';
import '../data/mock_database.dart';
import '../providers/kitchen_provider.dart'; 
import '../main.dart'; 

class CategoryManagerScreen extends ConsumerStatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  ConsumerState<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> {
  
  void _showCategoryDialog({IngredientCategory? existingCategory}) {
    final bool isEdit = existingCategory != null;
    final nameController = TextEditingController(text: isEdit ? existingCategory.name : '');
    StorageLocation selectedLoc = isEdit ? existingCategory.location : StorageLocation.fridge;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? '编辑分类' : '新建分类', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('分类名称', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    autofocus: !isEdit,
                    decoration: InputDecoration(
                      hintText: '例如：水果、海鲜...',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10C07B))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('存放位置', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: StorageLocation.values.map((loc) {
                      final isSel = selectedLoc == loc;
                      return ChoiceChip(
                        label: Text(loc.displayName),
                        selected: isSel,
                        showCheckmark: false,
                        selectedColor: const Color(0xFF10C07B).withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isSel ? const Color(0xFF10C07B) : Colors.black87, 
                          fontWeight: FontWeight.bold
                        ),
                        side: BorderSide(color: isSel ? const Color(0xFF10C07B) : Colors.grey.shade300),
                        onSelected: (val) => setDialogState(() => selectedLoc = loc),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('取消', style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10C07B), foregroundColor: Colors.white, elevation: 0),
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    if (newName.isEmpty) return; 
                    
                    if (isEdit) {
                      existingCategory.name = newName;
                      existingCategory.location = selectedLoc;
                      await existingCategory.save(); 
                    } else {
                      final newCat = IngredientCategory(
                        id: generateId(),
                        name: newName,
                        location: selectedLoc,
                      );
                      await categoryBox.put(newCat.id, newCat); 
                    }
                    
                    ref.invalidate(categoryProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCategory(IngredientCategory category) async {
    final allInventory = ref.read(inventoryProvider);
    final isInUse = allInventory.any((ing) => ing.categoryId == category.id);

    if (isInUse) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 8), Text('无法删除分类')]),
          content: Text('【${category.name}】下面还有食材正在使用。\n\n请先将该分类下的食材移至其他分类（或删除），然后再尝试删除此分类。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c), 
              child: const Text('我知道了', style: TextStyle(color: Color(0xFF10C07B), fontWeight: FontWeight.bold))
            )
          ],
        )
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('您确定要永久删除【${category.name}】吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, elevation: 0),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('彻底删除'),
          ),
        ],
      )
    );

    if (confirm == true) {
      await category.delete(); 
      ref.invalidate(categoryProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = ref.watch(categoryProvider);

    // 🌟 核心修改：按位置将分类进行分组
    Map<StorageLocation, List<IngredientCategory>> groupedCategories = {};
    for (var loc in StorageLocation.values) {
      final catsInLoc = allCategories.where((c) => c.location == loc).toList();
      if (catsInLoc.isNotEmpty) {
        // 顺便在这里也加上拼音排序，保持一致的体验
        catsInLoc.sort((a, b) => PinyinHelper.getPinyinE(a.name).toLowerCase().compareTo(PinyinHelper.getPinyinE(b.name).toLowerCase()));
        groupedCategories[loc] = catsInLoc;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('管理分类', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: groupedCategories.isEmpty
        ? const Center(child: Text('暂无分类，请点击下方按钮添加', style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: StorageLocation.values.length,
            itemBuilder: (context, index) {
              final loc = StorageLocation.values[index];
              final locCats = groupedCategories[loc];
              
              // 如果这个位置下没有分类，就直接不渲染这个区块
              if (locCats == null || locCats.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🌟 漂亮的分组标题 (例如：冰箱)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        loc.displayName, 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600)
                      ),
                    ),
                    
                    // 渲染该位置下的所有分类卡片
                    ...locCats.map((cat) => Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF10C07B).withValues(alpha: 0.1),
                          child: const Icon(Icons.folder_outlined, color: Color(0xFF10C07B)),
                        ),
                        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        // 🌟 删掉了冗余的 subtitle 位于xxx，让卡片更纯粹干净
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                              onPressed: () => _showCategoryDialog(existingCategory: cat),
                              tooltip: '编辑分类',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _deleteCategory(cat),
                              tooltip: '删除分类',
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10C07B),
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}