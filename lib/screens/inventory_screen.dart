// lib/screens/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../providers/kitchen_provider.dart';
import '../widgets/stardew_panel.dart';
import '../widgets/ingredient_edit_dialog.dart';
import '../main.dart'; // for isStardewTheme
import 'matched_recipes_screen.dart';
import '../widgets/ingredient_card.dart';
import 'package:lpinyin/lpinyin.dart';
import 'category_manager_screen.dart'; // 🌟 新增：引入分类管理页面
// 🌟 引入刚刚拆分出来的两个新组件
import '../widgets/add_category_dialog.dart';
import '../widgets/inventory_location_bar.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  StorageLocation _selectedLocation = StorageLocation.fridge;
  String? _selectedCategoryId;

  // 🌟 双向联动所需的核心控制器与字典
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  bool _isManualScrolling = false; 

  // 🌟 新增：搜索相关的状态
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    _searchController.dispose(); // 别忘了销毁
    super.dispose();
  }

  // 呼出食材编辑/新增弹窗
// 🌟 1. 增加 defaultLocation 参数，并透传给 IngredientEditDialog
  void _showIngredientDialog({Ingredient? existingIngredient, String? defaultCategoryId, StorageLocation? defaultLocation}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IngredientEditDialog(
        existingIngredient: existingIngredient,
        defaultCategoryId: defaultCategoryId ?? _selectedCategoryId,
        defaultLocation: defaultLocation, // 🌟 新增：传给弹窗内部
      ),
    );
  }
  // 核心逻辑 1：滑动右侧时，反向计算并更新左侧菜单
  void _syncLeftMenu(List<IngredientCategory> categories) {
    String? activeCategoryId;

    for (var cat in categories) {
      final key = _categoryKeys[cat.id];
      if (key != null && key.currentContext != null) {
        final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
        final offset = box.localToGlobal(Offset.zero).dy;

        if (offset < 250) {
          activeCategoryId = cat.id;
        }
      }
    }

    if (activeCategoryId == null && categories.isNotEmpty) {
      activeCategoryId = categories.first.id;
    }

    if (activeCategoryId != null && activeCategoryId != _selectedCategoryId) {
      setState(() {
        _selectedCategoryId = activeCategoryId;
      });
      _scrollToCenterLeftMenu(categories, activeCategoryId);
    }
  }

  // 核心逻辑 2：让左边菜单自动微调滚动，保持垂直居中
  void _scrollToCenterLeftMenu(List<IngredientCategory> categories, String catId) {
    if (!_leftScrollController.hasClients) return;
    
    final index = categories.indexWhere((c) => c.id == catId);
    if (index == -1) return;

    const itemHeight = 60.0;
    final targetOffset = index * itemHeight;
    final viewportHeight = _leftScrollController.position.viewportDimension;
    final offset = targetOffset - (viewportHeight / 2) + (itemHeight / 2);

    _leftScrollController.animateTo(
      offset.clamp(0.0, _leftScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

@override
  Widget build(BuildContext context) {
    final allCategories = ref.watch(categoryProvider);
    final myInventory = ref.watch(inventoryProvider);

    final locationCategories = allCategories.where((c) => c.location == _selectedLocation).toList();

    locationCategories.sort((a, b) {
      String pinyinA = PinyinHelper.getPinyinE(a.name).toLowerCase();
      String pinyinB = PinyinHelper.getPinyinE(b.name).toLowerCase();
      return pinyinA.compareTo(pinyinB);
    });
    
    if (_selectedCategoryId == null && locationCategories.isNotEmpty) {
      _selectedCategoryId = locationCategories.first.id;
    }

    return StardewPanelContainer(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '在全部食材库中搜索...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                    // 🌟 修复 1：删掉了这里的 suffixIcon，因为它容易被拦截
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                )
              : const Text('My Kitchen', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: _isSearching 
              ? [
                  // 🌟 修复 2：把关闭按钮放到原生的 actions 列表里！这里的点击绝对百分百触发。
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  ),
                ] 
              : [
                  // 非搜索状态下，显示搜索按钮和其他原有按钮
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black54),
                    onPressed: () => setState(() => _isSearching = true),
                  ),
                  // 🌟 修复：改为跳转到完整的分类管理页面
                  IconButton(
                    icon: const Icon(Icons.folder_copy_outlined, color: Color(0xFF10C07B)), // 换个图标，表示“分类管理”
                    tooltip: '管理分类',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoryManagerScreen(),
                        ),
                      );
                    },
                  ),                  IconButton(
                    icon: const Icon(Icons.bolt, color: Colors.orangeAccent), 
                    tooltip: '一键刷新营养成分', 
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🤖 AI 正在分析库中食材，请稍候...')));
                      try {
                        final count = await ref.read(inventoryProvider.notifier).batchAnalyzeNutrition();
                        if (context.mounted) {
                          if (count > 0) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✨ 成功为 $count 项食材匹配营养标签！'), backgroundColor: const Color(0xFF10C07B)));
                        }
                      } catch (e) {}
                    },
                  ),
                ],
        ),// 🌟 核心升级：如果是搜索状态，就直接展示全局结果列表！
        
        body: _isSearching
            ? _buildGlobalSearchResults(myInventory, allCategories)
            : Column(
                children: [
                  InventoryLocationBar(
                    selectedLocation: _selectedLocation,
                    onLocationChanged: (newLocation) {
                      setState(() {
                        _selectedLocation = newLocation;
                        _selectedCategoryId = null; 
                      });
                      if (_rightScrollController.hasClients) {
                        _rightScrollController.jumpTo(0);
                      }
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLeftCategoryMenu(locationCategories),
                        Expanded(child: _buildRightContentArea(locationCategories, myInventory)),
                      ],
                    ),
                  )
                ],
              ),
        // 搜索时隐藏悬浮按钮
        floatingActionButton: _isSearching 
            ? null 
            : FloatingActionButton(
                backgroundColor: const Color(0xFF10C07B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                elevation: 2,
                onPressed: () => _showIngredientDialog(),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
      ),
    );
  }
  
  // ============== 🌟 新增：全局搜索结果视图 ==============
  Widget _buildGlobalSearchResults(List<Ingredient> myInventory, List<IngredientCategory> allCategories) {
    if (_searchQuery.isEmpty) {
      return const Center(child: Text('输入名称搜索全部食材', style: TextStyle(color: Colors.grey)));
    }

    // 1. 在整个厨房过滤食材（支持原生包含匹配，也可以扩展支持拼音搜索）
    var results = myInventory.where((i) {
      final matchName = i.name.toLowerCase().contains(_searchQuery.toLowerCase());
      // 可选：如果用拼音库，还可以支持搜拼音 `pingguo` 匹配 `苹果`
      final matchPinyin = PinyinHelper.getPinyinE(i.name).toLowerCase().replaceAll(' ', '').contains(_searchQuery.toLowerCase());
      return matchName || matchPinyin;
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('没有找到相关食材', style: TextStyle(color: Colors.grey)),
          ],
        )
      );
    }

    // 2. 按首字母排个序
    results.sort((a, b) => PinyinHelper.getPinyinE(a.name).toLowerCase().compareTo(PinyinHelper.getPinyinE(b.name).toLowerCase()));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final ing = results[index];
        // 去总分类表里找出它的归属地
        final cat = allCategories.firstWhere((c) => c.id == ing.categoryId, 
          orElse: () => IngredientCategory(id: 'unknown', name: '未知分类', location: StorageLocation.fridge)
        );
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 贴心细节：搜索结果上方标明该食材的存放位置和分类
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4, top: 12),
              child: Text(
                '📍 ${cat.location.displayName} - ${cat.name}', 
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)
              ),
            ),
            IngredientCard(ingredient: ing),
          ],
        );
      },
    );
  }
  
  // ============== 局部组件：左侧菜单 ==============
  Widget _buildLeftCategoryMenu(List<IngredientCategory> categories) {
    return Container(
      width: 90,
      color: const Color(0xFFF5F5F5),
      child: ListView.builder(
        controller: _leftScrollController, 
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.id == _selectedCategoryId;
          
          return GestureDetector(
            onTap: () async {
              setState(() => _selectedCategoryId = cat.id);
              _scrollToCenterLeftMenu(categories, cat.id); 
              
              // 核心逻辑 3：点左边，右边滚动
              final key = _categoryKeys[cat.id];
              if (key != null && key.currentContext != null) {
                _isManualScrolling = true; 
                await Scrollable.ensureVisible(
                  key.currentContext!,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  alignment: 0.0, 
                );
                await Future.delayed(const Duration(milliseconds: 100));
                _isManualScrolling = false; 
              }
            },
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border(left: BorderSide(color: isSelected ? const Color(0xFF10C07B) : Colors.transparent, width: 4))
              ),
              alignment: Alignment.center,
              child: Text(
                cat.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============== 局部组件：右侧内容 ==============
  Widget _buildRightContentArea(List<IngredientCategory> categories, List<Ingredient> myInventory) {
    if (categories.isEmpty) return const Center(child: Text('此位置暂无分类', style: TextStyle(color: Colors.grey)));

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isManualScrolling && scrollInfo is ScrollUpdateNotification) {
          _syncLeftMenu(categories);
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: _rightScrollController, 
        padding: const EdgeInsets.all(12),
        child: Column(
          children: categories.map((cat) {
            _categoryKeys.putIfAbsent(cat.id, () => GlobalKey());
            final catKey = _categoryKeys[cat.id]!;

            final ingredients = myInventory.where((i) => i.categoryId == cat.id).toList();

            ingredients.sort((a, b) {
              if (a.inStock && !b.inStock) return -1;
              if (!a.inStock && b.inStock) return 1;
              
              // 🌟 食材同样按拼音 A-Z 排序
              String pinyinA = PinyinHelper.getPinyinE(a.name).toLowerCase();
              String pinyinB = PinyinHelper.getPinyinE(b.name).toLowerCase();
              return pinyinA.compareTo(pinyinB); 
            });

            return Column(
              key: catKey, // 挂载定位器
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                  child: Text(cat.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black45)),
                ),
                
                if (ingredients.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Text('还没有添加食材哦', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                  )
                else
                  ...ingredients.map((ing) => IngredientCard(ingredient: ing)),
                  
Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 4.0),
                child: InkWell(
                  // 🌟 2. 在这里精确传递当前所在的大类
                  onTap: () => _showIngredientDialog(
                    defaultCategoryId: cat.id,
                    defaultLocation: _selectedLocation, // 新增这一行
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text('+ 添加到 ${cat.name}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ),
                ),
              )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}