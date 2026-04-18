// lib/widgets/ingredient_edit_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../providers/kitchen_provider.dart';
import '../data/mock_database.dart'; // 暂时用于读取 allRecipes 和 recipeBox

class IngredientEditDialog extends ConsumerStatefulWidget {
  final Ingredient? existingIngredient;
  final String? defaultCategoryId;
  final StorageLocation? defaultLocation;

  // 🌟 新增这一行：允许外部拦截保存动作
  final void Function(Ingredient)? onSaveOverride;

  const IngredientEditDialog({
    super.key, 
    this.existingIngredient, 
    this.defaultCategoryId,
    this.defaultLocation,
    this.onSaveOverride, // 🌟 新增
  });

  @override
  ConsumerState<IngredientEditDialog> createState() => _IngredientEditDialogState();
}

class _IngredientEditDialogState extends ConsumerState<IngredientEditDialog> {
  late TextEditingController nameController;
  late TextEditingController amountController;
  
  late StorageLocation selectedLoc;
  String? selectedCategoryId;
  late String selectedUnit;
  DateTime? selectedExpirationDate;
  
  List<String> linkedRecipeIds = [];
  String recipeSearchQuery = '';

  @override
  void initState() {
    super.initState();
    final isEdit = widget.existingIngredient != null;
    
    nameController = TextEditingController(text: isEdit ? widget.existingIngredient!.name : '');
    amountController = TextEditingController(
      text: isEdit && widget.existingIngredient!.numericAmount != null 
          ? widget.existingIngredient!.numericAmount.toString() 
          : ''
    );
    
    // 初始化位置和分类
    if (isEdit) {
      final cat = allCategories.firstWhere((c) => c.id == widget.existingIngredient!.categoryId, 
        orElse: () => allCategories.first);
      selectedLoc = cat.location;
      selectedCategoryId = widget.existingIngredient!.categoryId;
    } else {
      selectedLoc = widget.defaultLocation ?? StorageLocation.fridge;
      selectedCategoryId = widget.defaultCategoryId;
    }

    selectedUnit = isEdit && widget.existingIngredient!.unit != null ? widget.existingIngredient!.unit! : 'g';
    selectedExpirationDate = isEdit ? widget.existingIngredient!.expirationDate : null;

    // 初始化已关联的菜谱
    if (isEdit) {
      linkedRecipeIds = allRecipes
          .where((r) => r.ingredients.any((ri) => ri.ingredientId == widget.existingIngredient!.id))
          .map((r) => r.id)
          .toList();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingIngredient != null;
    // 监听全局分类，以确保联动正确
    final availableCategories = ref.watch(categoryProvider).where((c) => c.location == selectedLoc).toList();
    
    if (selectedCategoryId == null && availableCategories.isNotEmpty) {
      selectedCategoryId = availableCategories.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 顶部 Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(backgroundColor: Color(0xFF10C07B), radius: 12, child: Icon(Icons.add, color: Colors.white, size: 16)),
                      const SizedBox(width: 8),
                      Text(isEdit ? '编辑食材' : '入库新食材', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),

              // 2. 名称输入
              const Text('名称', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: '输入名称...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10C07B))),
                ),
              ),
              const SizedBox(height: 20),

              // 3. 位置与分类联动
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('位置', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // 第一行：位置标签 (取代了原来的 Dropdown)
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: StorageLocation.values.map((loc) {
                      final isSel = selectedLoc == loc;
                      return ChoiceChip(
                        label: Text(loc.displayName),
                        selected: isSel,
                        showCheckmark: false, // 👈 保留你的优秀优化：去掉打勾图标
                        selectedColor: const Color(0xFF10C07B).withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isSel ? const Color(0xFF10C07B) : Colors.black87, 
                          fontWeight: FontWeight.bold // 👈 保留你的优秀优化：固定加粗防止闪烁
                        ),
                        side: BorderSide(color: isSel ? const Color(0xFF10C07B) : Colors.grey.shade300),
                        onSelected: (val) {
                          setState(() {
                            selectedLoc = loc;
                            // 🌟 核心：切换位置时，自动抓取新位置下的第一个分类 (使用 Riverpod)
                            final newCats = ref.read(categoryProvider).where((c) => c.location == loc).toList();
                            selectedCategoryId = newCats.isNotEmpty ? newCats.first.id : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text('分类', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // 第二行：分类标签
                  availableCategories.isEmpty 
                    ? const Text('该位置暂无分类，请先去首页新建', style: TextStyle(color: Colors.red, fontSize: 12))
                    : Wrap(
                        spacing: 8, runSpacing: 8,
                        children: availableCategories.map((cat) {
                          final isSel = selectedCategoryId == cat.id;
                          return ChoiceChip(
                            label: Text(cat.name),
                            selected: isSel,
                            showCheckmark: false, // 👈 保留你的优秀优化
                            selectedColor: const Color(0xFF10C07B).withValues(alpha: 0.1),
                            labelStyle: TextStyle(
                              color: isSel ? const Color(0xFF10C07B) : Colors.black87, 
                              fontWeight: FontWeight.bold // 👈 保留你的优秀优化
                            ),
                            side: BorderSide(color: isSel ? const Color(0xFF10C07B) : Colors.grey.shade300),
                            onSelected: (val) => setState(() => selectedCategoryId = cat.id),
                          );
                        }).toList(),
                      ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. 数量与单位
              const Text('数量与单位 (选填)', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '输入数量',
                        filled: true, fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10C07B))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4, 
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: ['g', 'ml', '个'].map((u) {
                          final isSel = selectedUnit == u;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedUnit = u),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSel ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: isSel ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
                                ),
                                margin: const EdgeInsets.all(3),
                                alignment: Alignment.center,
                                child: Text(u, style: TextStyle(color: isSel ? const Color(0xFF10C07B) : Colors.grey.shade600, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 快捷添加按钮
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickAddBtn('+1'), const SizedBox(width: 8),
                    _buildQuickAddBtn('+5'), const SizedBox(width: 8),
                    _buildQuickAddBtn('+50'), const SizedBox(width: 8),
                    _buildQuickAddBtn('+100'), const SizedBox(width: 8),
                    _buildQuickAddBtn('+500'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. 保质期
              const Text('保质期 (选填)', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildQuickDateBtn('+3天', () => setState(() => selectedExpirationDate = DateTime.now().add(const Duration(days: 3)))),
                  const SizedBox(width: 8),
                  _buildQuickDateBtn('+1周', () => setState(() => selectedExpirationDate = DateTime.now().add(const Duration(days: 7)))),
                  const SizedBox(width: 8),
                  _buildQuickDateBtn('+1月', () => setState(() => selectedExpirationDate = DateTime.now().add(const Duration(days: 30)))),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: selectedExpirationDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2050));
                  if (picked != null) setState(() => selectedExpirationDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(selectedExpirationDate == null ? '年 / 月 / 日' : selectedExpirationDate!.toLocal().toString().split(' ')[0], style: TextStyle(color: selectedExpirationDate == null ? Colors.grey : Colors.black87, fontSize: 16)),
                      const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 6. 菜谱搜索关联
              const Text('关联菜谱 (可选)', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: '搜索并关联已有菜谱...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                  filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10C07B))),
                ),
                onChanged: (val) => setState(() => recipeSearchQuery = val),
              ),
              const SizedBox(height: 8),
              
              Builder(
                builder: (context) {
                  final filteredRecipes = allRecipes.where((r) => r.name.toLowerCase().contains(recipeSearchQuery.toLowerCase())).toList();
                  
                  if (allRecipes.isEmpty) return const Text('暂无菜谱，请先去菜谱页添加', style: TextStyle(color: Colors.grey, fontSize: 12));
                  if (filteredRecipes.isEmpty) return const Text('未找到匹配的菜谱', style: TextStyle(color: Colors.grey, fontSize: 12));
                  
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = filteredRecipes[index];
                        return CheckboxListTile(
                          title: Text(recipe.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          value: linkedRecipeIds.contains(recipe.id),
                          activeColor: const Color(0xFF10C07B),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) linkedRecipeIds.add(recipe.id);
                              else linkedRecipeIds.remove(recipe.id);
                            });
                          }
                        );
                      }
                    ),
                  );
                }
              ),
              const SizedBox(height: 24),

              // 7. 提交按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10C07B), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _saveIngredient,
                  child: const Text('确认入库', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              // 8. 彻底删除按钮 (仅编辑模式显示)
              if (isEdit)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.08), foregroundColor: Colors.red, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text('彻底删除此食材', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        final isLinked = allRecipes.any((r) => r.ingredients.any((ri) => ri.ingredientId == widget.existingIngredient!.id));
                        if (isLinked) {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 8), Text('无法彻底删除')]),
                              content: const Text('有菜谱正在使用该食材。\n如果您当前不需要它，只需将其数量清空即可（它会自动沉底并显示缺货）。'),
                              actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('我知道了', style: TextStyle(color: Color(0xFF10C07B))))],
                            )
                          );
                        } else {
                          ref.read(inventoryProvider.notifier).deleteIngredient(widget.existingIngredient!);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  // --- 内部辅助方法 ---

  Widget _buildQuickAddBtn(String label) {
    return InkWell(
      onTap: () {
        double current = double.tryParse(amountController.text) ?? 0.0;
        double toAdd = double.tryParse(label.replaceAll('+', '')) ?? 0.0;
        setState(() {
          double result = current + toAdd;
          amountController.text = result == result.truncateToDouble() ? result.toInt().toString() : result.toString();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(16)),
        child: Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQuickDateBtn(String label, VoidCallback onSelect) {
    return InkWell(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(16)),
        child: Text(label, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }

  Future<void> _saveIngredient() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入食材名称')));
      return;
    }
    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先建立分类')));
      return;
    }

    double? parsedAmt = double.tryParse(amountController.text);
    final inputName = nameController.text.trim();
    String currentIngId = widget.existingIngredient?.id ?? generateId();


    // 🌟🌟🌟 新增的核心拦截逻辑：在这里拦截，阻止直接写库 🌟🌟🌟
    if (widget.onSaveOverride != null) {
      final updatedIng = Ingredient(
        id: currentIngId,
        name: inputName,
        categoryId: selectedCategoryId!,
        numericAmount: parsedAmt,
        unit: selectedUnit,
        expirationDate: selectedExpirationDate,
        inStock: true,
        // 继承原有的营养数据（防止编辑时把 AI 算出来的营养丢失）
        dietaryGroup: widget.existingIngredient?.dietaryGroup,
        nutritionalTags: widget.existingIngredient?.nutritionalTags,
        dietarySubGroup: widget.existingIngredient?.dietarySubGroup,
        caloriesPer100g: widget.existingIngredient?.caloriesPer100g,
        proteinPer100g: widget.existingIngredient?.proteinPer100g,
        carbsPer100g: widget.existingIngredient?.carbsPer100g,
        fatPer100g: widget.existingIngredient?.fatPer100g,
      );
      widget.onSaveOverride!(updatedIng);
      return; // ⛔️ 关键：直接 return，绝不执行下面的真实写库和菜谱关联操作
    }
    // 🌟🌟🌟 拦截逻辑结束 🌟🌟🌟
    
    // 1. 保存/合并食材
    if (widget.existingIngredient != null) {
      widget.existingIngredient!.name = inputName;
      widget.existingIngredient!.categoryId = selectedCategoryId!;
      widget.existingIngredient!.expirationDate = selectedExpirationDate;
      widget.existingIngredient!.numericAmount = parsedAmt;
      widget.existingIngredient!.unit = selectedUnit;
      await ref.read(inventoryProvider.notifier).addOrUpdateIngredient(widget.existingIngredient!);
    } else {
      // 智能重复检查：如果该名称已存在（可能在缺货底部），直接复活它
      final allInventory = ref.read(inventoryProvider);
      final existingMatch = allInventory.where((i) => i.name.trim().toLowerCase() == inputName.toLowerCase()).firstOrNull;

      if (existingMatch != null) {
        existingMatch.inStock = true;
        existingMatch.categoryId = selectedCategoryId!;
        existingMatch.expirationDate = selectedExpirationDate;
        existingMatch.numericAmount = parsedAmt;
        existingMatch.unit = selectedUnit;
        await ref.read(inventoryProvider.notifier).addOrUpdateIngredient(existingMatch);
        currentIngId = existingMatch.id; 
      } else {
        final newIng = Ingredient(
          id: currentIngId, 
          name: inputName, 
          categoryId: selectedCategoryId!, 
          inStock: true, 
          expirationDate: selectedExpirationDate, 
          numericAmount: parsedAmt,
          unit: selectedUnit
        );
        await ref.read(inventoryProvider.notifier).addOrUpdateIngredient(newIng);
      }
    }

    // 2. 更新菜谱关联
    for (var recipe in allRecipes) {
      bool changed = false;
      final existingIndex = recipe.ingredients.indexWhere((ri) => ri.ingredientId == currentIngId);
      
      if (linkedRecipeIds.contains(recipe.id)) {
        if (existingIndex == -1) { 
          recipe.ingredients.add(RecipeIngredient(ingredientId: currentIngId, quantity: '适量', isMain: true)); 
          changed = true; 
        }
      } else {
        if (widget.existingIngredient != null && existingIndex != -1) { 
          recipe.ingredients.removeAt(existingIndex); 
          changed = true; 
        }
      }
      if (changed) {
        await recipeBox.put(recipe.id, recipe);
      }
    }
    syncMemoryWithHive(); // 确保其他页面能拿到最新的菜谱数据

    if (mounted) Navigator.pop(context);
  }
}