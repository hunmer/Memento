---
name: add-list-widget-with-filters
description: 为插件主页添加带过滤器的列表小组件，使用 commonWidgetsProvider 支持多种公共组件样式，根据过滤条件选择使用多步骤 data selectors 或自定义表单
---

# Add List Widget with Filters for Plugin Home

为插件主页添加带过滤器的列表小组件，使用 `commonWidgetsProvider` 支持多种公共组件样式。

## Usage

```bash
# 为插件添加列表小组件（带过滤器）
/add-list-widget-with-filters <plugin_id>

# 示例
/add-list-widget-with-filters notes
/add-list-widget-with-filters todo
```

## Workflow

### 1. 创建 providers.dart

在 `lib/plugins/<plugin_id>/home_widgets/providers.dart` 中创建数据提供者：

```dart
/// 插件列表小组件数据提供者
Future<Map<String, Map<String, dynamic>>> provide{Plugin}ListWidgets(
  Map<String, dynamic> config,
) async {
  final plugin = PluginManager.instance.getPlugin('<plugin_id>') as {Plugin}?;
  if (plugin == null) return {};

  final controller = plugin.controller;

  // 解析过滤器参数
  final folderId = config['folderId'] as String?;
  final tags = config['tags'] as List<dynamic>?;
  final startDateStr = config['startDate'] as String?;
  final endDateStr = config['endDate'] as String?;

  // 解析日期
  DateTime? startDate;
  DateTime? endDate;
  if (startDateStr != null) startDate = DateTime.parse(startDateStr);
  if (endDateStr != null) endDate = DateTime.parse(endDateStr);

  // 获取过滤后的数据
  List<Item> filteredItems = controller.getItems(
    folderId: folderId,
    tags: tags?.cast<String>(),
    startDate: startDate,
    endDate: endDate,
  );

  final now = DateTime.now();
  final displayItems = filteredItems.take(5).toList();
  final moreCount = filteredItems.length > displayItems.length
      ? filteredItems.length - displayItems.length
      : 0;

  return {
    // TaskListCard
    'taskListCard': {
      'icon': Icons.list.codePoint.toString(),
      'iconBackgroundColor': pluginColor.value,
      'count': filteredItems.length,
      'countLabel': '{总}Items'.tr,
      'items': displayItems.map((e) => e.title).toList(),
      'moreCount': moreCount,
    },

    // ColorTagTaskCard
    'colorTagTaskCard': {
      'taskCount': filteredItems.length,
      'label': folderName ?? 'All',
      'tasks': displayItems.map((item) {
        final tag = item.tags.firstOrNull ?? '';
        return {
          'title': item.title,
          'color': _getColorFromTag(tag).value,
          'tag': tag.isEmpty ? 'Untagged'.tr : tag,
        };
      }).toList(),
      'moreCount': moreCount,
    },

    // InboxMessageCard
    'inboxMessageCard': {
      'messages': displayItems.map((item) {
        return {
          'name': item.title,
          'avatarUrl': '',
          'preview': _getPreviewText(item.content),
          'timeAgo': _formatTimeAgo(item.updatedAt, now),
          'iconCodePoint': Icons.item.icon.codePoint,
          'iconBackgroundColor': tagColor?.value ?? pluginColor.value,
        };
      }).toList(),
      'totalCount': filteredItems.length,
      'remainingCount': moreCount,
      'title': folderName ?? 'All',
      'primaryColor': pluginColor.value,
    },

    // NewsUpdateCard
    'newsUpdateCard': displayItems.isNotEmpty
        ? {
            'icon': 'bolt',
            'title': displayItems.first.title,
            'timestamp': _formatTimeAgo(displayItems.first.updatedAt, now),
            'currentIndex': 0,
            'totalItems': displayItems.length.clamp(1, 4),
          }
        : {
            'icon': 'bolt',
            'title': 'No Items'.tr,
            'timestamp': DateFormat('yyyy-MM-dd').format(now),
            'currentIndex': 0,
            'totalItems': 1,
          },
  };
}

// 辅助函数
Color _getColorFromTag(String tag) {
  final hashCode = tag.hashCode;
  final hue = (hashCode % 360).abs();
  return HSVColor.fromAHSV(1.0, hue.toDouble(), 0.7, 0.9).toColor();
}

String _getPreviewText(String content) {
  // 移除 Markdown 符号，截取前 50 个字符
  String cleanText = content
      .replaceAll(RegExp(r'^#+\s+', multiLine: true), '')
      .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'\1')
      .trim();

  if (cleanText.length > 50) {
    cleanText = cleanText.substring(0, 50);
    final lastSpace = cleanText.lastIndexOf(' ');
    if (lastSpace > 30) cleanText = cleanText.substring(0, lastSpace);
    cleanText += '...';
  }
  return cleanText.isEmpty ? 'Empty'.tr : cleanText;
}

String _formatTimeAgo(DateTime dateTime, DateTime now) {
  final difference = now.difference(dateTime);
  if (difference.inSeconds < 60) return 'JustNow'.tr;
  if (difference.inMinutes < 60) return 'minutesAgo'.trParams({'count': '${difference.inMinutes}'});
  if (difference.inHours < 24) return 'hoursAgo'.trParams({'count': '${difference.inHours}'});
  if (difference.inDays < 7) return 'daysAgo'.trParams({'count': '${difference.inDays}'});
  return DateFormat('yyyy-MM-dd').format(dateTime);
}
```

