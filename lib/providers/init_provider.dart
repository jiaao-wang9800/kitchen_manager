// lib/providers/init_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

// FutureProvider 完美适配应用的异步初始化过程
final initProvider = FutureProvider<void>((ref) async {
  await DatabaseService.init();
});