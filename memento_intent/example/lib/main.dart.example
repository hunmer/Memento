import 'package:flutter/material.dart';
import 'package:memento_intent/memento_intent.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Intent 插件
  await MementoIntent.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MementoIntent _intent = MementoIntent.instance;

  @override
  void initState() {
    super.initState();
    _setupIntentCallbacks();
  }

  void _setupIntentCallbacks() {
    // 深度链接回调
    _intent.onDeepLink = (Uri uri) {
      debugPrint('收到深度链接: $uri');
      _showSnackBar('收到深度链接: $uri');
    };

    // 分享文本回调
    _intent.onSharedText = (String text) {
      debugPrint('收到分享文本: $text');
      _showSnackBar('收到分享文本: $text');
    };

    // 分享文件回调
    _intent.onSharedFiles = (List<SharedMediaFile> files) {
      debugPrint('收到分享文件: ${files.length} 个文件');
      for (var file in files) {
        debugPrint('  - ${file.path} (${file.type})');
      }
      _showSnackBar('收到 ${files.length} 个分享文件');
    };

    // Intent 数据回调
    _intent.onIntentData = (IntentData data) {
      debugPrint('收到 Intent 数据: ${data.toJson()}');
    };
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _registerScheme() async {
    final success = await _intent.registerDynamicScheme(
      scheme: 'memento',
      host: 'example.com',
      pathPrefix: '/app',
    );

    if (success) {
      _showSnackBar('Scheme 注册成功!');
    } else {
      _showSnackBar('Scheme 注册失败');
    }
  }

  Future<void> _unregisterScheme() async {
    final success = await _intent.unregisterDynamicScheme();

    if (success) {
      _showSnackBar('Scheme 注销成功!');
    } else {
      _showSnackBar('Scheme 注销失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memento Intent Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Memento Intent Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Memento Intent Plugin 示例',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _registerScheme,
                icon: const Icon(Icons.link),
                label: const Text('注册 Scheme'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _unregisterScheme,
                icon: const Icon(Icons.link_off),
                label: const Text('注销 Scheme'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '使用说明:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. 点击"注册 Scheme"来注册深度链接\n'
                        '2. 在浏览器中输入: memento://example.com/app\n'
                        '3. 观察应用接收到的深度链接\n'
                        '4. 从其他应用分享内容到本应用',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
