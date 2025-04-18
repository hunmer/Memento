import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'plugins/chat/l10n/chat_localizations.dart';
import 'plugins/day/l10n/day_localizations.dart';
// 移除未使用的导入
import 'core/plugin_manager.dart';
import 'core/storage/storage_manager.dart';
import 'core/config_manager.dart';
import 'screens/home_screen.dart';
import 'plugins/chat/chat_plugin.dart'; // 聊天插件
import 'plugins/diary/diary_plugin.dart'; // 日记插件
import 'plugins/activity/activity_plugin.dart'; // 活动插件
import 'plugins/checkin/checkin_plugin.dart'; // 打卡插件
import 'plugins/timer/timer_plugin.dart'; // 计时器插件
import 'plugins/todo/todo_plugin.dart'; // 任务插件
import 'plugins/day/day_plugin.dart'; // 纪念日插件
import 'plugins/nodes/nodes_plugin.dart'; // 笔记插件
import 'plugins/notes/notes_plugin.dart'; // Notes插件
import 'plugins/goods/goods_plugin.dart'; // 物品插件
import 'plugins/bill/bill_plugin.dart'; // 账单插件

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
    globalPluginManager.setStorageManager(globalStorage);
    debugPrint('初始化插件管理器...');

    // 注册内置插件
    debugPrint('注册内置插件...');
    final plugins = [
      ChatPlugin.instance,
      DiaryPlugin.instance,
      ActivityPlugin.instance,
      CheckinPlugin.instance,
      TimerPlugin.instance,
      TodoPlugin.instance,
      DayPlugin.instance,
      NodesPlugin(), // 添加笔记插件
      NotesPlugin(), // 添加Notes插件
      GoodsPlugin.instance, // 添加物品插件
      BillPlugin(), // 添加账单插件
    ];

    // 遍历并注册插件
    for (final plugin in plugins) {
      try {
        await globalPluginManager.registerPlugin(plugin);
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
      title: 'Memento',
      debugShowCheckedModeBanner: false, // 关闭调试横幅
      localizationsDelegates: [
        AppLocalizations.delegate,
        ChatLocalizations.delegate, // 添加聊天插件的本地化代理
        DayLocalizationsDelegate.delegate, // 添加纪念日插件的本地化代理
        NodesPlugin().localizationsDelegate, // 添加笔记插件的本地化代理
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', ''), // 中文
        Locale('en', ''), // 英文
      ],
      locale:
          globalConfigManager.getLocale() ??
          const Locale('en', ''), // 使用保存的语言设置，默认英文
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
      onGenerateTitle:
          (BuildContext context) => AppLocalizations.of(context)!.appTitle,
    );
  }
}
