# 脚本中心集成 JS Bridge 系统 - 重构文档

**日期**: 2025-11-14
**版本**: 1.0
**作者**: Claude AI Assistant

---

## 📋 重构概述

### 问题背景

原先的脚本中心使用独立的 `flutter_js` 引擎来执行脚本，存在以下问题：

1. **API 隔离**：脚本无法访问 Memento 的插件 API（如 `Memento.chat.sendMessage()` 等）
2. **重复实现**：需要手动实现全局 API（log、storage、emit 等），与 JSBridgeManager 功能重复
3. **同步限制**：`flutter_js` 的消息机制是同步的，导致某些异步操作（如脚本互调）无法正常工作
4. **平台差异**：无法利用 JSBridgeManager 的平台适配能力（Web 用浏览器引擎，移动端用 QuickJS）

### 改进方案

将脚本执行引擎从独立的 `flutter_js` 迁移到 `JSBridgeManager`，实现：

1. ✅ **统一 JS 环境**：所有脚本和插件共享同一个 JS 运行时
2. ✅ **插件 API 访问**：脚本可以直接调用所有已注册插件的 JS API
3. ✅ **真正的异步**：支持 Promise、async/await 和脚本互调
4. ✅ **平台适配**：自动适配 Web、移动端、桌面端的 JS 引擎
5. ✅ **标准化**：使用 JSBridgeManager 的标准 API 注册机制

---

## 🔧 技术实现

### 核心变更

#### 1. 依赖调整

**之前 (script_executor.dart)**:
```dart
import 'package:flutter_js/flutter_js.dart';

class ScriptExecutor {
  late JavascriptRuntime _jsRuntime;

  Future<void> initialize() async {
    _jsRuntime = getJavascriptRuntime();
    _injectGlobalAPI();
  }
}
```

**之后**:
```dart
import '../../../core/js_bridge/js_bridge_manager.dart';

class ScriptExecutor {
  final JSBridgeManager _jsBridge = JSBridgeManager.instance;

  Future<void> initialize() async {
    if (!_jsBridge.isSupported) {
      throw Exception('JSBridgeManager 未初始化或不支持');
    }
    await _injectScriptCenterAPI();
  }
}
```

#### 2. API 注入机制

**之前**：手动注入全局 API (log, storage, emit 等)
```dart
void _injectGlobalAPI() {
  final globalAPIs = '''
    function log(message, level) { ... }
    const storage = { get: ..., set: ... };
    function emit(eventName, data) { ... }
  ''';
  _jsRuntime.evaluate(globalAPIs);
}
```

**之后**：利用 JSBridgeManager 的标准机制，只注入脚本中心特有的 API
```dart
Future<void> _injectScriptCenterAPI() async {
  final tempPlugin = _ScriptExecutorPlugin(this);
  final apis = {
    'runScript': _handleRunScript,
  };
  await _jsBridge.registerPlugin(tempPlugin, apis);

  // 全局快捷方式
  await _jsBridge.evaluate('''
    globalThis.runScript = globalThis.Memento.script_executor.runScript;
  ''');
}
```

#### 3. 脚本执行流程

**之前**：直接使用 `_jsRuntime.evaluate()`
```dart
final jsResult = _jsRuntime.evaluate(wrappedCode);
if (jsResult.isError) {
  throw Exception(jsResult.stringResult);
}
return jsResult.stringResult;
```

**之后**：使用 JSBridgeManager 的异步 API
```dart
final jsResult = await _jsBridge.evaluate(wrappedCode);
if (!jsResult.success) {
  throw Exception(jsResult.error ?? '未知错误');
}
return jsResult.result;
```

#### 4. 脚本互调

**之前**：由于同步限制，无法实现
```dart
String? _handleRunScript(String scriptId, List params) {
  print('⚠️ runScript功能需要异步支持，当前版本暂不支持');
  return jsonEncode({
    'success': false,
    'error': 'runScript功能暂不支持（需要异步支持）',
  });
}
```

**之后**：完全支持异步脚本互调
```dart
Future<dynamic> _handleRunScript(String scriptId, [dynamic params]) async {
  if (_executingScripts.contains(scriptId)) {
    throw Exception('检测到循环调用');
  }

  _executingScripts.add(scriptId);
  try {
    final result = await execute(scriptId, args: {'params': params});
    return result.success ? result.result : result.error;
  } finally {
    _executingScripts.remove(scriptId);
  }
}
```

---

## 🎯 功能对比

### 改进前

| 功能 | 支持情况 | 说明 |
|------|---------|------|
| 基础 JS 执行 | ✅ | 支持 ES6+ 语法 |
| 调用插件 API | ❌ | 无法访问 `Memento.chat.*` 等 |
| 脚本互调 | ❌ | 由于同步限制无法实现 |
| 全局 log/storage | ⚠️ | 需要手动实现 |
| 跨平台适配 | ⚠️ | 仅支持 QuickJS |
| 异步操作 | ⚠️ | 有限支持 |

### 改进后