### 2. 创建 register_<widget>.dart

在 `lib/plugins/<plugin_id>/home_widgets/register_<widget>.dart` 中注册小组件：

```dart
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'utils.dart' show pluginColor;
import 'providers.dart';

/// 注册笔记列表小组件
void register{Plugin}ListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: '{plugin}_list_widget',
      pluginId: '{plugin}',
      name: '{plugin}_listWidgetName'.tr,
      description: '{plugin}_listWidgetDescription'.tr,
      icon: Icons.view_list,
      color: pluginColor,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
      category: 'home_categoryRecord'.tr,

      selectorId: '{plugin}.list.config',
      commonWidgetsProvider: provide{Plugin}ListWidgets,

      builder: (context, config) {
        return StatefulBuilder(
          builder: (context, setState) {
            return EventListenerContainer(
              events: const [
                'item_added',
                'item_updated',
                'item_deleted',
              ],
              onEvent: () => setState(() {}),
              child: GenericSelectorWidget(
                widgetDefinition: registry.getWidget('{plugin}_list_widget')!,
                config: config,
              ),
            );
          },
        );
      },
    ),
  );
}
```

### 3. 更新 home_widgets.dart

添加注册调用：

```dart
import 'register_{widget}.dart' show register{Plugin}ListWidget;

void register() {
  // ... 现有注册
  register{Plugin}ListWidget(registry);
}
```

### 4. 选择选择器方案

根据过滤条件选择合适的数据选择器实现方案：

#### 方案 A: 多步骤选择器（适用于简单单选条件）

**适用场景**：
- 每个步骤都是单选
- 不需要可选步骤
- 步骤之间有依赖关系

**实现方式**：使用多个 `SelectorStep`，`viewType: SelectorViewType.list`

```dart
pluginDataSelectorService.registerSelector(SelectorDefinition(
  id: '{plugin}.list.config',
  pluginId: {Plugin}Plugin.instance.id,
  name: '配置选择器名称'.tr,
  icon: Icons.tune,
  color: {Plugin}Plugin.instance.color,
  searchable: false,
  selectionMode: SelectionMode.single,
  steps: [
    // 步骤1：选择文件夹
    SelectorStep(
      id: 'folder',
      title: '选择文件夹',
      viewType: SelectorViewType.list,
      dataLoader: (_) async {
        // 返回文件夹列表
        return [
          SelectableItem(id: 'all', title: '全部', rawData: {'folderId': null}),
          // ... 文件夹选项
        ];
      },
      isFinalStep: false, // 不是最后一步
    ),

    // 步骤2：选择样式
    SelectorStep(
      id: 'style',
      title: '选择样式',
      viewType: SelectorViewType.list,
      dataLoader: (previousSelections) async {
        // previousSelections['folder'] 包含的是 rawData (Map)，不是 SelectableItem
        final folderData = previousSelections['folder'] as Map<String, dynamic>?;
        final folderId = folderData?['folderId'] as String?;

        return [
          // 返回样式选项
        ];
      },
      isFinalStep: true,
    ),
  ],
));
```

**注意**：
- `previousSelections` 中存储的是 `rawData` (Map<String, dynamic>)，不是 `SelectableItem`
- 如果 `SelectorStep` 的 `isFinalStep` 为 `false`，则必须有下一步

#### 方案 B: 自定义表单选择器（适用于复杂过滤条件）

**适用场景**：
- 需要多选（如标签）
- 需要可选步骤
- 需要自定义交互（如日期选择器）
- 需要在一个界面完成所有配置

**实现方式**：使用 `SelectorViewType.customForm` + `customFormBuilder`

