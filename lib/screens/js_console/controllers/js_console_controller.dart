import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../../core/js_bridge/js_bridge_manager.dart';

/// 示例文件信息
class ExampleFile {
  final String name; // 文件名（显示用）
  final String path; // 文件路径
  final String category; // 分类

  ExampleFile({
    required this.name,
    required this.path,
    required this.category,
  });
}

class JSConsoleController extends ChangeNotifier {
  String _code = '';
  String _output = '';
  bool _isRunning = false;
  Map<String, String> _examples = {};
  bool _examplesLoaded = false;

  // 新增：文件相关属性
  List<ExampleFile> _exampleFiles = [];
  String? _selectedFilePath;
  Map<String, Map<String, String>> _examplesByFile = {}; // 按文件分组的示例

  String get code => _code;
  String get output => _output;
  bool get isRunning => _isRunning;
  Map<String, String> get examples => _examples;
  bool get examplesLoaded => _examplesLoaded;

  // 新增：文件选择相关 getter
  List<ExampleFile> get exampleFiles => _exampleFiles;
  String? get selectedFilePath => _selectedFilePath;

  /// 获取当前选中文件的示例
  Map<String, String> get currentFileExamples {
    if (_selectedFilePath == null) return _examples;
    return _examplesByFile[_selectedFilePath] ?? {};
  }

  void setCode(String code) {
    _code = code;
    notifyListeners();
  }

  void clearOutput() {
    _output = '';
    notifyListeners();
  }

  /// 选择示例文件
  void selectFile(String? filePath) {
    _selectedFilePath = filePath;
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
      final exampleFilePaths = [
        'lib/screens/js_console/examples/basic_examples.json',
        'lib/screens/js_console/examples/flutter_api_examples.json',
        'lib/screens/js_console/examples/chat_examples.json',
        'lib/screens/js_console/examples/activity_examples.json',
        'lib/screens/js_console/examples/bill_examples.json',
        'lib/screens/js_console/examples/calendar_examples.json',
        'lib/screens/js_console/examples/calendar_album_examples.json',
        'lib/screens/js_console/examples/checkin_examples.json',
        'lib/screens/js_console/examples/contact_examples.json',
        'lib/screens/js_console/examples/database_examples.json',
        'lib/screens/js_console/examples/day_examples.json',
        'lib/screens/js_console/examples/diary_examples.json',
        'lib/screens/js_console/examples/goods_examples.json',
        'lib/screens/js_console/examples/habits_examples.json',
        'lib/screens/js_console/examples/nodes_examples.json',
        'lib/screens/js_console/examples/notes_examples.json',
        'lib/screens/js_console/examples/openai_examples.json',
        'lib/screens/js_console/examples/store_examples.json',
        'lib/screens/js_console/examples/timer_examples.json',
        'lib/screens/js_console/examples/todo_examples.json',
        'lib/screens/js_console/examples/tracker_examples.json',
      ];

      _examples = {};
      _exampleFiles = [];
      _examplesByFile = {};

      for (final filePath in exampleFilePaths) {
        try {
          // 加载 JSON 文件
          final jsonString = await rootBundle.loadString(filePath);
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

          // 解析示例
          final category = jsonData['category'] as String? ?? '未分类';
          final examples = jsonData['examples'] as List<dynamic>? ?? [];

          // 创建文件信息对象
          filePath.split('/').last.replaceAll('_examples.json', '');
          final fileInfo = ExampleFile(
            name: category,
            path: filePath,
            category: category,
          );
          _exampleFiles.add(fileInfo);

          // 为这个文件创建示例 Map
          final fileExamples = <String, String>{};

          // 添加到 examples Map
          for (final example in examples) {
            if (example is Map<String, dynamic>) {
              final title = example['title'] as String?;
              final code = example['code'] as String?;

              if (title != null && code != null) {
                // 使用标题作为键（不再包含分类前缀）
                fileExamples[title] = code;

                // 全局示例仍使用 "分类 - 标题" 格式
                final globalKey = category == '未分类' ? title : '$category - $title';
                _examples[globalKey] = code;
              }
            }
          }

          // 存储按文件分组的示例
          _examplesByFile[filePath] = fileExamples;

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
    // 从当前选中的文件或全局示例中加载
    if (_selectedFilePath != null) {
      _code = _examplesByFile[_selectedFilePath]?[exampleKey] ?? '';
    } else {
      _code = _examples[exampleKey] ?? '';
    }
    notifyListeners();
  }
}
