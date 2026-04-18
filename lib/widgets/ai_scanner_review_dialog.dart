// lib/widgets/ai_scanner_review_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart'; 
import '../providers/kitchen_provider.dart'; 
import '../providers/cart_provider.dart';
import 'ingredient_edit_dialog.dart'; // 🌟 引入你现有的底部编辑弹窗

class AiScannerReviewDialog extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> scannedItems;

  const AiScannerReviewDialog({super.key, required this.scannedItems});

  @override
  ConsumerState<AiScannerReviewDialog> createState() => _AiScannerReviewDialogState();
}

class _AiScannerReviewDialogState extends ConsumerState<AiScannerReviewDialog> {
  late List<Map<String, dynamic>> _editableItems;

  @override
  void initState() {
    super.initState();
    _editableItems = widget.scannedItems.map((item) => Map<String, dynamic>.from(item)).toList();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoMatchExistingInventory();
    });
  }

  void _autoMatchExistingInventory() {
    final currentInventory = ref.read(inventoryProvider);
    setState(() {
      for (var item in _editableItems) {
        final aiName = (item['name'] as String).toLowerCase();
        final match = currentInventory.where((ing) => 
          ing.name.toLowerCase() == aiName || 
          ing.name.toLowerCase().contains(aiName) || 
          aiName.contains(ing.name.toLowerCase())
        ).firstOrNull;

        item['matchedIngredientId'] = match?.id; 
      }
    });
  }

  // 🌟 完美复用你现有的底部编辑弹窗！
  void _showEditBottomSheet(int index) {
    final item = _editableItems[index];
    
    // 构造一个临时的 Ingredient 对象去喂给你的编辑弹窗
    final tempIng = Ingredient(
      id: 'temp_ai_item', // 临时ID，无关紧要
      name: item['name'],
      categoryId: item['categoryId'] ?? 'default',
      numericAmount: item['amount'] as double,
      unit: item['unit'] as String,
      expirationDate: DateTime.now().add(Duration(days: item['shelfLifeDays'] as int)),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IngredientEditDialog(
        existingIngredient: tempIng,
        defaultCategoryId: tempIng.categoryId,
        // 🌟 使用拦截器！把用户在弹窗里的修改同步回我们的 _editableItems，而不污染数据库
        onSaveOverride: (editedIng) {
          setState(() {
            _editableItems[index]['name'] = editedIng.name;
            _editableItems[index]['amount'] = editedIng.numericAmount ?? 1.0;
            _editableItems[index]['unit'] = editedIng.unit ?? 'g';
            _editableItems[index]['categoryId'] = editedIng.categoryId;
            if (editedIng.expirationDate != null) {
              _editableItems[index]['shelfLifeDays'] = editedIng.expirationDate!.difference(DateTime.now()).inDays;
            }
          });
          Navigator.pop(context); // 修改成功后手动关闭底部弹窗
        },
      ),
    );
  }

  Future<void> _confirmAndImport() async {
    final inventoryNotifier = ref.read(inventoryProvider.notifier);
    final currentInventory = ref.read(inventoryProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final currentCart = ref.read(cartProvider);
    final allCategories = ref.read(categoryProvider);

    int processedCount = 0;
    int matchedCartCount = 0;

    for (var item in _editableItems) {
      final matchedId = item['matchedIngredientId'] as String?;
      String targetIngId;

      if (matchedId != null) {
        final existingIng = currentInventory.firstWhere((i) => i.id == matchedId);
        existingIng.inStock = true;
        existingIng.numericAmount = (existingIng.numericAmount ?? 0) + (item['amount'] as double);
        existingIng.expirationDate = DateTime.now().add(Duration(days: item['shelfLifeDays'] as int));
        
        await inventoryNotifier.addOrUpdateIngredient(existingIng);
        targetIngId = existingIng.id;
      } else {
        final finalCategoryId = allCategories.any((c) => c.id == item['categoryId']) ? item['categoryId'] : (allCategories.firstOrNull?.id ?? 'default');
        final newIng = Ingredient(
          id: generateId(),
          name: item['name'],
          categoryId: finalCategoryId,
          inStock: true,
          numericAmount: item['amount'] as double,
          unit: item['unit'] as String,
          dietaryGroup: item['group'] as DietaryGroup?,
          dietarySubGroup: item['subGroup'],
          caloriesPer100g: item['cal'],
          proteinPer100g: item['pro'],
          carbsPer100g: item['carb'],
          fatPer100g: item['fat'],
          nutritionalTags: item['tags'],
          expirationDate: DateTime.now().add(Duration(days: item['shelfLifeDays'] as int)),
          isAiAnalyzing: false,
        );
        
        await inventoryNotifier.addOrUpdateIngredient(newIng);
        targetIngId = newIng.id;
      }
      processedCount++;

      final unpurchasedCartItems = currentCart.where((i) => !i.isPurchased).toList();
      for (var cartItem in unpurchasedCartItems) {
        final cartIng = currentInventory.where((i) => i.id == cartItem.ingredientId).firstOrNull;
        if (cartIng != null) {
          if (cartIng.id == targetIngId || cartIng.name.contains(item['name']) || (item['name'] as String).contains(cartIng.name)) {
            cartItem.isPurchased = true; 
            await cartNotifier.addOrUpdateItem(cartItem);
            matchedCartCount++;
          }
        }
      }
    }

    if (mounted) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎉 入库 $processedCount 项食材，核销购物车 $matchedCartCount 项！'), backgroundColor: Colors.teal));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentInventory = ref.watch(inventoryProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.orange),
                SizedBox(width: 8),
                Text('AI 识别核对', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('请核对扫描结果。您可以点击编辑按钮修改详细信息，也可以直接在下拉框搜索并关联现有库存。', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 24),
            
            Expanded(
              child: _editableItems.isEmpty 
                ? const Center(child: Text('没有识别到内容'))
                : ListView.builder(
                    itemCount: _editableItems.length,
                    itemBuilder: (context, index) {
                      final item = _editableItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: Colors.grey.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item['name']}  (${item['amount']}${item['unit']})', 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                    )
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                    onPressed: () => _showEditBottomSheet(index), // 🌟 呼出你原来的编辑底部弹窗
                                    tooltip: '编辑详情',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => setState(() => _editableItems.removeAt(index)),
                                    tooltip: '删除此项',
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // 🌟 强力升级：带搜索功能的下拉菜单 (DropdownMenu)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return DropdownMenu<String?>(
                                    width: constraints.maxWidth, // 占满卡片宽度
                                    initialSelection: item['matchedIngredientId'],
                                    enableSearch: true, // 开启文本搜索
                                    enableFilter: true, // 开启列表过滤
                                    hintText: '搜索并关联现有食材...',
                                    textStyle: const TextStyle(fontSize: 14),
                                    menuHeight: 200, // 限制最大高度
                                    inputDecorationTheme: InputDecorationTheme(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                      fillColor: Colors.white,
                                      filled: true,
                                    ),
                                    dropdownMenuEntries: [
                                      const DropdownMenuEntry(value: null, label: '✨ 作为新食材入库 (不合并)'),
                                      // 动态渲染现有库存供搜索
                                      ...currentInventory.map((ing) => DropdownMenuEntry(
                                        value: ing.id, 
                                        label: '🔗 合并至: ${ing.name}',
                                      )),
                                    ],
                                    onSelected: (val) {
                                      setState(() => item['matchedIngredientId'] = val);
                                    },
                                  );
                                }
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: _editableItems.isEmpty ? null : _confirmAndImport,
                  icon: const Icon(Icons.check),
                  label: const Text('确认无误，一键入库'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}