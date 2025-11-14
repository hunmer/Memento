# 小组件配置持久化问题诊断指南

## 问题描述
小组件的显示风格（一列/两列）在重启应用后会丢失，总是恢复为默认的两列布局。

## 可能的原因

### 1. 配置保存失败
- 配置文件没有被正确写入磁盘
- 配置文件写入时出现错误但被捕获

### 2. 配置加载失败
- 配置文件格式不正确
- 序列化/反序列化过程中出现类型转换错误
- 配置键名不匹配

### 3. 配置没有被应用
- 配置正确加载但没有传递给组件
- 组件使用了错误的配置源

## 诊断步骤

### 步骤 1: 查看调试日志

我已经在以下位置添加了调试日志：

1. **保存配置时** (`home_screen.dart:653-657`)
   - 打印 widgetId
   - 打印 displayStyle
   - 打印完整的 config JSON

2. **加载配置时** (`home_layout_manager.dart:90`)
   - 打印每个 widget 的 widgetId
   - 打印完整的 config

3. **解析配置时** (`activity/home_widgets.dart:95-108`)
   - 打印收到的 config
   - 打印是否找到 pluginWidgetConfig
   - 打印解析结果

### 步骤 2: 运行应用并操作

1. 运行应用（Windows 版本）：
   ```bash
   flutter run -d windows
   ```

2. 修改一个小组件的显示风格：
   - 找到一个 2x2 的小组件（如"活动概览"）
   - 长按小组件 → 选择"设置"
   - 将"显示风格"从"两列"改为"一列"
   - 点击"确认"

3. 观察控制台输出，应该看到类似：
   ```
   [Home Screen] 保存配置：
   [Home Screen] - widgetId: activity_overview
   [Home Screen] - displayStyle: PluginWidgetDisplayStyle.oneColumn
   [Home Screen] - config JSON: {displayStyle: 0, selectedItemIds: [...], ...}
   [Home Screen] - updatedConfig: {pluginWidgetConfig: {displayStyle: 0, ...}}
   Home layout saved: X items, grid: 4, alignment: top
   ```

4. 重启应用

5. 观察启动时的日志，应该看到：
   ```
   [Layout Manager] 加载 widget: activity_overview, config: {pluginWidgetConfig: {displayStyle: 0, ...}}
   [Activity Widget] 收到的 config: {pluginWidgetConfig: {displayStyle: 0, ...}}
   [Activity Widget] 找到 pluginWidgetConfig: {displayStyle: 0, ...}
   [Activity Widget] 解析成功，displayStyle: PluginWidgetDisplayStyle.oneColumn
   ```

### 步骤 3: 检查配置文件

配置文件位置取决于平台：

**Windows:**
```
C:\Users\<用户名>\AppData\Roaming\Memento\configs\home_layout\settings.json
```

打开文件，查找对应的 widget 配置，确认 `pluginWidgetConfig` 是否存在：

```json
{
  "items": [
    {
      "id": "item_xxx",
      "type": "widget",
      "widgetId": "activity_overview",
      "size": {"width": 2, "height": 2},
      "config": {
        "pluginWidgetConfig": {
          "displayStyle": 0,  // 0 = 一列, 1 = 两列
          "selectedItemIds": [...],
          ...
        }
      }
    }
  ]
}
```

## 可能的修复方案

### 方案 1: 确保配置键名一致

检查所有插件的 `home_widgets.dart`，确保都使用 `'pluginWidgetConfig'` 作为键名。

### 方案 2: 添加配置版本号

在 `PluginWidgetConfig` 中添加版本号，以便处理配置迁移：

```dart
class PluginWidgetConfig {
  static const int currentVersion = 1;
  final int version;

  PluginWidgetConfig({
    this.version = currentVersion,
    // ... 其他字段
  });

  factory PluginWidgetConfig.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;
    // 根据版本号进行迁移
    return PluginWidgetConfig(
      version: version,
      // ... 其他字段
    );
  }
}
```

### 方案 3: 添加配置验证

在保存前验证配置是否可以正确序列化/反序列化：

```dart
// 在 home_screen.dart 中
final updatedConfig = Map<String, dynamic>.from(item.config);
updatedConfig['pluginWidgetConfig'] = result.toJson();

// 验证配置
try {
  final testConfig = PluginWidgetConfig.fromJson(
    updatedConfig['pluginWidgetConfig'] as Map<String, dynamic>
  );
  assert(testConfig.displayStyle == result.displayStyle);
} catch (e) {
  debugPrint('配置验证失败: $e');
  // 显示错误提示
  return;
}

final updatedItem = item.copyWith(config: updatedConfig);
// ... 保存
```

## 常见错误及解决方法

### 错误 1: `type 'String' is not a subtype of type 'int'`

**原因**: JSON 序列化时，枚举值被转换为字符串而不是索引

**解决**: 确保 `toJson` 使用 `.index`，`fromJson` 使用 `values[index]`

```dart
// toJson
'displayStyle': displayStyle.index,  // ✓ 正确

// fromJson
displayStyle: PluginWidgetDisplayStyle.values[
  json['displayStyle'] as int? ?? 1
],  // ✓ 正确
```

### 错误 2: `config['pluginWidgetConfig']` 为 null

**原因**: 配置没有被保存或键名不匹配

**解决**:
1. 检查保存逻辑是否正确调用
2. 检查键名是否一致
3. 检查配置文件是否存在

### 错误 3: 配置保存成功但重启后丢失

**原因**: 可能是异步保存问题或文件系统权限问题

**解决**:
1. 确保 `saveLayout()` 等待完成
2. 检查应用是否有写入权限
3. 检查配置目录是否存在

## 下一步

1. 运行应用并查看调试日志
2. 将日志输出粘贴到问题报告中
3. 检查配置文件内容
4. 根据日志输出定位具体问题

## 联系方式

如果问题仍然存在，请提供：
- 完整的调试日志
- 配置文件内容（`settings.json`）
- 操作步骤
- Flutter 版本和平台信息