| 功能 | 支持情况 | 说明 |
|------|---------|------|
| 基础 JS 执行 | ✅ | 支持 ES6+ 语法 |
| 调用插件 API | ✅ | 完全访问所有已注册的插件 API |
| 脚本互调 | ✅ | 支持 `await runScript(id, params)` |
| 全局 log/storage | ✅ | 由 JSBridgeManager 自动提供 |
| 跨平台适配 | ✅ | Web 用浏览器，移动端用 QuickJS |
| 异步操作 | ✅ | 完全支持 Promise/async/await |

---

## 📝 使用示例

### 在脚本中调用插件 API

```javascript
// 脚本文件: scripts/auto_chat/script.js
(async function() {
  // 1. 调用聊天插件 API
  const channels = await Memento.chat.getChannels();
  console.log('频道列表:', channels);

  // 2. 创建新频道
  const newChannel = await Memento.chat.createChannel('自动频道', 'normal');

  // 3. 发送消息
  await Memento.chat.sendMessage(
    newChannel.id,
    '这是脚本自动发送的消息',
    'text'
  );

  // 4. 调用其他插件 API（如果注册了）
  const diaryEntries = await Memento.diary.getEntries();
  const activities = await Memento.activity.getActivities();

  return {
    success: true,
    channelsCount: channels.length,
    createdChannel: newChannel.name
  };
})();
```

### 脚本互调示例

```javascript
// 脚本 A: data_exporter.js
(async function() {
  const data = await fetchDataFromSomewhere();
  return { data: data, timestamp: Date.now() };
})();

// 脚本 B: data_processor.js
(async function() {
  // 调用脚本 A 获取数据
  const exportResult = await runScript('data_exporter');

  // 处理数据
  const processed = processData(exportResult.data);

  // 保存到聊天频道
  await Memento.chat.sendMessage(
    'report_channel',
    `处理完成: ${processed.summary}`,
    'text'
  );

  return { success: true, processed: processed };
})();
```

---

## 🚀 迁移指南

### 对于现有脚本

如果您有使用旧版 API 的脚本，需要进行以下调整：

#### 1. 日志输出

**旧方式**:
```javascript
log('消息', 'info');
```

**新方式**:
```javascript
console.log('消息');  // 推荐
console.error('错误消息');
console.warn('警告消息');
```

#### 2. 数据存储

**旧方式**:
```javascript
const value = await storage.get('key');
await storage.set('key', value);
```

**新方式**:
```javascript
// 通过插件 API 访问存储
// 具体方式取决于各插件的实现
// 或使用脚本参数传递数据
```

#### 3. 事件触发

**旧方式**:
```javascript
emit('custom_event', { data: '...' });
```

**新方式**:
```javascript
// 使用插件提供的方法触发事件
// 或直接调用插件 API 执行操作
```

### 兼容性说明

- ✅ **完全兼容**：基础 JS 语法、async/await、Promise
- ⚠️ **需要调整**：log/storage/emit 等全局函数
- ✅ **新增功能**：调用插件 API、脚本互调

---

## 🐛 故障排除

### 问题 1: 脚本报错 "JSBridgeManager 未初始化"

**原因**: JS Bridge 系统未在应用启动时初始化

**解决方案**: 确保 `main.dart` 中包含以下代码：
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 JS Bridge
  await JSBridgeManager.instance.initialize();

  // 初始化其他服务...
  await globalStorage.initialize();

  runApp(MyApp());
}
```

### 问题 2: 无法调用插件 API

**原因**: 插件未注册 JS API

**解决方案**:
1. 确认插件实现了 `JSBridgePlugin` mixin
2. 插件的 `initialize()` 方法中调用 `await registerJSAPI()`
3. 检查 `defineJSAPI()` 方法是否返回了 API 映射

示例:
```dart
class MyPlugin extends BasePlugin with JSBridgePlugin {
  @override
  Map<String, Function> defineJSAPI() {
    return {
      'myMethod': _jsMyMethod,
    };
  }

  @override
  Future<void> initialize() async {
    // 其他初始化代码...

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  Future<String> _jsMyMethod() async {
    return jsonEncode({'status': 'ok'});
  }
}
```

### 问题 3: 脚本互调出现循环调用错误

**原因**: 脚本 A 调用 B，B 又调用 A

**解决方案**: 重新设计脚本调用关系，使用共享函数或参数传递代替循环调用

---

## 📚 相关文档

- [脚本中心实施计划](scripts_center_implementation_plan.md)
- [JS Bridge 系统文档](../lib/core/js_bridge/README.md)
- [示例脚本集合](script_examples/)
- [测试 Memento API 脚本](script_examples/test_memento_api.md)

---

## 🔄 版本历史

### v1.0 (2025-11-14)
- ✅ 完成从 flutter_js 到 JSBridgeManager 的迁移
- ✅ 实现脚本对插件 API 的完全访问
- ✅ 支持真正的异步脚本互调
- ✅ 创建示例脚本和文档
- ✅ 移除冗余的全局 API 实现

---

## 🙏 致谢

感谢 Memento 项目的开发者设计了优秀的 JS Bridge 架构，使得这次重构能够顺利完成。

---

**文档结束**
