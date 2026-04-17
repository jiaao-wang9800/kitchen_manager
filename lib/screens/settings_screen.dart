// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backup_service.dart';
import '../main.dart'; // 用于读取 isStardewTheme 状态

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // 预留的状态变量
  double _fontSize = 14.0;
  String _currentApi = 'OpenAI (默认)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('设置中心', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ==========================================
          // 1. 外观与个性化
          // ==========================================
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text('外观与个性化', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                // 1.1 切换主题
                ValueListenableBuilder<bool>(
                  valueListenable: isStardewTheme,
                  builder: (context, isStardew, child) {
                    return SwitchListTile(
                      title: const Text('复古像素主题 (Stardew)'),
                      subtitle: const Text('开启后厨房页将变为游戏像素风'),
                      value: isStardew,
                      activeColor: const Color(0xFF4A5D4E),
                      secondary: const Icon(Icons.palette_outlined, color: Colors.orange),
                      onChanged: (val) => isStardewTheme.value = val,
                    );
                  }
                ),
                const Divider(height: 1, indent: 56),
                // 1.2 调节字体 (UI演示)
                ListTile(
                  leading: const Icon(Icons.format_size, color: Colors.blueAccent),
                  title: const Text('全局字体大小'),
                  subtitle: Slider(
                    value: _fontSize,
                    min: 12.0, max: 24.0, divisions: 6,
                    activeColor: const Color(0xFF4A5D4E),
                    label: _fontSize.round().toString(),
                    onChanged: (val) => setState(() => _fontSize = val),
                  ),
                  trailing: Text('${_fontSize.round()} pt', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ==========================================
          // 2. AI 与 数据
          // ==========================================
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text('AI 与 数据', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                // 2.1 切换 API
                ListTile(
                  leading: const Icon(Icons.smart_toy_outlined, color: Colors.purple),
                  title: const Text('AI 引擎接口 (API)'),
                  subtitle: Text(_currentApi),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // 弹窗选择 API
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (c) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(padding: EdgeInsets.all(16.0), child: Text('选择 AI 引擎', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                            ListTile(title: const Text('OpenAI (默认)'), trailing: _currentApi.contains('OpenAI') ? const Icon(Icons.check, color: Colors.teal) : null, onTap: () { setState(() => _currentApi = 'OpenAI (默认)'); Navigator.pop(c); }),
                            ListTile(title: const Text('Claude 3'), trailing: _currentApi.contains('Claude') ? const Icon(Icons.check, color: Colors.teal) : null, onTap: () { setState(() => _currentApi = 'Claude 3'); Navigator.pop(c); }),
                            ListTile(title: const Text('自定义代理接口'), trailing: _currentApi.contains('自定义') ? const Icon(Icons.check, color: Colors.teal) : null, onTap: () { setState(() => _currentApi = '自定义代理接口'); Navigator.pop(c); }),
                          ],
                        ),
                      )
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                // 2.2 数据备份导出
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: Colors.teal),
                  title: const Text('备份并导出所有数据'),
                  subtitle: const Text('将厨房、菜谱和计划导出为 JSON 文件'),
                  trailing: const Icon(Icons.ios_share, color: Colors.grey),
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在生成备份文件...')));
                    await BackupService.exportAllData();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // 底部版本号
          const Center(
            child: Text('My Kitchen v2.0.0\nPowered by Riverpod', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        ],
      ),
    );
  }
}