```dart
pluginDataSelectorService.registerSelector(SelectorDefinition(
  id: '{plugin}.list.config',
  pluginId: {Plugin}Plugin.instance.id,
  name: '配置选择器名称'.tr,
  icon: Icons.tune,
  color: {Plugin}Plugin.instance.color,
  searchable: false,
  selectionMode: SelectionMode.single,
  steps: [
    SelectorStep(
      id: 'config',
      title: '配置选择器名称'.tr,
      viewType: SelectorViewType.customForm,
      dataLoader: (_) async => [], // customForm 不需要加载数据
      isFinalStep: true,
      customFormBuilder: (context, previousSelections, onComplete) {
        return _{Plugin}ListConfigForm(
          onComplete: (config) {
            onComplete(config);
          },
        );
      },
    ),
  ],
));
```

**自定义表单组件**：

```dart
class _{Plugin}ListConfigForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const _{Plugin}ListConfigForm({required this.onComplete});

  @override
  State<_{Plugin}ListConfigForm> createState() => _{Plugin}ListConfigFormState();
}

class _{Plugin}ListConfigFormState extends State<_{Plugin}ListConfigForm> {
  String? _selectedFolderId;
  final Set<String> _selectedTags = {};
  DateTime? _startDate;
  DateTime? _endDate;

  List<Folder> _folders = [];
  List<String> _allTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final controller = {Plugin}Plugin.instance.controller;

    setState(() {
      _folders = controller.getAllFolders().where((f) => f.id != 'root').toList();

      final allItems = controller.getAllItems();
      final tagsSet = <String>{};
      for (final item in allItems) {
        tagsSet.addAll(item.tags);
      }
      _allTags = tagsSet.toList()..sort();

      _isLoading = false;
    });
  }

  void _confirm() {
    widget.onComplete({
      'folderId': _selectedFolderId,
      'tags': _selectedTags.toList(),
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.tune, color: {Plugin}Plugin.instance.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '配置选择器名称'.tr,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 配置选项
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFolderSelector(),
                  const SizedBox(height: 16),
                  _buildTagSelector(),
                  const SizedBox(height: 16),
                  _buildDateRangeSelector(),
                ],
              ),
            ),
            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('取消'.tr),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirm,
                      child: Text('确认'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择文件夹'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedFolderId ?? 'all',
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
          ),
          items: [
            DropdownMenuItem(value: 'all', child: Text('全部'.tr)),
            ..._folders.map((folder) {
              final itemCount = controller.getFolderItems(folder.id).length;
              return DropdownMenuItem(
                value: folder.id,
                child: Text('${folder.name} • $itemCount'),
              );
            }),
          ],
          onChanged: (value) {
            setState(() => _selectedFolderId = value == 'all' ? null : value);
          },
        ),
      ],
    );
  }

  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择标签 (可选)'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_allTags.isEmpty)
          Text('暂无标签'.tr, style: TextStyle(color: Theme.of(context).colorScheme.outline))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) _selectedTags.add(tag);
                    else _selectedTags.remove(tag);
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('日期范围 (可选)'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _startDate = date);
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(_startDate == null ? '开始日期'.tr : DateFormat('yyyy-MM-dd').format(_startDate!)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _endDate = date);
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(_endDate == null ? '结束日期'.tr : DateFormat('yyyy-MM-dd').format(_endDate!)),
              ),
            ),
          ],
        ),
        if (_startDate != null || _endDate != null)
          TextButton.icon(
            onPressed: () => setState(() => _startDate = null; _endDate = null;),
            icon: const Icon(Icons.clear, size: 16),
            label: Text('清除'.tr),
          ),
      ],
    );
  }
}
```

**关键点**：
- 自定义表单类名以下划线开头（私有类）
- `customFormBuilder` 中返回的表单组件需要自己处理导航和确认
- 使用 `Navigator.pop(context)` 取消，`onComplete(config)` 确认

### 5. 更新数据选择器文件

在 `lib/plugins/<plugin_id>/<plugin>_data_selectors.dart` 或 `notes_data_selectors.dart` 中添加选择器注册。

**重要**：
- 如果是 `part of` 文件，不能有 import 语句
- 需要在主插件文件中添加必要的 import（如 `intl`, `models` 等）
- `previousSelections` 存储的是 `rawData`，不是 `SelectableItem`

### 6. 添加国际化字符串

在 `l10n/<plugin>_translations_zh.dart` 和 `<plugin>_translations_en.dart` 中添加：

```dart
// 中文
'{plugin}_listWidgetName': '列表小组件',
'{plugin}_listWidgetDescription': '显示列表，支持过滤',
'{plugin}_listConfigSelectorName': '列表配置',
'{plugin}_listConfigSelectorDesc': '选择过滤条件和显示样式',
'{plugin}_allItems': '全部项目',
'{plugin}_selectTagsTitle': '选择标签',
'{plugin}_selectDateRangeTitle': '日期范围',
'{plugin}_optional': '可选',
'{plugin}_noTags': '暂无标签',
'{plugin}_cancel': '取消',
'{plugin}_confirm': '确认',
```

