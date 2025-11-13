import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../../core/js_bridge/js_bridge_manager.dart';

class JSConsoleController extends ChangeNotifier {
  String _code = '';
  String _output = '';
  bool _isRunning = false;
  Map<String, String> _examples = {};
  bool _examplesLoaded = false;

  String get code => _code;
  String get output => _output;
  bool get isRunning => _isRunning;
  Map<String, String> get examples => _examples;
  bool get examplesLoaded => _examplesLoaded;

  void setCode(String code) {
    _code = code;
    notifyListeners();
  }

  void clearOutput() {
    _output = '';
    notifyListeners();
  }

  Future<void> runCode() async {
    if (_isRunning) return;

    _isRunning = true;
    _output = '运行中...\n';
    notifyListeners();

    try {
      // 执行代码（evaluate 方法会自动处理 Promise）
      final result = await JSBridgeManager.instance.evaluate(_code);

      if (result.success) {
        // 格式化输出结果
        final resultStr = _formatResult(result.result);
        _output += '✓ 成功:\n$resultStr\n';
      } else {
        _output += '✗ 错误:\n${result.error}\n';
      }
    } catch (e) {
      _output += '✗ 异常:\n$e\n';
    } finally {
      _isRunning = false;
      notifyListeners();
    }
  }

  /// 格式化结果以便显示
  String _formatResult(dynamic result) {
    if (result == null) {
      return 'null';
    } else if (result is String) {
      return result;
    } else if (result is Map || result is List) {
      // 格式化 JSON 对象
      try {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(result);
      } catch (e) {
        return result.toString();
      }
    } else {
      return result.toString();
    }
  }

  /// 从 JSON 文件加载示例代码
  ///
  /// 示例文件位于 lib/screens/js_console/examples/
  /// 每个 JSON 文件包含一组相关的示例代码
  Future<void> loadExamples() async {
    if (_examplesLoaded) return;

    try {
      // 需要加载的示例文件列表
      final exampleFiles = [
        'lib/screens/js_console/examples/basic_examples.json',
        'lib/screens/js_console/examples/chat_examples.json',
      ];

      _examples = {};

      for (final filePath in exampleFiles) {
        try {
          // 加载 JSON 文件
          final jsonString = await rootBundle.loadString(filePath);
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

          // 解析示例
          final category = jsonData['category'] as String? ?? '未分类';
          final examples = jsonData['examples'] as List<dynamic>? ?? [];

          // 添加到 examples Map
          for (final example in examples) {
            if (example is Map<String, dynamic>) {
              final title = example['title'] as String?;
              final code = example['code'] as String?;

              if (title != null && code != null) {
                // 使用 "分类 - 标题" 作为键
                final key = category == '未分类' ? title : '$category - $title';
                _examples[key] = code;
              }
            }
          }

          print('✓ 已加载示例文件: $filePath (${examples.length} 个)');
        } catch (e) {
          print('✗ 加载示例文件失败: $filePath - $e');
        }
      }

      _examplesLoaded = true;
      print('✓ 示例加载完成，共 ${_examples.length} 个示例');
      notifyListeners();
    } catch (e) {
      print('✗ 加载示例失败: $e');
    }
  }

  /// 加载指定示例代码到编辑器
  void loadExample(String exampleKey) {
    _code = _examples[exampleKey] ?? '';
    notifyListeners();
  }
}
