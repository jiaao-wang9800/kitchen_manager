// lib/screens/shopping_cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart'; // 仅保留用于 generateId
import '../services/ai_scanner_service.dart';
import '../providers/kitchen_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/ai_scanner_review_dialog.dart';
import '../widgets/ingredient_edit_dialog.dart'; // 🌟 导入神级编辑弹窗

class ShoppingCartScreen extends ConsumerStatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  ConsumerState<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends ConsumerState<ShoppingCartScreen> {
  bool _isScanning = false;

  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery); 
    if (image == null) return;

    setState(() => _isScanning = true);

    try {
      final bytes = await image.readAsBytes();
      final allCategories = ref.read(categoryProvider);
      final results = await ReceiptScannerService.scanGroceries(bytes, categories: allCategories);
      
      setState(() => _isScanning = false); 

      if (results.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未能识别到食材，请换一张清晰的照片试试。')));
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, 
          builder: (context) => AiScannerReviewDialog(scannedItems: results),
        );
      }
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('扫描失败: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    } 
  }
  
  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final inventory = ref.watch(inventoryProvider);

    Map<String, List<ShoppingItem>> calendarGroups = {};
    Map<String, List<ShoppingItem>> recipeRestockGroups = {}; 
    List<ShoppingItem> generalRestockItems = []; 

    for (var item in cartItems) {
      if (item.mealPlanId != null) {
        String group = item.groupName ?? '📅 计划所需';
        calendarGroups.putIfAbsent(group, () => []).add(item);
      } else if (item.groupName != null && item.groupName!.contains('菜谱补货')) {
        recipeRestockGroups.putIfAbsent(item.groupName!, () => []).add(item);
      } else {
        generalRestockItems.add(item);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Shopping Cart', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: Colors.teal),
            tooltip: 'Clear Purchased',
            onPressed: () async {
              await ref.read(cartProvider.notifier).clearPurchased();
            },
          )
        ],
      ),
      body: Stack(
        children: [
          cartItems.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('Your cart is empty.\nGo plan some meals!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500))]))
              : ListView(
                  children: [
                    if (calendarGroups.isNotEmpty) ...[
                      const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Row(children: [Icon(Icons.calendar_today, size: 18, color: Colors.orange), SizedBox(width: 8), Text('来自日历计划', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange))])),
                      ...calendarGroups.entries.map((entry) => _buildGroup(entry.key, entry.value, inventory, isCalendar: true)),
                    ],

                    if (recipeRestockGroups.isNotEmpty) ...[
                      const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Row(children: [Icon(Icons.menu_book, size: 18, color: Colors.deepOrange), SizedBox(width: 8), Text('菜谱所需补货', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepOrange))])),
                      ...recipeRestockGroups.entries.map((entry) => _buildGroup(entry.key, entry.value, inventory, isCalendar: false)),
                    ],

                    if (generalRestockItems.isNotEmpty) ...[
                      const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Row(children: [Icon(Icons.shopping_bag, size: 18, color: Colors.teal), SizedBox(width: 8), Text('快捷补货', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal))])),
                      _buildGroup('🛒 补货清单', generalRestockItems, inventory, isCalendar: false),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
          
          if (_isScanning)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.teal),
                      SizedBox(height: 16),
                      Text('AI 正在清点小票并核销购物车...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'scan_btn',
            onPressed: _isScanning ? null : _scanReceipt,
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.document_scanner, color: Colors.white),
            label: const Text('智能小票入库', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          // 🌟 改为唤出全新的搜索快捷弹窗
          FloatingActionButton(
            heroTag: 'manual_add_btn',
            onPressed: () => showDialog(context: context, builder: (c) => const ManualAddCartSearchDialog()),
            backgroundColor: Colors.teal,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(String title, List<ShoppingItem> items, List<Ingredient> inventory, {required bool isCalendar}) {
    return ExpansionTile(
      initiallyExpanded: true,
      shape: const Border(),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isCalendar ? Colors.orange[800] : Colors.teal[800], fontSize: 16)),
      children: items.map((cartItem) {
        final ingredient = inventory.where((ing) => ing.id == cartItem.ingredientId).firstOrNull;
        if (ingredient == null) return const SizedBox.shrink();

        return CheckboxListTile(
          title: Text(
            ingredient.name,
            style: TextStyle(
              decoration: cartItem.isPurchased ? TextDecoration.lineThrough : null,
              color: cartItem.isPurchased ? Colors.grey : Colors.black87, 
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: isCalendar ? const Text('自动同步', style: TextStyle(fontSize: 10, color: Colors.grey)) : null,
          value: cartItem.isPurchased,
          activeColor: Colors.teal,
          onChanged: (bool? val) async {
            cartItem.isPurchased = val!;
            ingredient.inStock = val;
            await ref.read(cartProvider.notifier).addOrUpdateItem(cartItem);
            await ref.read(inventoryProvider.notifier).addOrUpdateIngredient(ingredient);
          },
          secondary: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: () async {
              await ref.read(cartProvider.notifier).deleteItem(cartItem);
            },
          ),
        );
      }).toList(),
    );
  }
}

