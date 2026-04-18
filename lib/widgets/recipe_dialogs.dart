// lib/widgets/recipe_dialogs.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart'; // 仅保留用于直接操作未迁移的Box和生成ID
import '../services/ai_receipt_service.dart';
import '../providers/recipe_provider.dart';
import '../providers/kitchen_provider.dart';

// ==========================================
// 1. 添加/编辑菜谱的独立弹窗组件
// ==========================================
class RecipeEditDialog extends ConsumerStatefulWidget {
  final Recipe? existingRecipe;
  const RecipeEditDialog({super.key, this.existingRecipe});

  @override
  ConsumerState<RecipeEditDialog> createState() => _RecipeEditDialogState();
}

class _RecipeEditDialogState extends ConsumerState<RecipeEditDialog> {
  final ImagePicker _picker = ImagePicker();
  late bool isEdit;
  late TextEditingController nameController;
  late List<RecipeIngredient> selectedIngredients;
  final Map<String, TextEditingController> qtyControllers = {};
  late List<String> steps;
  late List<String> selectedRecipeCatIds;
  String? selectedImagePath;
  final newStepController = TextEditingController();
  
  // 🌟 加入和你详情页一样的搜索控制器
  String ingredientSearchQuery = '';
  final TextEditingController _ingSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isEdit = widget.existingRecipe != null;
    nameController = TextEditingController(text: isEdit ? widget.existingRecipe!.name : '');
    
    selectedIngredients = isEdit 
        ? widget.existingRecipe!.ingredients.map((ri) => RecipeIngredient(ingredientId: ri.ingredientId, quantity: ri.quantity, isMain: ri.isMain)).toList() 
        : [];
    
    for (var ri in selectedIngredients) {
      qtyControllers[ri.ingredientId] = TextEditingController(text: ri.quantity);
    }

