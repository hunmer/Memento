import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/js_bridge/js_bridge_manager.dart';

class JSConsoleController extends ChangeNotifier {
  String _code = '';
  String _output = '';
  bool _isRunning = false;

  String get code => _code;
  String get output => _output;
  bool get isRunning => _isRunning;

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

  // 预设示例
  static const Map<String, String> examples = {
    '异步API测试': '''
// 方式3：async/await，自动捕获 return 值
(async function() {
  var result = await Memento.chat.testSync();
  console.log('结果:', result);
  return result;  // 自动捕获
})();
''',
    '获取所有频道': '''
// 获取所有聊天频道
(async function() {
  var channels = await Memento.chat.getChannels();
  setResult(channels);  // 使用 setResult 返回
})();
''',
    'setResult 高级用法': '''
// 演示 setResult 的多种用法
(async function() {
  console.log('开始测试...');

  // 1. 调用 API
  var result = await Memento.chat.testSync();
  console.log('API 返回:', result);

  // 2. 处理数据
  var processed = {
    original: result,
    timestamp: new Date().toISOString(),
    processed: true
  };

  // 3. 显式设置返回值
  setResult(processed);

  console.log('完成！');
})();
''',
    '创建新频道': '''
// 创建一个新的聊天频道（使用 await）
async function test() {
  var channel = await Memento.chat.createChannel('测试频道');
  console.log('创建成功:', channel);
  return channel;
}
test();
''',
    '发送消息': '''
// 先获取频道列表，然后发送消息（使用 await）
async function test() {
  var channels = await Memento.chat.getChannels();

  if (channels.length > 0) {
    var channelId = channels[0].id;

    // 发送消息
    var message = await Memento.chat.sendMessage(
      channelId,
      'Hello from JS!',
      'text'
    );

    console.log('消息已发送:', message);
    return message;
  } else {
    return '没有可用频道，请先创建';
  }
}
test();
''',
    '获取当前用户': '''
// 获取当前登录用户（使用 await）
async function test() {
  var user = await Memento.chat.getCurrentUser();
  console.log('当前用户:', user);
  return user;
}
test();
''',
    '获取频道消息': '''
// 获取第一个频道的消息（使用 await）
async function test() {
  var channels = await Memento.chat.getChannels();

  if (channels.length > 0) {
    var channelId = channels[0].id;
    var messages = await Memento.chat.getMessages(channelId, 5);
    console.log('最新5条消息:', messages);
    return messages;
  } else {
    return '没有可用频道';
  }
}
test();
''',
    '复杂操作示例': '''
// 复杂操作：创建频道并发送多条消息（使用 await）
async function test() {
  // 1. 创建频道
  var channel = await Memento.chat.createChannel('JS测试频道');
  console.log('频道已创建:', channel);

  // 2. 发送多条消息
  await Memento.chat.sendMessage(channel.id, '第一条消息', 'text');
  await Memento.chat.sendMessage(channel.id, '第二条消息', 'text');
  await Memento.chat.sendMessage(channel.id, '第三条消息', 'text');

  // 3. 获取消息
  var messages = await Memento.chat.getMessages(channel.id, 10);
  console.log('消息列表:', messages);

  // 4. 返回结果
  return '频道: ' + channel.name + ', 消息数: ' + messages.length;
}
test();
''',
  };

  void loadExample(String exampleKey) {
    _code = examples[exampleKey] ?? '';
    notifyListeners();
  }
}
