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

    int newCount = 0;
    int restockCount = 0;
    int addStockCount = 0;
    int matchedCartCount = 0;

    for (var item in _editableItems) {
      final matchedId = item['matchedIngredientId'] as String?;
      String targetIngId;

      if (matchedId != null) {
        final existingIng = currentInventory.firstWhere((i) => i.id == matchedId);
        
        // 统计：之前是缺货还是有货
        if (existingIng.inStock) {
          addStockCount++;
        } else {
          restockCount++;
        }

        existingIng.inStock = true;
        existingIng.numericAmount = (existingIng.numericAmount ?? 0) + (item['amount'] as double);
        existingIng.expirationDate = DateTime.now().add(Duration(days: item['shelfLifeDays'] as int));
        
        await inventoryNotifier.addOrUpdateIngredient(existingIng);
        targetIngId = existingIng.id;
      } else {
        newCount++;
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
      // 🌟 优化后的提示语，清晰展示各类别数量
      final message = '🎉 成功入库！新增 $newCount 项，补货 $restockCount 项，追加库存 $addStockCount 项。(自动核销购物车 $matchedCartCount 项)';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.teal, duration: const Duration(seconds: 4)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentInventory = ref.watch(inventoryProvider);

    // 🌟 1. 根据当前库存状态，将扫描项目分为三类 (保存它们在原列表中的索引)
    List<int> newIndices = [];
    List<int> restockIndices = [];
    List<int> existingIndices = [];

    for (int i = 0; i < _editableItems.length; i++) {
      final matchedId = _editableItems[i]['matchedIngredientId'];
      if (matchedId == null) {
        newIndices.add(i);
      } else {
        final matchIng = currentInventory.where((ing) => ing.id == matchedId).firstOrNull;
        if (matchIng != null && matchIng.inStock) {
          existingIndices.add(i); // 已经有货（可能重复或追加余量）
        } else {
          restockIndices.add(i); // 目前缺货（需要补货）
        }
      }
    }

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
            const Text('请核对扫描结果，系统已自动按库存状态进行分类。您可以点击匹配下拉框修改关联状态。', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 24),
            
            Expanded(
              child: _editableItems.isEmpty 
                ? const Center(child: Text('没有识别到内容'))
                : ListView(
                    children: [

                      // 🌟 已有库存区块（提示风险）
                      if (existingIndices.isNotEmpty) ...[
                        _buildSectionHeader(Icons.warning_amber_rounded, '已有库存 (入库将增加余量，请确认)', Colors.orange),
                        ...existingIndices.map((idx) => _buildItemCard(idx, currentInventory)),
                      ],

                      // 🌟 新食材区块
                      if (newIndices.isNotEmpty) ...[
                        _buildSectionHeader(Icons.new_releases, '发现新食材', Colors.green),
                        ...newIndices.map((idx) => _buildItemCard(idx, currentInventory)),
                        const SizedBox(height: 16),
                      ],
                      
                      // 🌟 补货食材区块
                      if (restockIndices.isNotEmpty) ...[
                        _buildSectionHeader(Icons.restore_page, '补货食材 (库中缺货)', Colors.teal),
                        ...restockIndices.map((idx) => _buildItemCard(idx, currentInventory)),
                        const SizedBox(height: 16),
                      ],
                    ],
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

  // 小标题组件
  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // 🌟 抽取出的独立列表项渲染逻辑
  Widget _buildItemCard(int index, List<Ingredient> currentInventory) {
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
                  onPressed: () => _showEditBottomSheet(index), 
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
            
            // 伪装成下拉框的按钮，点击呼出专用的搜索弹窗
            Builder(
              builder: (context) {
                final matchedId = item['matchedIngredientId'];
                final matchedIng = matchedId != null 
                    ? currentInventory.where((i) => i.id == matchedId).firstOrNull 
                    : null;
                
                return InkWell(
                  onTap: () => _showSearchableSelect(index, currentInventory),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          matchedId == null ? Icons.add_circle_outline : Icons.link, 
                          size: 18, 
                          color: matchedId == null ? Colors.orange : Colors.teal
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            matchedId == null ? '✨ 作为新食材入库 (不合并)' : '🔗 合并至: ${matchedIng?.name ?? '未知食材'}',
                            style: TextStyle(
                              fontSize: 14, 
                              color: matchedId == null ? Colors.orange.shade700 : Colors.black87,
                              fontWeight: matchedId == null ? FontWeight.bold : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 全新的搜索关联弹窗（保持不变）
  void _showSearchableSelect(int itemIndex, List<Ingredient> inventory) {
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // 模糊搜索逻辑：只要名字里包含输入的字就能搜出来
            final filteredList = inventory.where((ing) => 
              ing.name.toLowerCase().contains(searchQuery.toLowerCase())
            ).toList();

            return AlertDialog(
              title: const Text('选择关联食材', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              contentPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: SizedBox(
                width: double.maxFinite,
                height: 400, // 给列表一个固定的最大高度
                child: Column(
                  children: [
                    // 搜索框
                    TextField(
                      autofocus: true, 
                      decoration: InputDecoration(
                        hintText: '搜索现有食材...',
                        prefixIcon: const Icon(Icons.search, color: Colors.teal),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) {
                        setModalState(() => searchQuery = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    // 搜索结果列表
                    Expanded(
                      child: ListView(
                        children: [
                          // 永远置顶的“作为新食材”选项
                          ListTile(
                            leading: const Icon(Icons.add_circle_outline, color: Colors.orange),
                            title: const Text('✨ 作为新食材入库 (不合并)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                            onTap: () {
                              setState(() {
                                _editableItems[itemIndex]['matchedIngredientId'] = null;
                              });
                              Navigator.pop(context);
                            },
                          ),
                          const Divider(),
                          if (filteredList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: Text('未找到匹配的食材', style: TextStyle(color: Colors.grey))),
                            ),
                          // 渲染搜索结果
                          ...filteredList.map((ing) => ListTile(
                            leading: const Icon(Icons.kitchen, color: Colors.teal),
                            title: Text('🔗 合并至: ${ing.name}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            // 贴心地显示一下当前的库存状态
                            subtitle: Text(
                              ing.inStock ? '当前有库存' : '当前缺货', 
                              style: TextStyle(fontSize: 12, color: ing.inStock ? Colors.grey : Colors.red)
                            ),
                            onTap: () {
                              setState(() {
                                _editableItems[itemIndex]['matchedIngredientId'] = ing.id;
                              });
                              Navigator.pop(context); // 选完自动关闭小弹窗
                            },
                          )),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }
}