    steps = isEdit ? List.from(widget.existingRecipe!.steps) : [];
    selectedRecipeCatIds = isEdit ? List.from(widget.existingRecipe!.categoryIds) : []; 
    selectedImagePath = isEdit ? widget.existingRecipe!.imagePath : null;
  }

  @override
  void dispose() {
    nameController.dispose();
    newStepController.dispose();
    _ingSearchController.dispose();
    for (var ctrl in qtyControllers.values) { ctrl.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);
    final allRecipeCategories = ref.watch(recipeCategoryProvider);
    final filteredIngredients = inventory.where((ing) => ing.name.toLowerCase().contains(ingredientSearchQuery.toLowerCase())).toList();

    return AlertDialog(
      title: Text(isEdit ? 'Edit Recipe' : 'Add Recipe'),
      backgroundColor: const Color(0xFFF8F9FA), // 统一背景色
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. 图片上传区 ---
              Center(
                child: GestureDetector(
                  onTap: () async { 
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery); 
                    if (image != null) setState(() => selectedImagePath = image.path); 
                  }, 
                  child: Container(
                    height: 150, width: double.infinity, 
                    decoration: BoxDecoration(
                      color: Colors.grey[200], borderRadius: BorderRadius.circular(10), 
                      image: selectedImagePath != null ? DecorationImage(image: FileImage(File(selectedImagePath!)), fit: BoxFit.cover) : null
                    ), 
                    child: selectedImagePath == null ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey), SizedBox(height: 8), Text('Tap to add photo', style: TextStyle(color: Colors.grey))]) : null
                  )
                )
              ),
              const SizedBox(height: 16),
              
              // --- 2. 基本信息 ---
              TextField(
                controller: nameController, 
                decoration: InputDecoration(labelText: 'Recipe Name', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))
              ),
              const SizedBox(height: 16),
              const Text('Tags / Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              allRecipeCategories.isEmpty
                  ? const Text('暂无可用的标签，去浏览页右上角添加吧~', style: TextStyle(color: Colors.grey, fontSize: 13))
                  : Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: allRecipeCategories.map((cat) {
                        final isSelected = selectedRecipeCatIds.contains(cat.id);
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              isSelected ? selectedRecipeCatIds.remove(cat.id) : selectedRecipeCatIds.add(cat.id);
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200), // 丝滑的变色动画
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              // 选中时用显眼的纯绿色，未选中用浅灰色
                              color: isSelected ? const Color(0xFF10C07B) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF10C07B) : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                // 选中时文字变白且加粗
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 8),
              const Divider(),
              
              // --- 3. 食材区 (完美复刻你的神仙内联 UI，去掉了右上角的 New) ---
              const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              TextField(
                controller: _ingSearchController,
                decoration: InputDecoration(
                  hintText: '搜索已有食材，或输入新名称...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: ingredientSearchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () => setState(() { _ingSearchController.clear(); ingredientSearchQuery = ''; }))
                    : null,
                ),
                onChanged: (val) => setState(() => ingredientSearchQuery = val)
              ),
              
              if (ingredientSearchQuery.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: const Color(0xFF4A5D4E).withValues(alpha: 0.3))
                  ),
                  child: Column(
                    children: [
                      // 1. 渲染搜索到的已有食材
                      ...filteredIngredients.map((ing) {
                        final isAlreadyAdded = selectedIngredients.any((ri) => ri.ingredientId == ing.id);
                        return ListTile(
                          title: Text(
                            ing.name,
                            style: TextStyle(
                              color: isAlreadyAdded ? Colors.grey : Colors.black87,
                              decoration: isAlreadyAdded ? TextDecoration.lineThrough : null, 
                            )
                          ),
                          trailing: isAlreadyAdded
                            ? const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check, color: Colors.grey, size: 16), SizedBox(width: 4), Text('已添加', style: TextStyle(color: Colors.grey, fontSize: 12))])
                            : const Icon(Icons.add_circle_outline, color: Color(0xFF4A5D4E)),
                          onTap: isAlreadyAdded ? null : () {
                            setState(() {
                              selectedIngredients.add(RecipeIngredient(ingredientId: ing.id, quantity: '适量', isMain: true));
                              qtyControllers[ing.id] = TextEditingController(text: '适量');
                              _ingSearchController.clear();
                              ingredientSearchQuery = '';
                            });
                          },
                        );
                      }),

                      // 🌟 2. 核心改动：智能判断是否显示“新建”选项
                      // 逻辑：只有当【搜索结果里没有任何一个名字】与【输入框内容】完全一致时，才允许新建。
                      if (!filteredIngredients.any((ing) => ing.name.trim().toLowerCase() == ingredientSearchQuery.trim().toLowerCase()))
                        ListTile(
                          leading: const Icon(Icons.add, color: Colors.blueAccent),
                          title: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black87, fontSize: 16),
                              children: [
                                const TextSpan(text: '新建食材 '),
                                TextSpan(text: '"$ingredientSearchQuery"', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          onTap: () => _showQuickAddIngredientDialog(ingredientSearchQuery),
                        )
                    ],
                  ),
                ),
              const SizedBox(height: 16),             
              

              if (selectedIngredients.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedIngredients.length,
                  itemBuilder: (context, index) {
                    final ri = selectedIngredients[index];
                    final ing = inventory.firstWhere((i) => i.id == ri.ingredientId, orElse: () => Ingredient(id: '', name: 'Unknown', categoryId: ''));
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () {
                                setState(() { selectedIngredients.removeAt(index); qtyControllers.remove(ing.id)?.dispose(); });
                              })
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: qtyControllers[ing.id], decoration: InputDecoration(labelText: '具体用量', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), onChanged: (val) => ri.quantity = val)),
                              const SizedBox(width: 12),
                              ChoiceChip(label: const Text('主料'), selected: ri.isMain, onSelected: (v) => setState(() => ri.isMain = true)),
                              const SizedBox(width: 8),
                              ChoiceChip(label: const Text('调料'), selected: !ri.isMain, onSelected: (v) => setState(() => ri.isMain = false)),
                            ],
                          )
                        ],
                      ),
                    );
                  }
                ),

              const Divider(),
              
              // --- 4. 步骤区 ---
              const Text('Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: steps.length, 
                itemBuilder: (context, index) { 
                  return ListTile(
                    dense: true, contentPadding: EdgeInsets.zero, 
                    leading: CircleAvatar(radius: 12, backgroundColor: const Color(0xFF4A5D4E), child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))), 
                    title: Text(steps[index]), trailing: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20), onPressed: () => setState(() => steps.removeAt(index)))
                  ); 
                }
              ),
              Row(children: [
                Expanded(child: TextField(controller: newStepController, decoration: InputDecoration(hintText: 'Add a step...', isDense: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))), 
                IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF4A5D4E)), onPressed: () { if (newStepController.text.isNotEmpty) { setState(() { steps.add(newStepController.text); newStepController.clear(); }); } })
              ]),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D4E), foregroundColor: Colors.white),
          onPressed: () async {
            if (nameController.text.isEmpty) return; 
            Recipe finalRecipe;
            if (isEdit) {
              widget.existingRecipe!.name = nameController.text;
              widget.existingRecipe!.ingredients = selectedIngredients;
              widget.existingRecipe!.steps = steps;
              widget.existingRecipe!.imagePath = selectedImagePath;
              widget.existingRecipe!.categoryIds = selectedRecipeCatIds;
              finalRecipe = widget.existingRecipe!;
            } else {
              finalRecipe = Recipe(
                id: generateId(), name: nameController.text, ingredients: selectedIngredients, steps: steps, imagePath: selectedImagePath, categoryIds: selectedRecipeCatIds
              );
            }
            await ref.read(recipeProvider.notifier).addOrUpdateRecipe(finalRecipe);
            if (context.mounted) Navigator.pop(context);
          }, 
          child: const Text('Save')
        ),
      ],
    );
  }

  // Quick Add Ingredient 辅助方法保持 Riverpod 状态同步
  Future<void> _showQuickAddIngredientDialog([String? initialName]) async {
    final newIngNameCtrl = TextEditingController(text: initialName ?? '');
    final allCategories = ref.read(categoryProvider);
    String? selectedCatId = allCategories.isNotEmpty ? allCategories.first.id : null;

    await showDialog(
      context: context,
      builder: (innerContext) => StatefulBuilder(
        builder: (innerContext, setInnerState) => AlertDialog(
          title: const Text('Quick Add Ingredient'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: newIngNameCtrl, decoration: const InputDecoration(labelText: 'Ingredient Name'), onChanged: (val) => setInnerState(() {})),
                const SizedBox(height: 16),
                const Text('Category:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                allCategories.isEmpty 
                  ? const Text('No categories exist!', style: TextStyle(color: Colors.red))
                  : Wrap(spacing: 8.0, runSpacing: 4.0, children: allCategories.map((cat) { return ChoiceChip(label: Text(cat.name), selected: selectedCatId == cat.id, selectedColor: const Color(0xFF4A5D4E).withValues(alpha: 0.3), onSelected: (bool selected) { if (selected) setInnerState(() => selectedCatId = cat.id); }); }).toList()),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(innerContext), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D4E), foregroundColor: Colors.white),
              onPressed: (selectedCatId == null || newIngNameCtrl.text.trim().isEmpty) ? null : () async {
                final newIng = Ingredient(id: generateId(), name: newIngNameCtrl.text.trim(), categoryId: selectedCatId!, inStock: false);
                await ref.read(inventoryProvider.notifier).addOrUpdateIngredient(newIng);
                setState(() {
                  selectedIngredients.add(RecipeIngredient(ingredientId: newIng.id, quantity: '适量', isMain: true));
                  qtyControllers[newIng.id] = TextEditingController(text: '适量');
                  _ingSearchController.clear();
                  ingredientSearchQuery = '';
                });
                if (innerContext.mounted) Navigator.pop(innerContext);
              },
              child: const Text('Create'),
            )
          ],
        )
      )
    );
  }
}
// ==========================================
// 2. AI 导入的独立弹窗组件
// ==========================================
class AiImportDialog extends ConsumerStatefulWidget {
  const AiImportDialog({super.key});
  @override
  ConsumerState<AiImportDialog> createState() => _AiImportDialogState();
}

