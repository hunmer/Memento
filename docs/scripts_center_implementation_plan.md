# JS脚本中心 - 详细实施计划

**项目**: Memento
**模块**: scripts_center 插件
**创建时间**: 2025-11-14
**预计工期**: 25-30 小时
**当前状态**: 📋 待开始

---

## 📝 项目概述

### 目标
创建一个插件化的JavaScript脚本中心，实现：
- 脚本文件的组织管理（JS + JSON 配对）
- 脚本列表展示与启用/禁用控制
- 脚本元数据编辑功能
- 手动执行和事件触发自动执行
- 脚本间调用能力
- 与 Memento 事件系统深度集成

### 核心特性
1. **脚本管理**: 子目录式组织，每个脚本独立文件夹
2. **元数据系统**: JSON配置文件记录脚本信息
3. **执行引擎**: 基于flutter_js的安全执行环境
4. **事件驱动**: 集成EventManager，支持自动触发
5. **脚本互调**: 内置runScript全局方法
6. **简洁UI**: Material Design 3风格界面

---

## ✅ 已确认的技术方案

### 技术选型决策

| 项目 | 选择方案 | 理由 |
|------|---------|------|
| **JS执行引擎** | flutter_js | 轻量级QuickJS引擎，支持ES6+，沙箱隔离良好，适合纯逻辑脚本 |
| **文件组织** | 子目录分组 | `scripts/script_name/` 结构，每个脚本独立目录，便于管理复杂脚本 |
| **代码编辑器** | 简单TextField | 只读显示 + "外部编辑器打开"按钮，实现简单，体验良好 |
| **安全策略** | 基础沙箱 | 依赖flutter_js自带隔离，不额外实现权限系统，快速上线 |
| **更新机制** | 暂不实现 | MVP版本专注核心功能，后续版本扩展 |

### 技术栈

- **框架**: Flutter 3.7+, Dart SDK
- **JS引擎**: flutter_js (QuickJS)
- **状态管理**: Provider + ChangeNotifier
- **存储**: 项目现有 StorageManager
- **UI组件**: Material Design 3
- **国际化**: 中英双语支持

---

## 📁 项目架构

### 目录结构

```
lib/plugins/scripts_center/
├── scripts_center_plugin.dart       # 插件主类（继承PluginBase）
│
├── models/                          # 数据模型层
│   ├── script_info.dart             # 脚本元数据模型
│   ├── script_trigger.dart          # 触发器模型
│   └── script_execution_result.dart # 执行结果模型
│
├── services/                        # 业务逻辑层
│   ├── script_loader.dart           # 脚本加载器（扫描目录，解析文件）
│   ├── script_manager.dart          # 脚本管理器（CRUD，状态管理）
│   └── script_executor.dart         # 脚本执行引擎（flutter_js封装）
│
├── screens/                         # 界面层
│   ├── scripts_list_screen.dart     # 脚本列表页
│   ├── script_detail_screen.dart    # 脚本详情/编辑页
│   └── components/                  # 子组件
│       ├── metadata_editor.dart     # 元数据编辑表单
│       └── script_card.dart         # 脚本卡片组件
│
└── l10n/                            # 国际化资源
    ├── scripts_localizations.dart    # 国际化基类
    ├── scripts_localizations_zh.dart # 中文资源
    └── scripts_localizations_en.dart # 英文资源
```

### 脚本存储结构

```
<app_documents>/scripts/
├── example_script/                  # 脚本1
│   ├── script.js                    # JavaScript代码
│   └── metadata.json                # 元数据配置
│
├── auto_backup/                     # 脚本2
│   ├── script.js
│   └── metadata.json
│
└── data_analyzer/                   # 脚本3
    ├── script.js
    ├── metadata.json
    └── helpers/                     # 可选：辅助文件
        └── utils.js
```

### 元数据JSON结构

```json
{
  "name": "示例脚本",
  "version": "1.0.0",
  "description": "这是一个示例脚本的说明",
  "icon": "code",
  "author": "作者名称",
  "updateUrl": "https://example.com/script/update.json",
  "enabled": true,
  "type": "module",
  "triggers": [
    {
      "event": "plugins_initialized",
      "delay": 1000
    },
    {
      "event": "diary_entry_created",
      "delay": 0
    }
  ]
}
```

