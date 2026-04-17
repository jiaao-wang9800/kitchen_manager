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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isExpired = ingredient.expirationDate != null && ingredient.expirationDate!.isBefore(DateTime.now());
    bool isOutOfStock = !ingredient.inStock;
    
    return Opacity(
      opacity: isOutOfStock ? 0.4 : 1.0, 
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.kitchen, color: Colors.grey.shade400)),
          // 🌟 核心修改：将标题升级为 Row，把名字和状态放在同一行
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中对齐
            children: [
              // 1. 食材名字 (使用 Flexible 保证名字太长时会自动省略，不会把右边的状态挤出屏幕)
              Flexible(
                child: Text(
                  ingredient.name, 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8), // 名字和状态之间的间距
              
              // 2. 状态信息跟在后面
              if (isOutOfStock)
                const Text('缺货', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))
              else
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (ingredient.numericAmount != null)
                      Text(
                        'Qty: ${ingredient.numericAmount == ingredient.numericAmount!.truncateToDouble() ? ingredient.numericAmount!.toInt() : ingredient.numericAmount}${ingredient.unit ?? ''}', 
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)
                      ),
                    if (ingredient.expirationDate != null)
                      Text(
                        'Exp: ${ingredient.expirationDate!.toLocal().toString().split(' ')[0]}', 
                        style: TextStyle(
                          fontSize: 12, 
                          color: isExpired ? Colors.red : Colors.grey.shade500, 
                          fontWeight: isExpired ? FontWeight.bold : FontWeight.normal
                        )
                      ),
                  ],
                ),
            ],
          ),
          
// 🌟 修复副标题：加入 AI 思考动画，并完美恢复橙色(大类) + 绿色(营养亮点)的双色标签组合
          subtitle: ingredient.isAiAnalyzing
            ? const Padding(
                padding: EdgeInsets.only(top: 6.0),
                child: Row(
                  children: [
                    SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                    SizedBox(width: 8),
                    Text('AI 营养分析中...', style: TextStyle(fontSize: 10, color: Colors.orange)),
                  ],
                ),
              )
            : Builder(
                builder: (context) {
                  List<Widget> tags = [];

                  // 1. 橙色标签：膳食宝塔分类
                  if (ingredient.dietaryGroup != null) {
                    tags.add(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange.shade200)),
                        child: Text(
                          ingredient.dietaryGroup!.displayName, 
                          style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold)
                        ),
                      )
                    );
                  }

                  // 2. 绿色标签：AI 营养特色 (例如高蛋白、低GI等)，最多显示2个以保持UI不拥挤
                  if (ingredient.nutritionalTags != null && ingredient.nutritionalTags!.isNotEmpty) {
                    for (var tag in ingredient.nutritionalTags!.take(2)) {
                      tags.add(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green.shade200)),
                          child: Text(
                            tag, 
                            style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold)
                          ),
                        )
                      );
                    }
                  }

                  if (tags.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags,
                    ),
                  );
                },
              ),
              
          onTap: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => MatchedRecipesScreen(ingredient: ingredient))
            );
          },
          
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isOutOfStock)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.teal, size: 22), 
                  tooltip: '标记为吃完/用完',
                  // 🌟 触发我们刚刚写好的询问弹窗
                  onPressed: () => _confirmConsume(context, ref)
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 22), 
                onPressed: () => _showEditDialog(context)
              ),
            ],
          ),
        ),
      ),
    );
  }
}