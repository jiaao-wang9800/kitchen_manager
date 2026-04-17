import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../providers/kitchen_provider.dart';
import '../data/mock_database.dart';
import '../providers/cart_provider.dart';

class RecipeConsumeDialog extends ConsumerWidget {
  final Recipe recipe;

  const RecipeConsumeDialog({super.key, required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听全局库存
    final inventory = ref.watch(inventoryProvider);

    // 🌟 核心过滤逻辑：找出当前菜谱用到的、且在库里的真实食材
    final recipeIngredients = inventory.where((inv) {
      return recipe.ingredients.any(
        (req) => req.ingredientId == inv.id || req.ingredientId == inv.name
      );
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '结算食材: ${recipe.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              '如果做菜时彻底用光了某样食材，请点击消耗，它将从库存中扣除。',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            
            // 🌟 迷你库存列表
            Flexible(
              child: recipeIngredients.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text('此菜谱暂无对应的库存记录', style: TextStyle(color: Colors.grey.shade400)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: recipeIngredients.length,
                      itemBuilder: (context, index) {
                        final inv = recipeIngredients[index];
                        final bool inStock = inv.inStock;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: Text(
                              inv.name, 
                              style: TextStyle(
                                // 如果已经用完，加上删除线并变灰
                                decoration: !inStock ? TextDecoration.lineThrough : null,
                                color: !inStock ? Colors.grey : Colors.black87,
                                fontWeight: FontWeight.w500,
                              )
                            ),
                            // 🌟 完美复用“消耗”逻辑
                              trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: inStock ? Colors.orange.shade50 : Colors.grey.shade200,
                                foregroundColor: inStock ? Colors.orange.shade700 : Colors.grey,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                if (inStock) {
                                  // 1. 如果当前有库存，点击代表“用完”
                                  inv.inStock = false;
                                  await ref.read(inventoryProvider.notifier).addOrUpdateIngredient(inv);

                                  if (!context.mounted) return;

                                  // 2. 🌟 弹出询问窗口：是否加入购物车
                                  final shouldAddToCart = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('🍽️ 食材已耗尽'),
                                      content: Text('您刚刚用完了【${inv.name}】，是否需要顺手将它加入采购清单？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(c, false),
                                          child: const Text('暂不购买', style: TextStyle(color: Colors.grey)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF10C07B),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                          ),
                                          onPressed: () => Navigator.pop(c, true),
                                          child: const Text('加入购物车 🛒'),
                                        ),
                                      ],
                                    ),
                                  );

                                  // 3. 如果用户点了“加入购物车”
                                  if (shouldAddToCart == true && context.mounted) {
                                    // 构建一个购物车项
                                    // （假设你的数据库 ID 生成函数叫 generateId()，并且你的 ShoppingItem 模型是这样的）
                                    // 注意：请确保文件顶部 import 了 mock_database 里的 generateId
                                    final newItem = ShoppingItem(
                                      id: generateId(), 
                                      ingredientId: inv.id, 
                                      groupName: recipe.name, // 记作是为了做这道菜买的
                                    );
                                    
                                    // 写入购物车 Provider（请根据你实际的 cartProvider 方法名调整，比如 addItem 或 addCartItem）
                                    // 如果你还没给 cartProvider 写添加单项的方法，可以直接用 box.put，但推荐用 provider
                                    // 🌟 换成你真实的方法名
                                    ref.read(cartProvider.notifier).addOrUpdateItem(newItem);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('已将 ${inv.name} 加入购物车！'),
                                          backgroundColor: const Color(0xFF4A5D4E),
                                          behavior: SnackBarBehavior.floating,
                                        )
                                      );
                                    }
                                  }
                                } else {
                                  // 如果当前已经是“已耗尽”状态，点击代表“撤销操作”（比如用户点错了）
                                  inv.inStock = true;
                                  await ref.read(inventoryProvider.notifier).addOrUpdateIngredient(inv);
                                }
                              },
                              child: Text(inStock ? '吃完啦' : '已吃完', style: const TextStyle(fontSize: 13)),
                            ),                         
                          ),
                        );
                      },
                    ),
            ),
            
            const Divider(height: 32),
            
            // 底部完成按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10C07B), // 你的主题绿
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                // 点击完成，返回 true 告诉日历页：“结算完毕，可以打勾了”
                onPressed: () => Navigator.pop(context, true), 
                child: const Text('完成', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}