---

## 📊 数据模型设计

### ScriptInfo 类

```dart
class ScriptInfo {
  final String id;              // 唯一标识（目录名）
  final String path;            // 脚本目录路径
  String name;                  // 脚本名称
  String version;               // 版本号
  String description;           // 描述
  String icon;                  // 图标名称
  String author;                // 作者
  String? updateUrl;            // 更新地址（可选）
  bool enabled;                 // 是否启用
  String type;                  // 类型：module | standalone
  List<ScriptTrigger> triggers; // 触发条件列表

  // 序列化方法
  Map<String, dynamic> toJson();
  factory ScriptInfo.fromJson(Map<String, dynamic> json);
}
```

### ScriptTrigger 类

```dart
class ScriptTrigger {
  final String event;                 // 事件名称（EventManager中的事件）
  final int? delay;                   // 延迟执行（毫秒）
  final Map<String, dynamic>? condition; // 可选：条件判断参数

  Map<String, dynamic> toJson();
  factory ScriptTrigger.fromJson(Map<String, dynamic> json);
}
```

### ScriptExecutionResult 类

```dart
class ScriptExecutionResult {
  final bool success;           // 是否成功
  final dynamic result;         // 返回值
  final String? error;          // 错误信息
  final Duration duration;      // 执行时长
  final DateTime timestamp;     // 执行时间戳
}
```

---

## 🔧 核心服务实现

### ScriptLoader 服务

**职责**: 扫描脚本目录，加载JS和JSON文件

**关键方法**:
```dart
class ScriptLoader {
  final StorageManager storage;

  // 扫描scripts/目录，返回所有脚本信息
  Future<List<ScriptInfo>> scanScripts();

  // 加载单个脚本的元数据
  Future<ScriptInfo?> loadScriptMetadata(String scriptPath);

  // 读取脚本代码
  Future<String?> loadScriptCode(String scriptPath);

  // 保存元数据
  Future<void> saveScriptMetadata(String scriptPath, ScriptInfo info);
}
```

**实现要点**:
- 使用StorageManager的目录操作能力
- 处理文件不存在、格式错误等异常
- 支持跨平台（移动端、Web、桌面）

### ScriptManager 服务

**职责**: 提供脚本CRUD操作和状态管理

**关键方法**:
```dart
class ScriptManager extends ChangeNotifier {
  List<ScriptInfo> _scripts = [];
  final ScriptLoader loader;

  // 加载所有脚本
  Future<void> loadScripts();

  // 获取所有脚本
  List<ScriptInfo> get scripts => _scripts;

  // 获取已启用的脚本
  List<ScriptInfo> getEnabledScripts();

  // 切换脚本启用状态
  Future<void> toggleScript(String id, bool enabled);

  // 保存脚本元数据
  Future<void> saveScriptMetadata(String id, ScriptInfo info);

  // 删除脚本
  Future<void> deleteScript(String id);

  // 根据ID获取脚本
  ScriptInfo? getScriptById(String id);
}
```

### ScriptExecutor 服务

**职责**: 封装flutter_js引擎，提供安全的JS执行环境

**关键方法**:
```dart
class ScriptExecutor {
  late JavascriptRuntime jsRuntime;
  final ScriptManager scriptManager;
  final StorageManager storage;
  final EventManager eventManager;

  // 初始化JS引擎
  Future<void> initialize();

  // 注入全局API
  void injectGlobalAPI();

  // 执行脚本
  Future<ScriptExecutionResult> execute(
    String scriptId,
    {Map<String, dynamic>? args}
  );

  // 清理引擎
  void dispose();
}
```

**全局API设计**:
```javascript
// 在JS环境中可用的全局方法

// 1. 执行其他脚本
runScript(scriptId, ...args) // 返回Promise

// 2. 日志输出
log(message, level = 'info') // level: info, warn, error

// 3. 数据存储
storage.get(key)             // 异步读取
storage.set(key, value)      // 异步写入
storage.remove(key)          // 异步删除

// 4. 事件系统
emit(eventName, data)        // 触发事件
subscribe(eventName, handler) // 订阅事件（慎用）

// 5. 工具方法
utils.formatDate(date, format)
utils.sleep(milliseconds)
```

---

## 🎨 界面设计

### 脚本列表页 (ScriptsListScreen)

