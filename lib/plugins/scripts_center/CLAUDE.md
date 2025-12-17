 # 脚本中心插件 (Scripts Center) - AI 上下文文档

[根目录](../../../CLAUDE.md) > [plugins](../../) > **scripts_center**

> **变更记录 (Changelog)**
> - **2025-12-17T12:10:45+08:00**: 初始化脚本中心插件文档 - 完成架构分析、功能梳理和使用指南

---

## 模块职责

脚本中心插件是 Memento 的核心扩展机制，提供 JavaScript 脚本管理、执行和事件触发功能。允许用户编写自定义脚本来自动化任务、扩展功能，实现与其他插件的深度集成。

### 核心能力
- **脚本管理**: 创建、编辑、删除、启用/禁用脚本
- **多文件夹支持**: 组织和管理不同来源的脚本（用户脚本、示例脚本等）
- **事件驱动**: 响应系统事件自动执行脚本
- **脚本互调**: 支持脚本间的相互调用
- **参数化执行**: Module 类型脚本可接受用户输入参数
- **跨平台**: 支持 Web、移动端和桌面端的脚本执行

---

## 入口与启动

### 插件主类
```dart
// scripts_center_plugin.dart
class ScriptsCenterPlugin extends BasePlugin {
    static ScriptsCenterPlugin get instance; // 单例访问

    // 核心服务
    ScriptManager get scriptManager;
    ScriptExecutor get scriptExecutor;
}
```

### 初始化流程
1. 初始化三个核心服务（ScriptLoader、ScriptManager、ScriptExecutor）
2. 创建默认文件夹（"我的脚本"）
3. 加载当前文件夹的所有脚本
4. 设置事件触发器（延迟执行，确保其他插件已初始化）

### 文件夹系统
- **默认文件夹**: "我的脚本" - 用户脚本存储位置
- **扩展支持**: 可添加多个自定义文件夹
- **内置脚本**: 支持从 assets 加载示例脚本

---

## 对外接口

### 1. 脚本执行接口
```javascript
// 脚本中可用的全局 API
runScript(scriptId, params?)          // 调用其他脚本
log(message, level?)                  // 记录日志
emit(eventName, data)                 // 触发事件
```

### 2. Memento 插件 API 访问
通过 JSBridge 自动注入，脚本可直接访问：
```javascript
// 示例：访问其他插件的功能
await Memento.chat.sendMessage(channelId, message);
await Memento.diary.createEntry(title, content);
await Memento.todo.addTask(task);
```

### 3. 事件系统接口
```javascript
// 脚本接收事件参数
const args = {
    event: "event_name",
    eventData: {
        // 序列化后的事件数据
    }
};
```

---

## 关键依赖与配置

### 核心依赖
- **JSBridgeManager**: 提供统一的 JavaScript 执行环境
- **EventManager**: 事件的订阅与发布机制
- **StorageManager**: 脚本和配置的持久化存储

### 脚本目录结构
```
scripts/
├── {scriptId}/
│   ├── metadata.json      # 脚本元数据（配置）
│   └── script.js          # JavaScript 代码
```

### 元数据格式 (metadata.json)
```json
{
    "name": "脚本名称",
    "version": "1.0.0",
    "description": "脚本描述",
    "icon": "code",
    "author": "作者",
    "enabled": true,
    "type": "module",              // module | standalone
    "inputs": [],                  // 输入参数定义
    "triggers": []                 // 事件触发器配置
}
```

---

## 数据模型

### 1. ScriptInfo
脚本的核心元数据模型，包含：
- 基本信息：名称、版本、描述、作者
- 执行配置：启用状态、类型、输入参数
- 触发器配置：事件列表、延迟执行
- 文件路径和更新时间

### 2. ScriptTrigger
定义脚本如何被触发：
- event: 事件名称
- delay: 延迟执行时间（毫秒）
- condition: 条件判断（预留）

### 3. ScriptInput
定义模块类型脚本的输入参数：
- 支持 string、number、boolean、select 类型
- 必填验证和默认值
- 选项列表（select 类型）

### 4. ScriptFolder
文件夹配置模型：
- 支持内置和自定义文件夹
- 路径管理和启用状态
- 图标和描述信息

### 5. ScriptExecutionResult
执行结果封装：
- 成功/失败状态
- 返回值或错误信息
- 执行耗时统计

---

## 服务架构

### 1. ScriptLoader（加载器）
- 扫描脚本目录，解析 metadata.json
- 加载和保存脚本代码
- 创建新脚本模板
- Web 平台特殊处理（使用索引文件）

