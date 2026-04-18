My Kitchen - Rebuilding Project
当前架构 (Current Architecture)
/lib/main.dart - 仅保留 runApp 和 UI Theme

/lib/providers/init_provider.dart - 控制 App 启动流程和加载状态

/lib/providers/... - (新增) 包含 mealPlanProvider、inventoryProvider、cartProvider 等核心业务逻辑与状态分发

/lib/screens/splash_screen.dart - 拦截应用第一帧，负责数据库初始化的安全缓冲

/lib/screens/calendar_screen.dart - (重构) 日历与计划主页，已拆分瘦身

/lib/widgets/calendar_meal_list.dart - (新增) 抽离的每日三餐列表视图，负责渲染和打勾逻辑

/lib/widgets/combine_meal_picker.dart - (新增) 高度集成的紧凑版“安排计划”弹窗（左日历，右餐段）

/lib/widgets/recipe_consume_dialog.dart - (新增) 闭环核心组件：针对单道菜谱的“迷你食材结算弹窗”

/lib/services/database_service.dart - 隔离的 Hive 数据库初始化服务

/lib/data/mock_database.dart - 承担数据库初始化和默认模板注入（支持按名字去重机制）

/lib/data/my_initial_inventory.dart - (新增) 用户专属私有初始数据，包含精准的 DietaryGroup 划分

/lib/models/app_models.dart - 数据模型定义，已扩充 StorageLocation.pantry 和 MealPlan.isCompleted

已实现功能 (Features Completed)
Phase 1: 基础架构与防崩溃
[x] 基础架构重构，全面引入 Riverpod。

[x] 安全的启动屏 (SplashScreen) 防白屏机制，带有自动错误恢复。

[x] 异步隔离 Hive 数据库的初始化逻辑。

Phase 2: 高级库存管理 (Inventory Management)
[x] 架构扩充：底层模型与 UI 全面支持 StorageLocation.pantry (茶水间) 存储位置。

[x] 私有数据灌入：建立 my_initial_inventory.dart，支持批量导入自带完整宏量营养素 (Macros) 和膳食结构 (DietaryGroup) 的用户私有食材。

[x] 智能防重机制 (Upsert by Name)：数据库初始化时采用按“食材名称”去重的黄金逻辑，避免默认数据与用户私有数据发生冲突。

Phase 3: 智能日历与闭环结算 (Meal Planning & Consumption Loop)
[x] 高度一致的 UI 体验：菜谱详情页与日历页统一使用 CombinedMealPicker 进行计划安排。

[x] 日历页模块化：拆分复杂的长文件，将三餐列表渲染逻辑解耦至 CalendarMealList。

[x] “吃完即算”闭环：在日历打勾完成一顿饭时，自动呼出包含该菜谱所需食材的“迷你库存弹窗”进行结算。

[x] 无缝连招 (Inventory to Cart)：在结算弹窗中点击消耗食材时，系统智能拦截并弹出二次确认，支持一键将耗尽的食材转移至购物车 (ShoppingItem)。

状态管理策略 (State Management Strategy)
核心框架深度绑定 Riverpod。

FutureProvider 用于处理异步初始化和防奔溃状态拦截。

NotifierProvider / StateNotifierProvider 负责处理跨页面的联动刷新（如：点击库存消耗 -> 本地 Hive 更新 -> 触发 UI 列表自动划线变灰 -> 触发购物车角标数字更新），实现真正的响应式数据流。