**布局**:
```
┌─────────────────────────────────────┐
│ ← Scripts Center         [+]        │ ← AppBar
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 🟢 [图标] 自动备份脚本          │ │
│ │   v1.0.0 by hunmer              │ │ ← 脚本卡片
│ │   每日自动备份数据到WebDAV      │ │
│ │                         [启用▼] │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 🔴 [图标] 数据分析助手          │ │
│ │   v2.1.0 by AI                  │ │
│ │   分析活动数据并生成报告        │ │
│ │                         [禁用▶] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [空状态提示: 暂无脚本，点击+添加]  │
└─────────────────────────────────────┘
```

**功能**:
- 下拉刷新
- 脚本卡片显示：图标、名称、版本、作者、描述
- 启用/禁用开关（实时切换）
- 点击卡片进入详情页
- FAB按钮：添加新脚本

### 脚本详情页 (ScriptDetailScreen)

**布局**:
```
┌─────────────────────────────────────┐
│ ← 自动备份脚本      [保存] [删除]   │ ← AppBar
├─────────────────────────────────────┤
│ [元数据] [脚本代码] [执行日志]      │ ← TabBar
├─────────────────────────────────────┤
│ 【元数据标签页】                    │
│ 脚本名称: [自动备份脚本_______]     │
│ 版本号:   [1.0.0_______________]     │
│ 作者:     [hunmer______________]     │
│ 图标:     [backup______________]     │
│ 描述:                                │
│ [每日自动备份数据到WebDAV......]    │
│                                      │
│ 脚本类型: [module ▼]                │
│ 启用状态: [✓ 已启用]                │
│                                      │
│ 触发条件:                            │
│ + plugins_initialized (延迟1000ms)  │
│ + diary_entry_created (即时)        │
│ [+ 添加触发器]                       │
├─────────────────────────────────────┤
│          [尝试运行] [外部编辑器]     │ ← 底部操作栏
└─────────────────────────────────────┘
```

**功能**:
- 元数据编辑表单（保存时写入metadata.json）
- 脚本代码标签页：只读TextField + 行号显示
- "外部编辑器打开"按钮（使用系统默认编辑器）
- "尝试运行"按钮：立即执行并显示结果
- 执行日志标签页：显示历史执行记录

---

## 🔄 事件触发系统

### 触发流程

```
1. 插件初始化
   ├─ ScriptsCenterPlugin.initialize()
   ├─ 加载所有脚本元数据
   └─ 调用 _setupTriggers()

2. 设置触发器
   ├─ 遍历所有已启用的脚本
   ├─ 解析每个脚本的triggers配置
   └─ 订阅EventManager事件

3. 事件触发
   ├─ EventManager.broadcast(eventName, data)
   ├─ 匹配订阅的脚本
   ├─ 执行延迟（如有）
   ├─ ScriptExecutor.execute(scriptId, args: data)
   └─ 记录执行结果

4. 脚本互调
   ├─ JS代码中调用 runScript('other_script', param1, param2)
   ├─ 桥接到Dart层的ScriptExecutor
   ├─ 执行目标脚本
   └─ 返回结果到调用脚本
```

### EventManager集成示例

```dart
void _setupTriggers() {
  final enabledScripts = scriptManager.getEnabledScripts();

  for (var script in enabledScripts) {
    for (var trigger in script.triggers) {
      eventManager.subscribe(trigger.event, (data) async {
        // 延迟执行
        if (trigger.delay != null && trigger.delay! > 0) {
          await Future.delayed(Duration(milliseconds: trigger.delay!));
        }

        // 执行脚本
        try {
          final result = await scriptExecutor.execute(
            script.id,
            args: data as Map<String, dynamic>?
          );

          if (!result.success) {
            _logError('脚本执行失败: ${script.name}', result.error);
          }
        } catch (e) {
          _logError('脚本执行异常: ${script.name}', e.toString());
        }
      });
    }
  }
}
```

---

## 🧩 关键实现细节

### 1. flutter_js 引擎封装

