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
      final result = await JSBridgeManager.instance.evaluate(_code);

      if (result.success) {
        _output += '✓ 成功:\n${result.result}\n';
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

  // 预设示例
  static const Map<String, String> examples = {
    '获取所有频道': '''
// 获取所有聊天频道
var channels = Memento.chat.getChannels();
console.log('频道列表:', channels);
channels;
''',
    '创建新频道': '''
// 创建一个新的聊天频道
var channel = Memento.chat.createChannel('测试频道');
console.log('创建成功:', channel);
channel;
''',
    '发送消息': '''
// 先获取频道列表
var channelsJson = Memento.chat.getChannels();
var channels = JSON.parse(channelsJson);

if (channels.length > 0) {
  var channelId = channels[0].id;

  // 发送消息
  var message = Memento.chat.sendMessage(
    channelId,
    'Hello from JS!',
    'text'
  );

  console.log('消息已发送:', message);
  message;
} else {
  '没有可用频道，请先创建';
}
''',
    '获取当前用户': '''
// 获取当前登录用户
var user = Memento.chat.getCurrentUser();
console.log('当前用户:', user);
user;
''',
    '获取频道消息': '''
// 获取第一个频道的消息
var channelsJson = Memento.chat.getChannels();
var channels = JSON.parse(channelsJson);

if (channels.length > 0) {
  var channelId = channels[0].id;
  var messages = Memento.chat.getMessages(channelId, 5);
  console.log('最新5条消息:', messages);
  messages;
} else {
  '没有可用频道';
}
''',
    '复杂操作示例': '''
// 1. 创建频道
var channelJson = Memento.chat.createChannel('JS测试频道');
var channel = JSON.parse(channelJson);

// 2. 发送多条消息
Memento.chat.sendMessage(channel.id, '第一条消息', 'text');
Memento.chat.sendMessage(channel.id, '第二条消息', 'text');
Memento.chat.sendMessage(channel.id, '第三条消息', 'text');

// 3. 获取消息
var messagesJson = Memento.chat.getMessages(channel.id, 10);
var messages = JSON.parse(messagesJson);

// 4. 返回结果
'频道: ' + channel.name + ', 消息数: ' + messages.length;
''',
  };

  void loadExample(String exampleKey) {
    _code = examples[exampleKey] ?? '';
    notifyListeners();
  }
}
