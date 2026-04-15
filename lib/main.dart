// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'screens/splash_screen.dart'; // [修改] 导入刚建好的闪屏页

final ValueNotifier<bool> isStardewTheme = ValueNotifier<bool>(true); // 默认开启星露谷主题！

void main() {
  // 确保引擎初始化
  WidgetsFlutterBinding.ensureInitialized();

  // [移除] 所有关于 Hive.init() 和 initDatabase() 的阻塞调用，它们都搬到了 initProvider 里

  // 使用 ProviderScope 启动应用
  runApp(
    const ProviderScope(
      child: SmartRecipeApp(),
    ),
  );
}

class SmartRecipeApp extends StatelessWidget {
  const SmartRecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isStardewTheme,
      builder: (context, isStardew, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Recipe Manager',
          theme: isStardew ? _buildStardewTheme() : _buildModernTheme(),
          home: const SplashScreen(), // [关键修改] 首页现在是 SplashScreen，而不是 MainTabScreen
        );
      },
    );
  }

  // ==========================================
  // THEME A: STARDEW VALLEY (Pixel Art) - 保持不变
  // ==========================================
  ThemeData _buildStardewTheme() {
    const Color darkWood = Color(0xFF5D3C1A);
    const Color mediumWood = Color(0xFF966C3D);
    const Color parchmentWarm = Color(0xFFF2E2C2);
    const Color outlineColor = Color(0xFF3E2723);
    const Color coinGold = Color(0xFFD4A745);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkWood,
      textTheme: GoogleFonts.vt323TextTheme().apply(bodyColor: outlineColor, displayColor: outlineColor),
      appBarTheme: AppBarTheme(
        backgroundColor: mediumWood,
        titleTextStyle: GoogleFonts.vt323(fontSize: 32, color: coinGold, shadows: [const Shadow(offset: Offset(2, 2), color: outlineColor)]),
        iconTheme: const IconThemeData(color: coinGold),
        shape: const Border(bottom: BorderSide(color: outlineColor, width: 4)),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: outlineColor, width: 3)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: parchmentWarm,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: darkWood, width: 6)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: mediumWood,
        selectedItemColor: coinGold,
        unselectedItemColor: darkWood,
      ),
      extensions: const [ThemeModeExtension(isStardew: true)],
    );
  }

  // ==========================================
  // THEME B: MODERN MINIMALIST (Clean & Crisp) - 保持不变
  // ==========================================
  ThemeData _buildModernTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.teal,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      textTheme: GoogleFonts.interTextTheme(), 
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Colors.teal,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
      extensions: const [ThemeModeExtension(isStardew: false)],
    );
  }
}

class ThemeModeExtension extends ThemeExtension<ThemeModeExtension> {
  final bool isStardew;
  const ThemeModeExtension({required this.isStardew});

  @override
  ThemeExtension<ThemeModeExtension> copyWith({bool? isStardew}) => ThemeModeExtension(isStardew: isStardew ?? this.isStardew);

  @override
  ThemeExtension<ThemeModeExtension> lerp(ThemeExtension<ThemeModeExtension>? other, double t) => this;
}