```dart
// script_executor.dart 核心实现

class ScriptExecutor {
  late JavascriptRuntime _runtime;

  Future<void> initialize() async {
    _runtime = getJavascriptRuntime();
    _injectGlobalAPI();
  }

  void _injectGlobalAPI() {
    // 注入runScript方法
    _runtime.onMessage('runScript', (args) async {
      final scriptId = args[0] as String;
      final params = args.length > 1 ? args.sublist(1) : [];

      final result = await execute(scriptId, args: {
        'params': params
      });

      return result.success ? result.result : null;
    });

    // 注入log方法
    _runtime.onMessage('log', (args) {
      final message = args[0];
      final level = args.length > 1 ? args[1] : 'info';
      _log(message, level);
    });

    // 注入storage方法
    _runtime.onMessage('storage.get', (args) async {
      final key = args[0] as String;
      return await storage.read(key);
    });

    _runtime.onMessage('storage.set', (args) async {
      final key = args[0] as String;
      final value = args[1];
      await storage.write(key, value);
    });

    // 注入emit方法
    _runtime.onMessage('emit', (args) {
      final eventName = args[0] as String;
      final data = args.length > 1 ? args[1] : null;
      eventManager.broadcast(eventName, data);
    });
  }

  Future<ScriptExecutionResult> execute(
    String scriptId,
    {Map<String, dynamic>? args}
  ) async {
    final startTime = DateTime.now();

    try {
      // 读取脚本代码
      final code = await scriptManager.getScriptCode(scriptId);
      if (code == null) {
        throw Exception('脚本不存在');
      }

      // 注入参数
      final argsJson = jsonEncode(args ?? {});
      final wrappedCode = '''
        const args = $argsJson;
        (function() {
          $code
        })();
      ''';

      // 执行
      final result = _runtime.evaluate(wrappedCode);

      return ScriptExecutionResult(
        success: true,
        result: result.stringResult,
        error: null,
        duration: DateTime.now().difference(startTime),
        timestamp: startTime,
      );
    } catch (e) {
      return ScriptExecutionResult(
        success: false,
        result: null,
        error: e.toString(),
        duration: DateTime.now().difference(startTime),
        timestamp: startTime,
      );
    }
  }
}
```

### 2. 跨平台文件系统适配

```dart
// script_loader.dart 关键实现

Future<List<ScriptInfo>> scanScripts() async {
  final scriptsPath = await _getScriptsDirectory();
  final scriptsDir = Directory(scriptsPath);

  if (!await scriptsDir.exists()) {
    await scriptsDir.create(recursive: true);
    return [];
  }

  final List<ScriptInfo> scripts = [];

  // 遍历子目录
  await for (var entity in scriptsDir.list()) {
    if (entity is Directory) {
      final scriptId = path.basename(entity.path);
      final metadataPath = path.join(entity.path, 'metadata.json');
      final codePath = path.join(entity.path, 'script.js');

      // 检查必要文件
      if (await File(metadataPath).exists() &&
          await File(codePath).exists()) {
        try {
          final metadata = await loadScriptMetadata(scriptId);
          if (metadata != null) {
            scripts.add(metadata);
          }
        } catch (e) {
          print('加载脚本失败: $scriptId, 错误: $e');
        }
      }
    }
  }

  return scripts;
}

Future<String> _getScriptsDirectory() async {
  if (kIsWeb) {
    // Web平台使用IndexedDB模拟文件系统
    return 'scripts'; // 相对路径
  } else {
    // 移动端和桌面端
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path,  'app_data', 'scripts');
  }
}
```

### 3. 脚本互调实现

**JavaScript端**:
```javascript
// 在脚本中调用其他脚本
async function analyzeData() {
  // 获取日记数据
  const diaryData = await runScript('diary_exporter', {
    startDate: '2025-01-01',
    endDate: '2025-12-31'
  });

  // 调用数据分析脚本
  const result = await runScript('data_analyzer', diaryData);

  log(`分析结果: ${JSON.stringify(result)}`);
  return result;
}
```

**Dart端桥接**:
```dart
// 在ScriptExecutor中实现
_runtime.onMessage('runScript', (args) async {
  final targetScriptId = args[0] as String;
  final params = args.length > 1 ? args[1] : {};

  // 防止循环调用
  if (_isExecuting(targetScriptId)) {
    throw Exception('检测到循环调用: $targetScriptId');
  }

  _markExecuting(targetScriptId);

  try {
    final result = await execute(targetScriptId, args: params);
    return result.success ? result.result : throw Exception(result.error);
  } finally {
    _unmarkExecuting(targetScriptId);
  }
});
```

