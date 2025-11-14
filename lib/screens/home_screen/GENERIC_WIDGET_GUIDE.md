# 通用小组件系统 - 使用指南

## 概述

通用小组件系统提供了一个统一的方式来渲染插件的主页小组件（1x1、1x2、2x2）。用户可以通过长按小组件卡片来自定义：

- **显示风格**：一列文字或两列文字布局
- **显示项目**：选择要显示的统计项
- **背景图片**：设置卡片背景图片（支持裁剪）
- **图标颜色**：自定义图标颜色
- **背景颜色**：设置卡片背景颜色（无背景图片时生效）

## 核心组件

### 1. 数据模型

#### StatItemData - 统计项数据
```dart
class StatItemData {
  final String id;          // 唯一标识
  final String label;       // 显示标签
  final String value;       // 显示数值
  final bool highlight;     // 是否高亮显示
  final Color? color;       // 自定义颜色
}
```

#### PluginWidgetConfig - 小组件配置
```dart
class PluginWidgetConfig {
  PluginWidgetDisplayStyle displayStyle;  // 显示风格（一列/两列）
  List<String> selectedItemIds;           // 选中的统计项ID列表
  String? backgroundImagePath;            // 背景图片路径
  Color? iconColor;                       // 图标颜色
  Color? backgroundColor;                 // 背景颜色
}
```

### 2. 渲染组件

#### GenericPluginWidget
通用的小组件渲染组件，根据配置自动渲染不同风格的界面。

```dart
GenericPluginWidget(
  pluginName: '纪念日',
  pluginIcon: Icons.event_outlined,
  pluginDefaultColor: Colors.black87,
  availableItems: [...],  // 可用的统计项
  config: widgetConfig,   // 用户的自定义配置
)
```

### 3. 设置对话框

#### WidgetSettingsDialog
提供用户界面来配置小组件的各种选项。

```dart
showDialog<PluginWidgetConfig>(
  context: context,
  builder: (context) => WidgetSettingsDialog(
    initialConfig: currentConfig,
    availableItems: availableItems,
  ),
)
```

## 如何迁移现有插件

### 步骤 1: 添加导入

在 `home_widgets.dart` 文件顶部添加：

```dart
import '../../screens/home_screen/widgets/generic_plugin_widget.dart';
import '../../screens/home_screen/models/plugin_widget_config.dart';
```

### 步骤 2: 定义可用统计项

创建一个静态方法返回插件支持的所有统计项：

```dart
/// 获取可用的统计项
static List<StatItemData> _getAvailableStats() {
  try {
    final plugin = PluginManager.instance.getPlugin('your_plugin_id') as YourPlugin?;
    if (plugin == null) return [];

    return [
      StatItemData(
        id: 'total_count',
        label: '总数',
        value: '${plugin.getTotalCount()}',
        highlight: false,
      ),
      StatItemData(
        id: 'today_count',
        label: '今日',
        value: '${plugin.getTodayCount()}',
        highlight: true,
        color: Colors.blue,
      ),
      // 添加更多统计项...
    ];
  } catch (e) {
    return [];
  }
}
```

### 步骤 3: 更新小组件注册

在注册小组件时，添加 `availableStatsProvider` 参数，并确保 `builder` 接受 `config` 参数：

```dart
registry.register(HomeWidget(
  id: 'your_plugin_overview',
  pluginId: 'your_plugin_id',
  name: '插件概览',
  description: '显示统计信息',
  icon: Icons.your_icon,
  color: Colors.yourColor,
  defaultSize: HomeWidgetSize.large,
  supportedSizes: [HomeWidgetSize.large],
  category: '分类',
  builder: (context, config) => _buildOverviewWidget(context, config), // 添加 config 参数
  availableStatsProvider: _getAvailableStats, // 添加此字段
));
```

### 步骤 4: 重写构建器方法

使用 `GenericPluginWidget` 替代自定义实现：

```dart
/// 构建概览小组件
static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
  try {
    final l10n = YourPluginLocalizations.of(context);

    // 解析插件配置
    PluginWidgetConfig widgetConfig;
    try {
      if (config.containsKey('pluginWidgetConfig')) {
        widgetConfig = PluginWidgetConfig.fromJson(
          config['pluginWidgetConfig'] as Map<String, dynamic>,
        );
      } else {
        widgetConfig = PluginWidgetConfig();
      }
    } catch (e) {
      widgetConfig = PluginWidgetConfig();
    }

    // 获取可用的统计项数据
    final availableItems = _getAvailableStats();

    // 使用通用小组件
    return GenericPluginWidget(
      pluginName: l10n.name,
      pluginIcon: Icons.your_icon,
      pluginDefaultColor: Colors.yourColor,
      availableItems: availableItems,
      config: widgetConfig,
    );
  } catch (e) {
    return _buildErrorWidget(context, e.toString());
  }
}
```

### 步骤 5: 删除旧的自定义组件