class _AiImportDialogState extends ConsumerState<AiImportDialog> {
  final ImagePicker _picker = ImagePicker();
  final textCtrl = TextEditingController();
  bool isLoading = false;
  List<XFile> selectedImages = []; 

  @override
  void dispose() {
    textCtrl.dispose(); // 🌟 别忘了释放它
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [Icon(Icons.auto_awesome, color: Colors.amber), SizedBox(width: 8), Text('AI Smart Import')]),
      content: isLoading 
        ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
        : SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Paste text or upload screenshots/receipts.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  TextField(controller: textCtrl, maxLines: 4, 
                  onChanged: (value) {
                      setState(() {}); 
                    },
                  decoration: const InputDecoration(hintText: 'e.g. Tomato scrambled eggs...', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  if (selectedImages.isNotEmpty)
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal, itemCount: selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Padding(padding: const EdgeInsets.only(right: 8.0, top: 8.0), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: kIsWeb ? Image.network(selectedImages[index].path, width: 50, height: 50, fit: BoxFit.cover) : Image.file(File(selectedImages[index].path), width: 50, height: 50, fit: BoxFit.cover))),
                              Positioned(right: 0, top: 0, child: GestureDetector(onTap: () => setState(() => selectedImages.removeAt(index)), child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)))),
                            ],
                          );
                        },
                      ),
                    ),
                  TextButton.icon(icon: const Icon(Icons.add_photo_alternate, color: Colors.teal), label: const Text('Add Images', style: TextStyle(color: Colors.teal)), onPressed: () async { final List<XFile> images = await _picker.pickMultiImage(); if (images.isNotEmpty) { setState(() => selectedImages.addAll(images)); } }),
                ],
              ),
            ),
          ),
      actions: [
        if (!isLoading) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (!isLoading) ElevatedButton(
        onPressed: (textCtrl.text.trim().isEmpty && selectedImages.isEmpty)
        ? null : () async {
          setState(() => isLoading = true);
          
          try {
            // 🌟 核心改动：将 XFile 列表转换为字节列表
            List<Uint8List> imageBytesList = [];
            for (var file in selectedImages) {
              final bytes = await file.readAsBytes();
              imageBytesList.add(bytes);
            }

            // 调用已经升级为“字节模式”的 AiService
            final recipe = await AiService.importRecipeFromAi(
              textContent: textCtrl.text, 
              imageBytesList: imageBytesList, // 🌟 传入转换好的字节
              allCategories: ref.read(categoryProvider),
              currentInventory: ref.read(inventoryProvider),
              inventoryNotifier: ref.read(inventoryProvider.notifier),
            );

            if (recipe != null) {
              await ref.read(recipeProvider.notifier).addOrUpdateRecipe(recipe);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✨ 菜谱已智能导入并分析营养成分')),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('发生错误: $e'), backgroundColor: Colors.red),
              );
            }
          } finally {
            if (mounted) setState(() => isLoading = false);
          }
        },
        child: const Text('Generate'),
        )
      ],
    );
  }
}