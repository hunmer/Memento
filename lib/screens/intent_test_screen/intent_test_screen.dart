import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:memento_intent/memento_intent.dart';
class IntentTestScreen extends StatefulWidget {
  const IntentTestScreen({super.key});

  @override
  State<IntentTestScreen> createState() => _IntentTestScreenState();
}

class _IntentTestScreenState extends State<IntentTestScreen> {
  final MementoIntent _intent = MementoIntent.instance;

  // 测试状态
  String _platformVersion = 'Unknown';
  bool _isSchemeRegistered = false;
  List<String> _registeredSchemes = [];

  // 输入字段
  final TextEditingController _schemeController = TextEditingController();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _pathPrefixController = TextEditingController();

  // 日志
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    // 初始化插件
    await _intent.init();

    // 设置回调
    _intent.onDeepLink = (Uri uri) {
      _addLog('📱 收到深度链接: $uri');
    };

    _intent.onSharedText = (String text) {
      _addLog('📝 收到分享文本: $text');
    };

    _intent.onSharedFiles = (List<SharedMediaFile> files) {
      _addLog('📎 收到分享文件: ${files.length} 个文件');
      for (var file in files) {
        _addLog('   - ${file.path} (${file.type})');
      }
    };

    _intent.onIntentData = (IntentData data) {
      _addLog('🎯 收到 Intent 数据:');
      _addLog('   Action: ${data.action}');
      _addLog('   Data: ${data.data}');
      _addLog('   Type: ${data.type}');
      if (data.extras != null) {
        _addLog('   Extras: ${data.extras}');
      }
    };

    // 获取平台版本
    final version = await _intent.getPlatformVersion();
    setState(() {
      _platformVersion = version ?? 'Unknown';
    });

    // 加载已注册的 schemes
    _loadRegisteredSchemes();
  }

  void _loadRegisteredSchemes() async {
    final schemes = await _intent.getDynamicSchemes();
    setState(() {
      _registeredSchemes = schemes;
      _isSchemeRegistered = schemes.isNotEmpty;
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(
        0,
        '[${DateTime.now().toString().split(' ')[1].substring(0, 8)}] $message',
      );
      if (_logs.length > 100) {
        _logs.removeLast();
      }
    });

    // 自动滚动
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _registerScheme() async {
    final scheme = _schemeController.text.trim();
    if (scheme.isEmpty) {
      _addLog('❌ 错误: Scheme 不能为空');
      return;
    }

    final host =
        _hostController.text.trim().isNotEmpty
            ? _hostController.text.trim()
            : null;
    final pathPrefix =
        _pathPrefixController.text.trim().isNotEmpty
            ? _pathPrefixController.text.trim()
            : null;

    _addLog('🔄 正在注册 Scheme: $scheme');
    if (host != null) _addLog('   Host: $host');
    if (pathPrefix != null) _addLog('   Path Prefix: $pathPrefix');

    final success = await _intent.registerDynamicScheme(
      scheme: scheme,
      host: host,
      pathPrefix: pathPrefix,
    );

    if (success) {
      _addLog('✅ Scheme 注册成功!');
      setState(() {
        _isSchemeRegistered = true;
      });
      _loadRegisteredSchemes();
    } else {
      _addLog('❌ Scheme 注册失败');
    }
  }

  Future<void> _unregisterScheme() async {
    _addLog('🔄 正在注销 Scheme...');

    final success = await _intent.unregisterDynamicScheme();

    if (success) {
      _addLog('✅ Scheme 注销成功!');
      setState(() {
        _isSchemeRegistered = false;
      });
      _loadRegisteredSchemes();
    } else {
      _addLog('❌ Scheme 注销失败');
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  void _testScheme(String scheme) {
    // 构建测试 URI
    final testUri = Uri.parse('$scheme://test');
    _addLog('🧪 测试 Scheme: $scheme');
    _addLog('   生成的测试 URI: $testUri');

    // 手动触发 onDeepLink 回调来模拟接收深度链接
    _intent.onDeepLink?.call(testUri);
    _addLog('✅ 已触发测试回调');
  }

  void _showQuickRegisterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('screens_quickRegisterIntent'.tr),
          content: Text(
            'screens_selectPresetIntentType'.tr,
          ),
          actions: <Widget>[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _quickRegister('memento', null, '/test');
                },
                icon: const Icon(Icons.link),
                label: Text('screens_mementoTest'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _quickRegister('memento', 'app.example.com', '/open');
                },
                icon: const Icon(Icons.link),
                label: Text('screens_mementoComplete'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _quickRegister('myapp', 'custom.host', null);
                },
                icon: const Icon(Icons.link),
                label: Text('screens_customApp'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('screens_cancel'.tr),
            ),
          ],
        );
      },
    );
  }

  Future<void> _quickRegister(String scheme, String? host, String? pathPrefix) async {
    _addLog('🚀 快速注册 Intent');
    _addLog('   Scheme: $scheme');
    if (host != null) _addLog('   Host: $host');
    if (pathPrefix != null) _addLog('   Path Prefix: $pathPrefix');

    final success = await _intent.registerDynamicScheme(
      scheme: scheme,
      host: host,
      pathPrefix: pathPrefix,
    );

    if (success) {
      _addLog('✅ 快速注册成功!');
      setState(() {
        _isSchemeRegistered = true;
      });
      _loadRegisteredSchemes();

      // 自动填充表单
      _schemeController.text = scheme;
      _hostController.text = host ?? '';
      _pathPrefixController.text = pathPrefix ?? '';
    } else {
      _addLog('❌ 快速注册失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('screens_intentTest'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearLogs,
            tooltip: '清空日志',
          ),
        ],
      ),
      body: Column(
        children: [
          // 平台信息卡片
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 8),
                      Text(
                        '平台: $_platformVersion',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.link,
                        color: _isSchemeRegistered ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Scheme 状态: ${_isSchemeRegistered ? '已注册' : '未注册'}',
                        style: TextStyle(
                          color:
                              _isSchemeRegistered ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Scheme 注册/注销卡片
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '动态 Scheme 注册',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _schemeController,
                    decoration: const InputDecoration(
                      labelText: 'Scheme (必填)',
                      hintText: '例如: myapp',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                      labelText: 'Host (可选)',
                      hintText: '例如: example.com',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pathPrefixController,
                    decoration: const InputDecoration(
                      labelText: 'Path Prefix (可选)',
                      hintText: '例如: /app',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showQuickRegisterDialog(),
                          icon: const Icon(Icons.flash_on),
                          label: Text(
                            'screens_quickRegister'.tr,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isSchemeRegistered
                                  ? _unregisterScheme
                                  : _registerScheme,
                          icon: Icon(
                            _isSchemeRegistered ? Icons.link_off : Icons.link,
                          ),
                          label: Text(
                            _isSchemeRegistered ? '注销 Scheme' : '注册 Scheme',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isSchemeRegistered ? Colors.red : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_registeredSchemes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '已注册的 Schemes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          ..._registeredSchemes.map(
                            (scheme) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      ScreensLocalizations.of(
                                        context,
                                      ).bulletScheme(scheme),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _testScheme(scheme),
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      '测试',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 日志区域
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '日志',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _logs[index],
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _schemeController.dispose();
    _hostController.dispose();
    _pathPrefixController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