---

## 📋 实施步骤

### 阶段0：准备工作
- [x] 保存实施计划到文档
- [ ] 添加flutter_js依赖到pubspec.yaml
- [ ] 运行 flutter pub get

### 阶段1：基础架构 (预计3小时)
- [ ] 创建插件目录结构
- [ ] 创建数据模型类（ScriptInfo, ScriptTrigger, ExecutionResult）
- [ ] 实现ScriptsCenterPlugin主类骨架

### 阶段2：脚本管理核心 (预计6.5小时)
- [ ] 实现ScriptLoader服务（扫描子目录，加载JS和JSON）
- [ ] 实现ScriptManager服务（CRUD操作，状态管理）
- [ ] 跨平台文件系统适配

### 阶段3：UI界面开发 (预计6小时)
- [ ] 创建ScriptsListScreen界面（列表展示）
- [ ] 创建ScriptCard组件
- [ ] 创建ScriptDetailScreen界面（元数据编辑）
- [ ] 实现"外部编辑器打开"功能

### 阶段4：执行引擎与事件集成 (预计6小时)
- [ ] 实现ScriptExecutor服务（flutter_js引擎封装）
- [ ] 注入全局API（runScript, log, storage, emit）
- [ ] 集成EventManager事件触发系统
- [ ] 实现手动执行功能（尝试运行按钮）
- [ ] 实现脚本互调功能

### 阶段5：完善与优化 (预计3.5小时)
- [ ] 异常处理和日志系统
- [ ] 添加国际化资源（中英双语）
- [ ] 在main.dart中注册插件
- [ ] 测试和调试

---

## 🧪 测试计划

### 单元测试（可选）
- [ ] ScriptInfo模型序列化测试
- [ ] ScriptLoader加载功能测试
- [ ] ScriptExecutor执行结果测试

### 集成测试
- [ ] 脚本加载流程完整性
- [ ] 事件触发准确性
- [ ] 脚本互调功能

### 手动测试清单
- [ ] 创建示例脚本（auto_backup.js）
- [ ] 测试脚本列表展示
- [ ] 测试启用/禁用切换
- [ ] 测试元数据编辑和保存
- [ ] 测试手动执行功能
- [ ] 测试事件自动触发
- [ ] 测试脚本互调（runScript）
- [ ] 测试全局API（log, storage, emit）
- [ ] 测试跨平台兼容性（Android, iOS, Web, Desktop）
- [ ] 测试异常情况（文件缺失、JSON格式错误、JS语法错误）

---

## 📝 示例脚本

### 示例1：自动备份脚本

**metadata.json**:
```json
{
  "name": "自动备份助手",
  "version": "1.0.0",
  "description": "每天自动备份数据到WebDAV",
  "icon": "backup",
  "author": "hunmer",
  "updateUrl": null,
  "enabled": true,
  "type": "module",
  "triggers": [
    {
      "event": "app_daily_check",
      "delay": 5000
    }
  ]
}
```

**script.js**:
```javascript
// 自动备份脚本
(async function() {
  log('开始执行自动备份...', 'info');

  try {
    // 获取备份配置
    const config = await storage.get('backup_config');

    if (!config || !config.enabled) {
      log('自动备份未启用', 'warn');
      return;
    }

    // 触发WebDAV同步
    emit('webdav_sync_requested', {
      source: 'auto_backup_script',
      timestamp: new Date().toISOString()
    });

    log('备份任务已触发', 'info');

    // 记录备份历史
    const history = await storage.get('backup_history') || [];
    history.push({
      timestamp: new Date().toISOString(),
      status: 'success'
    });
    await storage.set('backup_history', history);

    return { success: true, message: '备份完成' };
  } catch (error) {
    log(`备份失败: ${error}`, 'error');
    return { success: false, error: error.toString() };
  }
})();
```

### 示例2：数据分析脚本

**metadata.json**:
```json
{
  "name": "数据分析助手",
  "version": "1.0.0",
  "description": "分析日记数据并生成统计报告",
  "icon": "analytics",
  "author": "AI",
  "updateUrl": null,
  "enabled": false,
  "type": "module",
  "triggers": []
}
```