// ==========================================
// 🌟 全新重构：复用搜索与新建逻辑的购物车快捷弹窗
// ==========================================
class ManualAddCartSearchDialog extends ConsumerStatefulWidget {
  const ManualAddCartSearchDialog({super.key});

  @override
  ConsumerState<ManualAddCartSearchDialog> createState() => _ManualAddCartSearchDialogState();
}

class _ManualAddCartSearchDialogState extends ConsumerState<ManualAddCartSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🌟 修复卡死 Bug：利用重叠弹窗和双重 pop 实现丝滑连贯的关闭
  void _openCreateIngredientDialog(String initialName) {
    // 删除了原来错误提前执行的 Navigator.pop(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => IngredientEditDialog(
        initialName: initialName, 
        onSaveOverride: (newIng) async {
          // 1. 拦截保存动作：设为缺货
          newIng.inStock = false;
          
          // 2. 保存这个新食材到全局库存
          await ref.read(inventoryProvider.notifier).addOrUpdateIngredient(newIng);
          
          // 3. 创建 ShoppingItem 放入购物车
          final newItem = ShoppingItem(
            id: generateId(),
            ingredientId: newIng.id,
            groupName: '🛒 快捷补货',
          );
          await ref.read(cartProvider.notifier).addOrUpdateItem(newItem);
          
          // 4. 🌟 完美的双重关闭逻辑
          if (bottomSheetContext.mounted) {
            Navigator.pop(bottomSheetContext); // 先关闭底部的填写表单
          }
          if (context.mounted) {
            Navigator.pop(context); // 再关闭背后的搜索弹窗
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);
    final cartItems = ref.watch(cartProvider);

    // 根据输入过滤库存
    final filteredIngredients = inventory
        .where((ing) => ing.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    // 判断是否有完全同名的食材，决定是否显示"新建"按钮
    final exactMatchExists = inventory.any(
        (ing) => ing.name.trim().toLowerCase() == _searchQuery.trim().toLowerCase());

    return AlertDialog(
      title: const Text('添加食材到购物车', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400, // 固定高度
        child: Column(
          children: [
            // 搜索框
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '搜索现有食材，或输入新名称...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }))
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 12),
            
            // 搜索结果列表
            Expanded(
              child: ListView(
                children: [
                  ...filteredIngredients.map((ing) {
                    // 判断这个食材是否已经在购物车里了（并且还没买）
                    final isAlreadyInCart = cartItems.any((item) => item.ingredientId == ing.id && !item.isPurchased);

                    return ListTile(
                      title: Text(
                        ing.name,
                        style: TextStyle(
                          color: isAlreadyInCart ? Colors.grey : Colors.black87,
                          decoration: isAlreadyInCart ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(
                        ing.inStock ? '当前有库存' : '当前缺货',
                        style: TextStyle(fontSize: 12, color: ing.inStock ? Colors.grey : Colors.red),
                      ),
                      trailing: isAlreadyInCart
                          ? const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.check, color: Colors.grey, size: 16),
                              SizedBox(width: 4),
                              Text('已在购物车', style: TextStyle(color: Colors.grey, fontSize: 12))
                            ])
                          : const Icon(Icons.add_shopping_cart, color: Colors.teal),
                      onTap: isAlreadyInCart
                          ? null
                          : () async {
                              // 如果是现有食材，点击直接加入购物车！
                              ing.inStock = false; // 因为要买，标为缺货
                              await ref.read(inventoryProvider.notifier).addOrUpdateIngredient(ing);
                              
                              final newItem = ShoppingItem(
                                id: generateId(),
                                ingredientId: ing.id,
                                groupName: '🛒 快捷补货',
                              );
                              await ref.read(cartProvider.notifier).addOrUpdateItem(newItem);
                              
                              if (context.mounted) Navigator.pop(context); // 选完自动关闭搜索框
                            },
                    );
                  }),

                  // 🌟 如果没搜到完全匹配的，显示蓝色新建按钮
                  if (_searchQuery.isNotEmpty && !exactMatchExists)
                    ListTile(
                      leading: const Icon(Icons.add, color: Colors.blueAccent),
                      title: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87, fontSize: 16),
                          children: [
                            const TextSpan(text: '新建食材 '),
                            TextSpan(
                                text: '"$_searchQuery"',
                                style: const TextStyle(
                                    color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      onTap: () => _openCreateIngredientDialog(_searchQuery),
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}