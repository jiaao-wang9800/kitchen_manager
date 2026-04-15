// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/init_provider.dart';
import 'main_tab_screen.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听初始化状态
    final initStatus = ref.watch(initProvider);

    return initStatus.when(
      // 1. 成功：直接返回主屏幕
      data: (_) => const MainTabScreen(),
      
      // 2. 加载中：展示星露谷风格的过渡页
      loading: () => Scaffold(
        backgroundColor: const Color(0xFF5D3C1A), // 深木色
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFD4A745)), // 金币黄
              const SizedBox(height: 24),
              Text(
                'Loading Kitchen...',
                style: GoogleFonts.vt323(
                  color: const Color(0xFFF2E2C2), // 羊皮纸色
                  fontSize: 32,
                ),
              ),
            ],
          ),
        ),
      ),
      
      // 3. 失败：展示错误并提供重试机制 (绝对不能只给白屏)
      error: (err, stack) => Scaffold(
        backgroundColor: Colors.red[900],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 64),
                const SizedBox(height: 16),
                Text(
                  '厨房出了点问题：\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(initProvider), // 点击重新尝试初始化
                  child: const Text('重新启动'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}