## Decision Matrix: 选择器方案选择

根据过滤条件选择合适的实现方案：

| 条件类型 | 推荐方案 | 理由 |
|---------|----------|------|
| 单个单选条件（如只选文件夹） | 方案 A：多步骤选择器 | 简单直接 |
| 多个单选条件（如文件夹→样式） | 方案 A：多步骤选择器 | 步骤清晰 |
| 包含多选条件（如标签） | 方案 B：自定义表单 | 框架不支持多选 |
| 包含可选条件 | 方案 B：自定义表单 | 框架不支持可选步骤 |
| 需要复杂交互（如日期选择器） | 方案 B：自定义表单 | 灵活性高 |
| 条件之间有复杂依赖 | 方案 B：自定义表单 | 更容易处理逻辑 |
| 过滤条件很多（4+ 个） | 方案 B：自定义表单 | 用户体验更好 |

## 文件结构

```
lib/plugins/<plugin_id>/
├── home_widgets/
│   ├── home_widgets.dart          # 注册入口
│   ├── providers.dart              # 数据提供者
│   ├── register_<widget>.dart      # 小组件注册
│   └── utils.dart                  # 工具函数（如颜色）
├── <plugin>_data_selectors.dart    # 数据选择器（或 part 文件）
├── l10n/
│   ├── <plugin>_translations.dart   # 国际化接口
│   ├── <plugin>_translations_zh.dart # 中文
│   └── <plugin>_translations_en.dart # 英文
└── <plugin>_plugin.dart              # 主插件文件
```

## Common Pitfalls

### 1. previousSelections 类型错误

```dart
// ❌ 错误
final folderSelection = previousSelections['folder'] as SelectableItem?;

// ✅ 正确
final folderData = previousSelections['folder'] as Map<String, dynamic>?;
final folderId = folderData?['folderId'] as String?;
```

### 2. part 文件中的 import

```dart
// ❌ 错误 - part 文件不能有 import
part of 'my_plugin.dart';

import 'package:intl/intl.dart';

// ✅ 正确 - 在主插件文件中添加 import
// my_plugin.dart
import 'package:intl/intl.dart';

part 'my_data_selectors.dart';
```

### 3. 数据选择器需要 dataLoader

```dart
// ❌ 错误 - customForm 也需要 dataLoader
SelectorStep(
  viewType: SelectorViewType.customForm,
  isFinalStep: true,
  customFormBuilder: (context, previousSelections, onComplete) {...},
)

// ✅ 正确
SelectorStep(
  viewType: SelectorViewType.customForm,
  dataLoader: (_) async => [], // 必须提供，即使是空数组
  isFinalStep: true,
  customFormBuilder: (context, previousSelections, onComplete) {...},
)
```

### 4. 国际化字符串格式

```dart
// ❌ 错误
Text('选择标签' + ' (可选)')

// ✅ 正确 - 使用字符串插值
Text('notes_selectTagsTitle'.tr + ' (${'notes_optional'.tr})')
```

## Checklist

完成以下检查确保小组件正确集成：

- [ ] `providers.dart` 创建并正确处理过滤参数
- [ ] `register_<widget>.dart` 注册小组件
- [ ] `home_widgets.dart` 添加注册调用
- [ ] 数据选择器正确注册（多步骤或自定义表单）
- [ ] 国际化字符串已添加
- [ ] 主插件文件中添加必要的 import（如 `intl`, `models`）
- [ ] `part` 文件中没有 import 语句
- [ ] 运行 `flutter analyze` 无错误
- [ ] 测试过滤条件是否正确工作

## Example: Notes List Widget

完整的笔记列表小组件实现参考本次会话：

**创建的文件**：
- `lib/plugins/notes/home_widgets/providers.dart`
- `lib/plugins/notes/home_widgets/register_notes_list_widget.dart`

**修改的文件**：
- `lib/plugins/notes/home_widgets/home_widgets.dart`
- `lib/plugins/notes/notes_data_selectors.dart`
- `lib/plugins/notes/l10n/notes_translations_zh.dart`
- `lib/plugins/notes/l10n/notes_translations_en.dart`

**支持的过滤条件**：
- 文件夹（下拉选择）
- 标签（FilterChip 多选）
- 日期范围（日期选择器）

**支持的公共组件**：
- TaskListCard
- ColorTagTaskCard
- InboxMessageCard
- NewsUpdateCard
