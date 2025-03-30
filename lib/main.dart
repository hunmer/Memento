import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'core/plugin_manager.dart';
import 'core/storage/storage_manager.dart';
import 'core/config_manager.dart';
import 'screens/home_screen.dart';
import 'plugins/chat/chat_plugin.dart'; // 聊天插件
import 'plugins/diary/diary_plugin.dart'; // 日记插件
import 'plugins/activity/activity_plugin.dart'; // 活动插件

// 全局单例实例
late final StorageManager globalStorage;
late final ConfigManager globalConfigManager;
late final PluginManager globalPluginManager;

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 设置首选方向为竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // 创建并初始化存储管理器（内部会处理Web平台的情况）
    globalStorage = StorageManager();
    debugPrint('初始化存储管理器...');
    await globalStorage.initialize();
    debugPrint('存储管理器初始化完成');

    // 初始化配置管理器
    globalConfigManager = ConfigManager(globalStorage);
    debugPrint('初始化配置管理器...');
    await globalConfigManager.initialize();
    debugPrint('配置管理器初始化完成');

    // 获取插件管理器单例实例
    globalPluginManager = PluginManager();
    debugPrint('初始化插件管理器...');

    // 注册内置插件
    debugPrint('注册内置插件...');
    final plugins = [
      ChatPlugin.instance,
      DiaryPlugin.instance,
      ActivityPlugin.instance,
    ];

    // 遍历并注册插件
    for (final plugin in plugins) {
      try {
        plugin.setStorageManager(globalStorage);
        await plugin.registerToApp(globalPluginManager, globalConfigManager);
        debugPrint('插件注册成功: ${plugin.name}');
      } catch (e) {
        debugPrint('插件注册失败: ${plugin.name} - $e');
      }
    }
  } catch (e) {
    debugPrint('初始化失败: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat App',
      debugShowCheckedModeBanner: false, // 关闭调试横幅
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        cardTheme: const CardTheme(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        ),
      ),
      builder: (context, child) {
        // 确保字体大小不受系统设置影响
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}
