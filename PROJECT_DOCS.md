# My Kitchen - Rebuilding Project

## 当前架构 (Current Architecture)
- `/lib/main.dart` - 仅保留 runApp 和 UI Theme
- `/lib/providers/init_provider.dart` - 控制 App 启动流程和加载状态
- `/lib/screens/splash_screen.dart` - 拦截应用第一帧，负责数据库初始化的安全缓冲
- `/lib/services/database_service.dart` - 隔离的 Hive 数据库初始化服务
- `/lib/data/mock_database.dart` - (遗留层) 待进一步迁移
- `/lib/models/app_models.dart` - (遗留层) 纯数据模型，含 Hive 声明

## 已实现功能 (Features Completed)
- [x] Phase 1: 基础架构重构，引入 Riverpod
- [x] Phase 1: 安全的启动屏 (SplashScreen) 防白屏机制，带有自动错误恢复
- [x] Phase 1: 异步隔离 Hive 数据库的初始化逻辑

## 状态管理策略 (State Management Strategy)
- 核心框架迁移至 **Riverpod**。
- `FutureProvider` 被用于处理异步初始化和防奔溃状态拦截。