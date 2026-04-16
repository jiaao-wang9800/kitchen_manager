// lib/widgets/stardew_panel.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // 引入 ThemeModeExtension

class StardewPanelContainer extends StatelessWidget {
  final Widget child;
  const StardewPanelContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final themeExt = Theme.of(context).extension<ThemeModeExtension>();
    final bool isStardew = themeExt?.isStardew ?? false;

    // 如果是现代风格（默认），直接返回纯白底色的内容，无任何装饰
    if (!isStardew) return Container(color: const Color(0xFFF8F9FA), child: child);

    // 星露谷风格装饰
    const Color darkWood = Color(0xFF5D3C1A);
    const Color mediumWood = Color(0xFF966C3D);
    const Color parchmentWarm = Color(0xFFF2E2C2);

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(2.0), 
      decoration: BoxDecoration(color: mediumWood, border: Border.all(color: darkWood, width: 4.0)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: mediumWood,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book, size: 16, color: darkWood), 
                const SizedBox(width: 8),
                Text('[kitchen inventory]', style: GoogleFonts.vt323(fontSize: 18, color: darkWood, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.menu_book, size: 16, color: darkWood), 
              ],
            ),
          ),
          Expanded(child: Container(color: parchmentWarm, child: child)),
        ],
      ),
    );
  }
}