**script.js**:
```javascript
// 数据分析脚本（可被其他脚本调用）
(async function() {
  const { startDate, endDate } = args;

  log(`分析日期范围: ${startDate} - ${endDate}`);

  // 调用日记导出脚本获取数据
  const diaryData = await runScript('diary_exporter', { startDate, endDate });

  // 分析数据
  const totalEntries = diaryData.length;
  const avgWordCount = diaryData.reduce((sum, entry) => sum + entry.wordCount, 0) / totalEntries;

  const report = {
    period: { startDate, endDate },
    totalEntries,
    avgWordCount,
    generatedAt: new Date().toISOString()
  };

  log(`分析完成: ${totalEntries}条日记，平均${Math.round(avgWordCount)}字`);

  return report;
})();
```

---

## 🚨 风险与注意事项

### 技术风险

1. **flutter_js性能问题**
   - 风险：复杂脚本可能导致UI卡顿
   - 缓解：实现执行超时（默认5秒），提供"后台执行"选项

2. **跨平台兼容性**
   - 风险：Web端IndexedDB限制，iOS JIT限制
   - 缓解：优先支持移动端/桌面，Web端标记为实验性

3. **脚本安全性**
   - 风险：恶意脚本访问敏感数据
   - 缓解：基础沙箱隔离，限制文件系统访问范围

4. **循环调用死锁**
   - 风险：runScript相互调用导致死锁
   - 缓解：维护执行栈，检测并阻止循环调用

### 开发风险

1. **依赖更新**
   - flutter_js可能版本不兼容
   - 建议：锁定依赖版本，详细测试

2. **存储空间占用**
   - 大量脚本文件占用存储
   - 缓解：显示存储统计，提供清理工具

---

## 📚 参考资料

### 依赖文档
- flutter_js: https://pub.dev/packages/flutter_js
- Provider: https://pub.dev/packages/provider
- path_provider: https://pub.dev/packages/path_provider

### 项目相关
- Memento 插件开发规范: `/CLAUDE.md`
- EventManager 事件列表: `lib/core/event/event_manager.dart`
- StorageManager API: `lib/core/storage/storage_manager.dart`

### JavaScript API参考
- QuickJS引擎: https://bellard.org/quickjs/
- ES6+ 语法: https://es6.ruanyifeng.com/

---

## ✅ 验收标准

### 功能验收
- [ ] 能够扫描并加载脚本目录中的所有脚本
- [ ] 脚本列表正确显示所有元数据信息
- [ ] 启用/禁用开关实时生效
- [ ] 元数据编辑功能完整且保存正确
- [ ] 手动执行按钮能成功运行脚本并显示结果
- [ ] 事件触发系统正确响应EventManager事件
- [ ] 脚本互调功能正常工作（无循环调用）
- [ ] 全局API（log, storage, emit, runScript）全部可用

### 性能验收
- [ ] 脚本列表加载时间 < 1秒（10个脚本以内）
- [ ] 单个脚本执行响应时间 < 500ms（简单脚本）
- [ ] UI操作无明显卡顿

### 兼容性验收
- [ ] Android 平台正常运行
- [ ] iOS 平台正常运行
- [ ] Windows 桌面平台正常运行
- [ ] macOS 桌面平台正常运行
- [ ] Web 平台基本功能可用（标记实验性）

### 代码质量验收
- [ ] 符合项目Lint规范（flutter_lints）
- [ ] 关键方法有注释说明
- [ ] 异常处理完善
- [ ] 无明显内存泄漏

---

## 🎯 未来扩展方向

### V2.0 计划功能
- [ ] 脚本更新检查功能（基于updateUrl）
- [ ] 脚本市场/分享功能
- [ ] 权限白名单系统
- [ ] 完整的代码编辑器（语法高亮、自动补全）
- [ ] 脚本调试工具（断点、单步执行）
- [ ] 性能监控面板
- [ ] 脚本依赖管理（npm模块支持）

### V3.0 愿景
- [ ] 可视化脚本编辑器（拖拽式）
- [ ] AI辅助脚本生成
- [ ] 云端脚本同步
- [ ] 多语言支持（Python, Lua等）

---

**文档版本**: v1.0
**最后更新**: 2025-11-14
**负责人**: Claude (AI Assistant)
**项目状态**: 📋 准备阶段 → 🚧 开发中
