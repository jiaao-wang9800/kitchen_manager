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
import '../data/mock_database.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  StorageLocation _selectedLocation = StorageLocation.fridge;
  String? _selectedCategoryId;

  // 🌟 新增：联动滚动所需的核心控制器与字典
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  bool _isManualScrolling = false; // 防冲突锁

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  void _showIngredientDialog({Ingredient? existingIngredient, String? defaultCategoryId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IngredientEditDialog(
        existingIngredient: existingIngredient,
        defaultCategoryId: defaultCategoryId ?? _selectedCategoryId,
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, StorageLocation currentLocation) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('在【${currentLocation.displayName}】添加新分类', style: const TextStyle(fontSize: 16)),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '例如：水果、甜品...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10C07B),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final newCategory = IngredientCategory(
                    id: generateId(), 
                    name: name,
                    location: currentLocation,
                  );
                  await categoryBox.put(newCategory.id, newCategory);
                  ref.invalidate(categoryProvider);

                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {
                      _selectedCategoryId = newCategory.id;
                    });
                  }
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  // 🌟 核心逻辑 1：滑动右侧时，反向计算并更新左侧菜单
  void _syncLeftMenu(List<IngredientCategory> categories) {
    String? activeCategoryId;

    for (var cat in categories) {
      final key = _categoryKeys[cat.id];
      if (key != null && key.currentContext != null) {
        final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
        final offset = box.localToGlobal(Offset.zero).dy;

        // 设置一条隐形的判定线（距离屏幕顶部 250 像素）。
        // 最后一个越过判定线的分类，就是当前视觉上占据主要位置的分类。
        if (offset < 250) {
          activeCategoryId = cat.id;
        }
      }
    }

    // 容错：如果都在判定线下方（说明是第一个分类），就选中第一个
    if (activeCategoryId == null && categories.isNotEmpty) {
      activeCategoryId = categories.first.id;
    }

    if (activeCategoryId != null && activeCategoryId != _selectedCategoryId) {
      setState(() {
        _selectedCategoryId = activeCategoryId;
      });
      // 联动：让左侧菜单也微微滚动，保持高亮项在中间
      _scrollToCenterLeftMenu(categories, activeCategoryId);
    }
  }

  // 🌟 核心逻辑 2：让左边菜单自动滚动，把选中的项保持在垂直居中的位置
  void _scrollToCenterLeftMenu(List<IngredientCategory> categories, String catId) {
    if (!_leftScrollController.hasClients) return;
    
    final index = categories.indexWhere((c) => c.id == catId);
    if (index == -1) return;

    const itemHeight = 60.0;
    final targetOffset = index * itemHeight;
    final viewportHeight = _leftScrollController.position.viewportDimension;
    // 计算居中偏移量
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
      final aIsDefault = a.id.startsWith('cat_');
      final bIsDefault = b.id.startsWith('cat_');
      if (aIsDefault && !bIsDefault) return -1;
      if (!aIsDefault && bIsDefault) return 1;
      return a.id.compareTo(b.id); 
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
          title: const Text('My Kitchen', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            IconButton(
              icon: const Icon(Icons.create_new_folder_outlined, color: Color(0xFF10C07B)), 
              tooltip: '新增分类',
              onPressed: () => _showAddCategoryDialog(context, _selectedLocation),
            ),
            IconButton(
              icon: const Icon(Icons.bolt, color: Colors.orangeAccent), 
              tooltip: '一键刷新营养成分', 
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🤖 AI 正在分析库中食材，请稍候...')));
                try {
                  final count = await ref.read(inventoryProvider.notifier).batchAnalyzeNutrition();
                  if (context.mounted) {
                    if (count > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✨ 成功为 $count 项食材匹配营养标签！'), backgroundColor: const Color(0xFF10C07B)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('所有食材都已分析完毕，无需刷新啦 ✨')));
                    }
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分析失败，请检查网络或 API 设置'), backgroundColor: Colors.red));
                }
              },
            ),
          ],
        ),  
        body: Column(
          children: [
            _buildTopLocationBar(),
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
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF10C07B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
          elevation: 2,
          onPressed: () => _showIngredientDialog(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildTopLocationBar() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: StorageLocation.values.length,
        itemBuilder: (context, index) {
          final loc = StorageLocation.values[index];
          final isSelected = loc == _selectedLocation;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedLocation = loc;
                _selectedCategoryId = null; 
              });
              // 🌟 切换大区域时，右侧列表主动复位到顶部
              if (_rightScrollController.hasClients) {
                _rightScrollController.jumpTo(0);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF10C07B) : Colors.grey.shade600,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 3,
                      width: 24,
                      decoration: BoxDecoration(color: const Color(0xFF10C07B), borderRadius: BorderRadius.circular(2)),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeftCategoryMenu(List<IngredientCategory> categories) {
    return Container(
      width: 90,
      color: const Color(0xFFF5F5F5),
      child: ListView.builder(
        controller: _leftScrollController, // 🌟 挂载左侧控制器
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.id == _selectedCategoryId;
          
          return GestureDetector(
            onTap: () async {
              setState(() => _selectedCategoryId = cat.id);
              _scrollToCenterLeftMenu(categories, cat.id); // 点自己的时候也稍微居中一下
              
              // 🌟 核心逻辑 3：点击左边，右边自动滚动到对应物理位置
              final key = _categoryKeys[cat.id];
              if (key != null && key.currentContext != null) {
                _isManualScrolling = true; // 上锁，防止触发双向滑动死循环
                await Scrollable.ensureVisible(
                  key.currentContext!,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  alignment: 0.0, // 滚动到可见区域的最顶部
                );
                await Future.delayed(const Duration(milliseconds: 100)); // 给个微小的缓冲时间
                _isManualScrolling = false; // 解锁
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

  Widget _buildRightContentArea(List<IngredientCategory> categories, List<Ingredient> myInventory) {
    if (categories.isEmpty) return const Center(child: Text('此位置暂无分类', style: TextStyle(color: Colors.grey)));

    // 🌟 为了能让 GlobalKey 正确绑定并测算所有元素，这里将 ListView.builder 替换为 SingleChildScrollView + Column
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        // 只有当不是我们主动点击左侧触发的滚动，而是用户实实在在滑动右侧时，才进行反向计算
        if (!_isManualScrolling && scrollInfo is ScrollUpdateNotification) {
          _syncLeftMenu(categories);
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: _rightScrollController, // 🌟 挂载右侧控制器
        padding: const EdgeInsets.all(12),
        child: Column(
          children: categories.map((cat) {
            // 为每个分类自动生成并复用唯一的 GlobalKey
            _categoryKeys.putIfAbsent(cat.id, () => GlobalKey());
            final catKey = _categoryKeys[cat.id]!;

            final ingredients = myInventory.where((i) => i.categoryId == cat.id).toList();

            ingredients.sort((a, b) {
              if (a.inStock && !b.inStock) return -1;
              if (!a.inStock && b.inStock) return 1;
              return a.name.compareTo(b.name); 
            });

            return Column(
              key: catKey, // 🌟 挂载！这相当于给每个分类贴上了定位追踪器
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
                    onTap: () => _showIngredientDialog(defaultCategoryId: cat.id),
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