My Kitchen - Rebuilding Project (Updated 2026.04)
当前架构 (Current Architecture)
Screens (页面层)
/lib/screens/inventory_screen.dart - (重构) 厨房主仓库。实现了 双向联动滚动 (Scroll Spy)、全局上帝视角搜索 及 中英文拼音 A-Z 排序。

/lib/screens/category_manager_screen.dart - (新增) 完整的分类管理中心。支持分类的 CRUD（增删改查），并按 StorageLocation 自动分组展示。

/lib/screens/calendar_screen.dart - 日历与计划主页，已拆分瘦身。

/lib/screens/splash_screen.dart - 拦截第一帧，负责数据库初始化的安全缓冲。

Widgets (组件层)
/lib/widgets/inventory_location_bar.dart - (新增) 抽离的顶部位置切换滑动栏。

/lib/widgets/ingredient_edit_dialog.dart - (重构) 深度优化入库逻辑。采用 “速记+选填”分层布局，支持 实时重名检测预警 和全标签化 (ChoiceChip) 选择体验。

/lib/widgets/ingredient_card.dart - (重构) 极致空间压缩。支持 缺货状态一键补货 (Add to Cart) 闭环逻辑。

/lib/widgets/add_category_dialog.dart - 专用的快捷分类添加弹窗（适配联动传参）。

/lib/widgets/recipe_consume_dialog.dart - 针对单道菜谱的“迷你食材结算弹窗”。

Data & Logic (数据与逻辑)
/lib/providers/kitchen_provider.dart - 核心业务逻辑，现包含 PinyinHelper 排序算法。

/lib/services/database_service.dart - 隔离的 Hive 初始化服务。

/pubspec.yaml - 引入了 lpinyin 库，支持汉字转拼音的检索与排序。

已实现功能 (Features Completed)
Phase 1: 基础架构与防崩溃
[x] 全面引入 Riverpod 状态管理。

[x] 安全启动屏机制与异步隔离 Hive 初始化。

Phase 2: 极致库存与搜索交互 (Latest Update 🚀)
[x] 双向联动联动 (Scroll Spy)：左侧分类菜单与右侧列表实时同步，支持点击跳转与滑动感应。

[x] 全局上帝视角搜索：支持搜索全部位置的食材，适配 拼音首字母/全拼检索（如搜 pg 匹配 苹果）。

[x] 中英文混合 A-Z 排序：利用 lpinyin 实现分类与食材按拼音顺序优雅排列。

[x] 智能重名预警：入库时实时检测重名，支持自动合并旧数据，防止数据碎片化。

[x] 入库布局分层：将“名称、分类”等必填项置顶并上移保存按钮，实现“指哪打哪”的极速录入体验。

Phase 3: 分类管理与购物闭环
[x] 分组分类管理：支持分类的重命名、修改位置，并按位置区块化展示，逻辑清晰。

[x] 安全删除机制：删除分类前自动检测是否有食材占用，防止引发逻辑崩溃。

[x] 缺货一键加购：卡片智能识别状态，缺货食材自动显示购物车图标，实现“耗尽 -> 补货”的极简路径。

Phase 4: 智能日历与结算 (Previous)
[x] “吃完即算”结算闭环，支持将消耗食材一键转移至购物车 (ShoppingItem)。

[x] 菜谱详情页与日历页统一使用 CombinedMealPicker。

状态管理策略 (State Management Strategy)
Riverpod 作为核心大脑：通过 NotifierProvider 处理跨页面联动（例如：在分类管理中重命名分类 -> 自动同步到库存列表和入库弹窗）。

拼音排序逻辑：在数据流向下传递至 UI 之前，在 build 方法中实时进行拼音加权排序，确保 UI 呈现高度一致性。

防冲突锁：在处理复杂的联动滚动时，引入 _isManualScrolling 布尔锁，确保用户点击与系统自动滚动的反馈不会发生逻辑震荡。