### 2. ScriptManager（管理器）
- 继承 ChangeNotifier，提供响应式状态管理
- CRUD 操作：创建、读取、更新、删除脚本
- 文件夹切换和管理
- 脚本搜索和筛选
- 代码缓存机制

### 3. ScriptExecutor（执行器）
- 基于 JSBridgeManager 的 JS 执行环境
- 支持异步执行和超时控制
- 循环调用检测
- 脚本间互调支持（runScript API）
- 事件数据深度序列化

---

## 界面组件

### 1. ScriptsListScreen
- 主界面：脚本列表展示
- 搜索和筛选功能
- 启用/禁用切换
- 手动执行脚本
- 统计信息展示

### 2. ScriptEditScreen
- 脚本编辑器
- 元数据配置
- 输入参数管理
- 触发器配置
- 代码编辑（内置格式化）

### 3. ScriptCard
- 脚本卡片组件
- 显示关键信息
- 快速操作按钮

### 4. ScriptRunDialog
- Module 类型脚本的参数输入界面
- 动态表单生成
- 参数验证

---

## 测试策略

### 测试文件位置
- 示例脚本：`examples/` 目录
- 测试指南：`examples/TEST_GUIDE.md`

### 测试覆盖要点
1. **基本功能**
   - 脚本 CRUD 操作
   - 启用/禁用切换
   - 手动执行

2. **事件系统**
   - 事件触发器配置
   - 事件数据序列化
   - 多触发器并发

3. **脚本互调**
   - runScript API 调用
   - 参数传递
   - 循环调用检测

4. **跨平台**
   - Web 环境执行
   - 移动端文件访问
   - 桌面端集成

---

## 常见问题 (FAQ)

### Q: 如何访问其他插件的功能？
A: 通过 JSBridge 自动注入的 Memento 对象：
```javascript
await Memento.chat.sendMessage(...)
await Memento.diary.createEntry(...)
```

### Q: 事件触发时如何获取数据？
A: 通过 args.eventData 访问序列化后的事件数据：
```javascript
const eventData = args.eventData;
console.log('事件数据:', eventData);
```

### Q: 如何调试脚本执行？
A: 使用 log 函数输出日志：
```javascript
log('调试信息', 'info');  // info | warn | error
```

### Q: 脚本执行超时怎么办？
A: 默认超时为 10 秒，可在 ScriptExecutor 初始化时调整：
```dart
ScriptExecutor(timeoutMilliseconds: 15000)  // 15秒
```

### Q: Web 平台和移动端的差异？
A: Web 平台使用索引文件管理脚本，移动端直接访问文件系统。API 保持一致。

---

## 相关文件清单

### 核心文件
- `scripts_center_plugin.dart` - 插件主类（442 行）
- `services/script_manager.dart` - 脚本管理服务（421 行）
- `services/script_executor.dart` - 脚本执行器（362 行）
- `services/script_loader.dart` - 脚本加载器（400 行）

### 数据模型
- `models/script_info.dart` - 脚本元数据模型（180 行）
- `models/script_trigger.dart` - 触发器模型（55 行）
- `models/script_input.dart` - 输入参数模型（149 行）
- `models/script_folder.dart` - 文件夹模型（98 行）
- `models/script_execution_result.dart` - 执行结果模型（87 行）

### 界面组件
- `screens/scripts_list_screen.dart` - 脚本列表（418 行）
- `screens/script_edit_screen.dart` - 脚本编辑器
- `widgets/script_card.dart` - 脚本卡片组件
- `widgets/script_run_dialog.dart` - 运行参数对话框
- `widgets/script_edit_dialog.dart` - 编辑对话框
- `widgets/script_input_edit_dialog.dart` - 输入参数编辑

### 国际化
- `l10n/scripts_center_translations.dart` - 翻译接口
- `l10n/scripts_center_translations_zh.dart` - 中文翻译
- `l10n/scripts_center_translations_en.dart` - 英文翻译

### 示例和文档
- `examples/TEST_GUIDE.md` - 测试指南（228 行）
- `examples/` - 示例脚本目录

---

## 扩展建议

### 1. 脚本市场
- 实现脚本的在线浏览和安装
- 版本管理和自动更新
- 评分和评论系统

### 2. 调试工具增强
- 可视化脚本执行流程
- 断点调试支持
- 性能分析工具

### 3. 安全机制
- 脚本权限控制
- API 访问白名单
- 恶意代码检测

### 4. 更多触发器类型
- 定时触发器（cron 表达式）
- 位置触发器
- 系统状态触发器

---

**最后更新**: 2025-12-17T12:10:45+08:00
**模块路径**: lib/plugins/scripts_center/
**总文件数**: 19
**代码行数**: 约 3000+ 行
**状态**: ✅ 已完成文档化