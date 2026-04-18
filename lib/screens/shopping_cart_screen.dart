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

class ShoppingCartScreen extends ConsumerStatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  ConsumerState<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends ConsumerState<ShoppingCartScreen> {
  bool _isScanning = false;

// ==========================================
  // 🌟 Smart AI Scanner Logic (Riverpod Powered)
  // ==========================================
  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery); 
    if (image == null) return;

    setState(() => _isScanning = true);

    try {
      final bytes = await image.readAsBytes();
      
      // 1. 获取全局的分类数据传给 AI
      final allCategories = ref.read(categoryProvider);
      final results = await ReceiptScannerService.scanGroceries(bytes, categories: allCategories);
      
      setState(() => _isScanning = false); // 扫描完成，关闭 loading 蒙层

      if (results.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未能识别到食材，请换一张清晰的照片试试。')));
        return;
      }

      // 🌟 核心拦截：唤出核对弹窗，后续的入库逻辑全交由弹窗内部处理
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // 强制用户必须点击按钮关闭，防止误触消失
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
    // 🌟 全局监听购物车和库存
    final cartItems = ref.watch(cartProvider);
    final inventory = ref.watch(inventoryProvider);

    Map<String, List<ShoppingItem>> calendarGroups = {};
    Map<String, List<ShoppingItem>> manualGroups = {};

    for (var item in cartItems) {
      if (item.mealPlanId != null) {
        String group = item.groupName ?? '📅 计划所需';
        calendarGroups.putIfAbsent(group, () => []).add(item);
      } else {
        String group = item.groupName ?? '🛒 其他';
        manualGroups.putIfAbsent(group, () => []).add(item);
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

                    if (manualGroups.isNotEmpty) ...[
                      const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Row(children: [Icon(Icons.shopping_bag, size: 18, color: Colors.teal), SizedBox(width: 8), Text('手动添加 / 补货', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal))])),
                      ...manualGroups.entries.map((entry) => _buildGroup(entry.key, entry.value, inventory, isCalendar: false)),
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
          FloatingActionButton(
            heroTag: 'manual_add_btn',
            onPressed: () => showDialog(context: context, builder: (c) => const ManualAddCartDialog()),
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
            // 🌟 使用 Riverpod 联动更新状态
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
// 🌟 提取的独立弹窗组件：手动添加到购物车
// ==========================================
class ManualAddCartDialog extends ConsumerStatefulWidget {
  const ManualAddCartDialog({super.key});
  @override
  ConsumerState<ManualAddCartDialog> createState() => _ManualAddCartDialogState();
}

class _ManualAddCartDialogState extends ConsumerState<ManualAddCartDialog> {
  final nameCtrl = TextEditingController();
  String? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final allCategories = ref.watch(categoryProvider);

    return AlertDialog(
      title: const Text('Add to Cart'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl, 
            decoration: const InputDecoration(labelText: 'Ingredient Name'),
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Category (For Kitchen)'),
            items: allCategories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
            onChanged: (val) => setState(() => selectedCategoryId = val),
          )
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
          onPressed: (selectedCategoryId == null || nameCtrl.text.isEmpty) ? null : () async {
            // 1. 创建新食材并入库
            final newIng = Ingredient(id: generateId(), name: nameCtrl.text, categoryId: selectedCategoryId!, inStock: false);
            await ref.read(inventoryProvider.notifier).addOrUpdateIngredient(newIng);
            
            // 2. 创建购物项并放入购物车
            final newItem = ShoppingItem(id: generateId(), ingredientId: newIng.id, groupName: '🛒 手动添加');
            await ref.read(cartProvider.notifier).addOrUpdateItem(newItem);
            
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Add'),
        )
      ],
    );
  }
}