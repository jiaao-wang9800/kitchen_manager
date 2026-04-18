// lib/widgets/ingredient_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart'; // 用于 generateId
import '../providers/kitchen_provider.dart';
import '../providers/cart_provider.dart'; // 🌟 新增：用来把东西丢进购物车
import '../screens/matched_recipes_screen.dart';
import 'ingredient_edit_dialog.dart';

class IngredientCard extends ConsumerWidget {
  final Ingredient ingredient;

  const IngredientCard({super.key, required this.ingredient});

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IngredientEditDialog(
        existingIngredient: ingredient,
        defaultCategoryId: ingredient.categoryId,
      ),
    );
  }

  // 🌟 恢复的弹窗交互逻辑：拦截用完操作，并询问是否补货
  void _confirmConsume(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('食材用完啦！'),
        content: Text('您已经标记吃完了 "${ingredient.name}"。需要顺手把它加入购物车补货吗？'),
        actions: [
          TextButton(
            onPressed: () async {
              // 仅标记为缺货，不加购物车
              ingredient.inStock = false;
              await ref.read(inventoryProvider.notifier).addOrUpdateIngredient(ingredient);
              if (context.mounted) Navigator.pop(c);
            },
            child: const Text('不用了，仅移除', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10C07B), foregroundColor: Colors.white),
            onPressed: () async {
              // 1. 标记缺货
              ingredient.inStock = false;
              await ref.read(inventoryProvider.notifier).addOrUpdateIngredient(ingredient);
              
              // 2. 写入购物车
              final shoppingItem = ShoppingItem(
                id: generateId(), 
                ingredientId: ingredient.id, 
                groupName: '🛒 智能补货'
              );
              await ref.read(cartProvider.notifier).addOrUpdateItem(shoppingItem);
              
              if (context.mounted) {
                Navigator.pop(c);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${ingredient.name} 已加入购物车！'), backgroundColor: const Color(0xFF10C07B))
                );
              }
            },
            child: const Text('是的，加入购物车'),
          ),
        ],
      ),
    );
  }


// 🌟 新增：一键快捷加入购物车逻辑
  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    final shoppingItem = ShoppingItem(
      id: generateId(), 
      ingredientId: ingredient.id, 
      groupName: '🛒 快捷补货', // 给它一个专属的智能分组
    );
    
    await ref.read(cartProvider.notifier).addOrUpdateItem(shoppingItem);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ingredient.name} 已加入购物车！'), 
          backgroundColor: Colors.orange, // 使用醒目的橙色提示
          duration: const Duration(seconds: 2),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isExpired = ingredient.expirationDate != null && ingredient.expirationDate!.isBefore(DateTime.now());
    bool isOutOfStock = !ingredient.inStock;
    
return Opacity(
      opacity: isOutOfStock ? 0.4 : 1.0, 
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA), 
          borderRadius: BorderRadius.circular(12),
        ),
        // 🌟 核心升级：用 Material + InkWell 替代 ListTile，保留点击水波纹效果，但打破高度限制
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MatchedRecipesScreen(ingredient: ingredient)));
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, // 左右两边垂直居中对齐
                children: [
                  // =====================================
                  // 左侧：信息展示区 (利用 Expanded 自动占满剩余空间)
                  // =====================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. 标题行
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                ingredient.name, 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isOutOfStock) ...[
                              const SizedBox(width: 8),
                              const Text('缺货', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                            ]
                          ],
                        ),
                        
                        // 2. 副标题（数量保质期 + 标签）
                        if (!isOutOfStock && (ingredient.numericAmount != null || ingredient.expirationDate != null))
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Wrap(
                              spacing: 12,
                              children: [
                                if (ingredient.numericAmount != null)
                                  Text(
                                    'Qty: ${ingredient.numericAmount == ingredient.numericAmount!.truncateToDouble() ? ingredient.numericAmount!.toInt() : ingredient.numericAmount}${ingredient.unit ?? ''}', 
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)
                                  ),
                                if (ingredient.expirationDate != null)
                                  Text(
                                    'Exp: ${ingredient.expirationDate!.toLocal().toString().split(' ')[0]}', 
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: isExpired ? Colors.red : Colors.grey.shade600, 
                                      fontWeight: isExpired ? FontWeight.bold : FontWeight.normal
                                    )
                                  ),
                              ],
                            ),
                          ),

                        // 3. AI 动画 或 营养标签
                        if (ingredient.isAiAnalyzing)
                          const Padding(
                            padding: EdgeInsets.only(top: 6.0),
                            child: Row(
                              children: [
                                SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                                SizedBox(width: 8),
                                Text('AI 营养分析中...', style: TextStyle(fontSize: 10, color: Colors.orange)),
                              ],
                            ),
                          )
                        else 
                          Builder(
                            builder: (context) {
                              List<Widget> tags = [];
                              if (ingredient.dietaryGroup != null) {
                                tags.add(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange.shade200)),
                                    child: Text(ingredient.dietaryGroup!.displayName, style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                                  )
                                );
                              }
                              if (ingredient.nutritionalTags != null && ingredient.nutritionalTags!.isNotEmpty) {
                                for (var tag in ingredient.nutritionalTags!.take(2)) {
                                  tags.add(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green.shade200)),
                                      child: Text(tag, style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                                    )
                                  );
                                }
                              }
                              if (tags.isEmpty) return const SizedBox.shrink();
                              return Padding(padding: const EdgeInsets.only(top: 6.0), child: Wrap(spacing: 6, runSpacing: 4, children: tags));
                            },
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12), // 左右两块区域的呼吸空间
                  
// =====================================
                  // 右侧：操作按钮区 (彻底解脱高度限制)
                  // =====================================
                  Column(
                    mainAxisSize: MainAxisSize.min, // 高度包裹内容
                    children: [
                      // 🌟 核心升级：有货显示“吃完”，缺货显示“加购”
                      if (!isOutOfStock) ...[
                        InkWell(
                          onTap: () => _confirmConsume(context, ref),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(Icons.check_circle_outline, color: Colors.teal, size: 22),
                          ),
                        ),
                        const SizedBox(height: 8), 
                      ] else ...[
                        InkWell(
                          onTap: () => _addToCart(context, ref), // 👆 调用我们刚写的加购方法
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(Icons.add_shopping_cart, color: Colors.orange, size: 22), // 缺货时显示橙色购物车
                          ),
                        ),
                        const SizedBox(height: 8), 
                      ],
                      // 下方始终保留编辑按钮
                      InkWell(
                        onTap: () => _showEditDialog(context),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 22),
                        ),
                      ),
                    ],
                  ),  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}