如果之前有自定义的 `_StatItem` 或类似的组件，现在可以删除它们了。

## 完整示例

查看 `lib/plugins/day/home_widgets.dart` 获取完整的实现示例。

### 关键代码片段

```dart
class DayHomeWidgets {
  static void register() {
    final registry = HomeWidgetRegistry();

    registry.register(HomeWidget(
      id: 'day_overview',
      pluginId: 'day',
      name: '纪念日概览',
      description: '显示纪念日总数和即将到来的事件',
      icon: Icons.event,
      color: Colors.black87,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '记录',
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  static List<StatItemData> _getAvailableStats() {
    final plugin = PluginManager.instance.getPlugin('day') as DayPlugin?;
    if (plugin == null) return [];

    final totalCount = plugin.getMemorialDayCount();
    final upcomingDays = plugin.getUpcomingMemorialDays();

    return [
      StatItemData(
        id: 'total_count',
        label: '纪念日数',
        value: '$totalCount',
      ),
      StatItemData(
        id: 'upcoming',
        label: '即将到来',
        value: upcomingDays.isNotEmpty ? upcomingDays.join('、') : '暂无',
        highlight: upcomingDays.isNotEmpty,
        color: Colors.black87,
      ),
    ];
  }

  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
    final l10n = DayLocalizations.of(context);

    PluginWidgetConfig widgetConfig;
    try {
      if (config.containsKey('pluginWidgetConfig')) {
        widgetConfig = PluginWidgetConfig.fromJson(
          config['pluginWidgetConfig'] as Map<String, dynamic>,
        );
      } else {
        widgetConfig = PluginWidgetConfig();
      }
    } catch (e) {
      widgetConfig = PluginWidgetConfig();
    }

    return GenericPluginWidget(
      pluginName: l10n.name,
      pluginIcon: Icons.event_outlined,
      pluginDefaultColor: Colors.black87,
      availableItems: _getAvailableStats(),
      config: widgetConfig,
    );
  }
}
```

## 用户使用方式

### 1. 长按小组件卡片

在主屏幕上长按任何支持自定义的小组件卡片。

### 2. 选择"小组件设置"

从弹出的菜单中选择"小组件设置"选项。

### 3. 自定义选项

在设置对话框中，用户可以：

- **显示风格**：选择一列或两列布局
- **显示项目**：勾选要显示的统计项
- **背景图片**：点击设置背景图片（支持裁剪为16:9比例）
- **图标颜色**：从预定义颜色中选择图标颜色
- **背景颜色**：设置卡片背景颜色（无背景图片时生效）

### 4. 保存设置

点击"确认"按钮保存设置，小组件会立即更新显示。

## 设计原则

### 1. 统一性
所有插件使用相同的视觉风格和交互方式，提供一致的用户体验。

### 2. 灵活性
用户可以根据自己的喜好自定义小组件的外观和内容。

### 3. 可扩展性
插件只需提供统计项数据，通用组件负责渲染，降低了开发复杂度。

### 4. 向后兼容
不支持自定义的旧小组件仍然可以正常工作，只是长按时会提示"该小组件不支持自定义设置"。

## 注意事项

### 1. 动态数据
`_getAvailableStats()` 方法会在每次渲染时调用，确保统计项的值是最新的。

### 2. 错误处理
建议在 `_getAvailableStats()` 和 `_buildOverviewWidget()` 中添加 try-catch 块，避免插件未加载时崩溃。

### 3. 本地化
统计项的标签应该使用国际化字符串，支持多语言。

### 4. 性能
避免在 `_getAvailableStats()` 中执行耗时操作，建议缓存计算结果。

## 相关文件

- `lib/screens/home_screen/models/plugin_widget_config.dart` - 配置数据模型
- `lib/screens/home_screen/widgets/generic_plugin_widget.dart` - 通用渲染组件
- `lib/screens/home_screen/widgets/widget_settings_dialog.dart` - 设置对话框
- `lib/screens/home_screen/widgets/home_widget.dart` - 小组件定义（已更新）
- `lib/screens/home_screen/home_screen.dart` - 主屏幕（已添加设置菜单）
- `lib/plugins/day/home_widgets.dart` - 完整示例

## 后续改进

### 可能的增强功能

1. **更多布局选项**：支持三列、网格等更多布局方式
2. **自定义字体大小**：允许用户调整文字大小
3. **动画效果**：添加数值变化的动画效果
4. **主题预设**：提供多套预定义主题供快速选择
5. **导出/导入配置**：支持配置的备份和恢复

## 问题反馈

如果在使用过程中遇到问题，请通过以下方式反馈：

1. 检查控制台日志，查看是否有错误信息
2. 确认插件的 `_getAvailableStats()` 方法返回了正确的数据
3. 验证 `config` 参数是否正确传递给 `builder` 方法
4. 查看示例插件（day）的实现作为参考

---

**最后更新**: 2025-11-14
**维护者**: Memento Team
