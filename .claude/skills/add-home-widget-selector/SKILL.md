---
name: add-home-widget-selector
description: 为Flutter插件添加可配置的选择器小组件（HomeWidget），支持用户点击配置、数据选择和动态数据渲染。核心特性：(1) 配置dataSelector保存必要数据，(2) 通过controller传递id获取最新数据，(3) 支持导航到详情页
---

# Add HomeWidget Selector

为 Flutter 插件添加可配置的选择器类型 HomeWidget，让用户可以在首页添加小组件并自定义选择要显示的数据。

## Usage

```bash
# 基础用法 - 为插件添加选择器小组件
/add-home-widget-selector <plugin-path> --widget-id <widget-id> --selector-id <selector-id>

# 完整参数
/add-home-widget-selector lib/plugins/todo \
  --widget-id todo_quick_access \
  --selector-id todo.task \
  --name "todo_quickAccessWidget".tr \
  --icon Icons.check_circle \
  --category "home_categoryTask".tr
```

**Examples:**

```bash
# 为待办插件添加任务快捷访问小组件
/add-home-widget-selector lib/plugins/todo \
  --widget-id todo_quick_access \
  --selector-id todo.task \
  --name "todo_quickAccessWidget".tr \
  --icon Icons.task_alt \
  --category "home_categoryTask".tr

# 为日记插件添加日记入口小组件
/add-home-widget-selector lib/plugins/diary \
  --widget-id diary_entry_selector \
  --selector-id diary.entry \
  --name "diary_quickAccessWidget".tr \
  --icon Icons.auto_stories \
  --category "home_categoryContent".tr

# 为聊天插件添加会话快捷小组件
/add-home-widget-selector lib/plugins/agent_chat \
  --widget-id chat_conversation_selector \
  --selector-id chat.conversation \
  --name "chat_quickAccessWidget".tr \
  --icon Icons.chat_bubble \
  --category "home_categoryChat".tr
```

## Arguments

- `<plugin-path>`: 插件根目录路径（包含 `home_widgets.dart` 或需要创建的文件）
- `--widget-id <id>`: 小组件唯一 ID（格式：`plugin_id_widget_name`）
- `--selector-id <id>`: 数据选择器 ID（格式：`plugin_id.selector_name`，需先注册）
- `--name <name>`: 小组件显示名称（国际化键值，如 `"todo_quickAccessWidget".tr`）
- `--icon <icon>`: 小组件图标（格式：`Icons.icon_name`）
- `--category <category>`: 小组件分类（国际化键值）

### 可选参数

- `--size <sizes>`: 支持的尺寸（逗号分隔，默认：`medium,large`）
- `--default-size <size>`: 默认尺寸（默认：`large`）
- `--data-extractor <method>`: 自定义数据提取方法名（默认：`_extractWidgetData`）
- `--data-renderer <method>`: 自定义渲染方法名（默认：`_renderWidgetData`）
- `--navigation <method>`: 自定义导航方法名（默认：`_navigateToDetail`）

## Workflow

### 1. Analyze Plugin Structure

读取插件目录并识别：

- 插件主文件（`[plugin_name]_plugin.dart`）
- 是否已存在 `home_widgets.dart`
- 插件的 controller 类和方法
- 国际化文件位置
- 路由配置文件

### 2. Register Data Selector (如果尚未注册)

在插件主文件中注册数据选择器：

```dart
// 在 [plugin_name]_plugin.dart 中
void _registerDataSelectors() {
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: '[plugin_id].[selector_name]',  // 例如: 'todo.task', 'diary.entry'
      pluginId: '[plugin_id]',
      name: '[翻译键]'.tr,
      selectionMode: SelectionMode.single,  // 或 SelectionMode.multiple
      steps: [
        SelectorStep(
          id: 'select_[item]',
          title: '[选择步骤标题]'.tr,
          viewType: SelectorViewType.list,  // 或 .grid, .tree
          dataLoader: (previousSelections) async {
            // 加载可选数据
            final items = await _loadSelectableItems();
            return items.map((item) => SelectableItem(
              id: item.id,
              title: item.title,
              subtitle: item.subtitle,
              icon: Icons.[icon_name],
              rawData: item.toJson(),  // 重要：保存完整数据供后续使用
            )).toList();
          },
          isFinalStep: true,
        ),
      ],
    ),
  );
}
```

### 3. Create/Update home_widgets.dart

在 `home_widgets.dart` 中注册选择器小组件：

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';

/// [PluginName] 插件的主页小组件注册
class [PluginName]HomeWidgets {
  /// 注册所有小组件
  static void register(HomeWidgetRegistry registry) {
    // 注册选择器小组件
    registry.register(
      HomeWidget(
        id: '[widget_id]',  // 例如: 'todo_quick_access'
        pluginId: '[plugin_id]',
        name: '[小组件名称]'.tr,
        description: '[小组件描述]'.tr,
        icon: Icons.[icon_name],
        color: Colors.[primary_color],
        defaultSize: HomeWidgetSize.[default_size],
        supportedSizes: [
          HomeWidgetSize.[size1],
          HomeWidgetSize.[size2],
        ],
        category: '[分类]'.tr,

        // === 选择器特定字段 ===
        selectorId: '[plugin_id].[selector_name]',  // 与选择器注册时的 id 一致
        dataRenderer: _[render_method],             // 自定义渲染函数
        navigationHandler: _[navigate_method],      // 导航处理函数

        builder: (context, config) {
          return GenericSelectorWidget(
            widgetDefinition: registry.getWidget('[widget_id]')!,
            config: config,
          );
        },
      ),
    );
  }

  /// 从选择器数据中提取小组件需要的数据（保存到本地存储）
  static Map<String, dynamic> _[extract_method](List<dynamic> dataArray) {
    final itemData = dataArray[0] as Map<String, dynamic>;

    return {
      'id': itemData['id'] as String,
      'title': itemData['title'] as String?,
      'subtitle': itemData['subtitle'] as String?,
      // 只保存必要的数据，避免存储冗余信息
    };
  }

  /// 渲染小组件数据（从 controller 获取最新数据）
  static Widget _[render_method](
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    // 从 result.data 获取已保存的数据（包含 id）
    final savedData = result.data is Map<String, dynamic>
        ? result.data as Map<String, dynamic>
        : {};

    final itemId = savedData['id'] as String? ?? '';

    return FutureBuilder<dynamic>(
      // ✅ 关键：通过 controller 传递 id 获取最新数据
      future: _loadLatestData(itemId),
      builder: (context, snapshot) {
        final latestData = snapshot.data ?? savedData;
        final title = latestData['title'] ?? savedData['title'] ?? 'Unknown';
        final subtitle = latestData['subtitle'] ?? savedData['subtitle'] ?? '';

        return _buildWidgetUI(context, title, subtitle, latestData);
      },
    );
  }

  /// 从 controller 加载最新数据
  static Future<dynamic> _loadLatestData(String itemId) async {
    try {
      final plugin = PluginManager.instance.getPlugin('[plugin_id]') as [PluginClass]?;
      if (plugin == null) return null;

      // ✅ 关键：通过 controller 传递 id 获取最新数据
      return await plugin.controller.getItemById(itemId);
    } catch (e) {
      debugPrint('加载最新数据失败: $e');
      return null;
    }
  }

  /// 构建小组件 UI
  static Widget _buildWidgetUI(
    BuildContext context,
    String title,
    String subtitle,
    dynamic data,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.[icon_name], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'home_clickToView'.tr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 导航到详情页
  static void _[navigate_method](
    BuildContext context,
    SelectorResult result,
  ) {
    final data = result.data is Map<String, dynamic>
        ? result.data as Map<String, dynamic>
        : {};

    final itemId = data['id'] as String?;

    // 使用 navigatorKey.currentContext 确保导航正常工作
    final navContext = NavigationHelper.getCurrentContext() ?? context;

    NavigationHelper.pushNamed(
      navContext,
      '/[plugin_id]/[detail_screen]',
      arguments: {
        'id': itemId,
        // 可以传递其他必要参数
      },
    );
  }
}
```

### 4. Update Plugin Registration

在插件主文件的 `initialize()` 方法中调用小组件注册：

```dart
// 在 [plugin_name]_plugin.dart
@override
Future<void> initialize() async {
  // ... 其他初始化代码 ...

  // 注册选择器（如果还没有）
  _registerDataSelectors();
}

@override
Future<void> registerToApp(
  PluginManager pluginManager,
  ConfigManager configManager,
) async {
  // 在应用级别注册小组件
  final homeWidgetRegistry = pluginManager.getService<HomeWidgetRegistry>();
  if (homeWidgetRegistry != null) {
    [PluginName]HomeWidgets.register(homeWidgetRegistry);
  }
}
```

### 5. Update Route Configuration

在 `lib/screens/route.dart` 中添加详情页路由：

```dart
// 在 generateRoute 方法中添加
case '/[plugin_id]/[detail_screen]':
case '[plugin_id]/[detail_screen]':
  String? id;

  if (settings.arguments is Map<String, dynamic>) {
    final args = settings.arguments as Map<String, dynamic>;
    id = args['id'] as String?;
  }

  debugPrint('打开详情页: id=$id');

  return _createRoute(
    [DetailScreen](id: id),
  );
```

### 6. Add Internationalization Strings

在插件的国际化文件中添加字符串：

**中文 (zh):**

```dart
'[plugin_id]_quickAccessWidget': '快捷访问',
'[plugin_id]_widgetDescription': '点击选择要显示的项目',
'[plugin_id]_selectTitle': '选择项目',
'[plugin_id]_clickToConfigure': '点击配置',
'[plugin_id]_clickToView': '点击查看详情',
```

**英文 (en):**

```dart
'[plugin_id]_quickAccessWidget': 'Quick Access',
'[plugin_id]_widgetDescription': 'Tap to select an item to display',
'[plugin_id]_selectTitle': 'Select Item',
'[plugin_id]_clickToConfigure': 'Tap to configure',
'[plugin_id]_clickToView': 'Tap to view details',
```

## Key Concepts

### 1. dataSelector - 数据提取函数

`dataSelector` 函数负责从选择器返回的完整数据中提取**必要字段**并保存到本地存储：

```dart
// ✅ 推荐：只保存必要数据
static Map<String, dynamic> _extractWidgetData(List<dynamic> dataArray) {
  final itemData = dataArray[0] as Map<String, dynamic>;
  return {
    'id': itemData['id'] as String,        // 必需：用于后续获取最新数据
    'title': itemData['title'] as String?,
    // 不要保存大型数据（如 content、description 等）
  };
}

// ❌ 避免：保存过多数据
static Map<String, dynamic> _extractWidgetData(List<dynamic> dataArray) {
  return dataArray[0] as Map<String, dynamic>;  // 保存完整数据
}
```

**为什么只保存必要数据？**
- 减少存储空间
- 数据变化时不需要更新小组件配置
- 通过 id 可以随时获取最新数据

### 2. dataRenderer - 动态数据获取

`dataRenderer` 函数必须通过插件的 controller 传递保存的 id 来获取**最新数据**：

```dart
static Widget _renderWidgetData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  final savedData = result.data as Map<String, dynamic>;
  final itemId = savedData['id'] as String? ?? '';

  return FutureBuilder<dynamic>(
    // ✅ 关键：传递 id 获取最新数据
    future: _loadLatestData(itemId),
    builder: (context, snapshot) {
      final data = snapshot.data ?? savedData;
      return _buildWidgetUI(context, data);
    },
  );
}

static Future<dynamic> _loadLatestData(String itemId) async {
  final plugin = PluginManager.instance.getPlugin('[plugin_id]') as PluginClass?;
  // ✅ 关键：通过 controller 获取最新数据
  return await plugin.controller.getItemById(itemId);
}
```

**为什么必须通过 controller 获取最新数据？**
- 保持小组件显示的信息与实际数据一致
- 用户的操作（如修改标题）能即时反映在小组件上
- 遵循单一数据源原则

### 3. navigationHandler - 导航处理

导航函数负责跳转到详情页：

```dart
static void _navigateToDetail(BuildContext context, SelectorResult result) {
  final data = result.data as Map<String, dynamic>;
  final itemId = data['id'] as String?;

  NavigationHelper.pushNamed(
    context,
    '/[plugin_id]/detail',
    arguments: {'id': itemId},
  );
}
```

## Complete Example: Todo Plugin

### 1. 注册选择器 (`todo_plugin.dart`)

```dart
void _registerDataSelectors() {
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'todo.task',
      pluginId: 'todo',
      name: 'todo_selectTask'.tr,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'select_task',
          title: 'todo_selectTask'.tr,
          viewType: SelectorViewType.list,
          dataLoader: (previousSelections) async {
            final tasks = await taskController.getAllTasks();
            return tasks.map((task) => SelectableItem(
              id: task.id,
              title: task.title,
              subtitle: task.description,
              icon: task.completed ? Icons.check_circle : Icons.radio_button_unchecked,
              rawData: {
                'id': task.id,
                'title': task.title,
                'description': task.description,
                'completed': task.completed,
                'priority': task.priority.index,
              },
            )).toList();
          },
          isFinalStep: true,
        ),
      ],
    ),
  );
}
```

### 2. 小组件注册 (`home_widgets.dart`)

```dart
class TodoHomeWidgets {
  static void register(HomeWidgetRegistry registry) {
    registry.register(
      HomeWidget(
        id: 'todo_quick_access',
        pluginId: 'todo',
        name: 'todo_quickAccessWidget'.tr,
        description: 'todo_quickAccessDescription'.tr,
        icon: Icons.check_circle,
        color: Colors.blue,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
        category: 'home_categoryTask'.tr,

        selectorId: 'todo.task',
        dataRenderer: _renderTaskData,
        navigationHandler: _navigateToTask,

        builder: (context, config) {
          return GenericSelectorWidget(
            widgetDefinition: registry.getWidget('todo_quick_access')!,
            config: config,
          );
        },
      ),
    );
  }

  static Map<String, dynamic> _extractTaskData(List<dynamic> dataArray) {
    final taskData = dataArray[0] as Map<String, dynamic>;
    return {
      'id': taskData['id'] as String,
      'title': taskData['title'] as String?,
    };
  }

  static Widget _renderTaskData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final savedData = result.data is Map<String, dynamic>
        ? result.data as Map<String, dynamic>
        : {};
    final taskId = savedData['id'] as String? ?? '';

    return FutureBuilder<Task?>(
      future: _loadLatestTask(taskId),
      builder: (context, snapshot) {
        final task = snapshot.data;
        final title = task?.title ?? savedData['title'] ?? 'Unknown';
        final description = task?.description ?? '';
        final completed = task?.completed ?? false;

        return _buildTaskWidget(context, title, description, completed);
      },
    );
  }

  static Future<Task?> _loadLatestTask(String taskId) async {
    try {
      final plugin = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
      return await plugin?.taskController.getTaskById(taskId);
    } catch (e) {
      debugPrint('加载任务失败: $e');
      return null;
    }
  }

  static Widget _buildTaskWidget(
    BuildContext context,
    String title,
    String description,
    bool completed,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: completed
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    completed ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: completed ? Colors.green : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: completed ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void _navigateToTask(BuildContext context, SelectorResult result) {
    final data = result.data is Map<String, dynamic>
        ? result.data as Map<String, dynamic>
        : {};
    final taskId = data['id'] as String?;

    NavigationHelper.pushNamed(
      context,
      '/todo/task',
      arguments: {'taskId': taskId},
    );
  }
}
```

### 3. 路由注册 (`route.dart`)

```dart
case '/todo/task':
case 'todo/task':
  String? taskId;

  if (settings.arguments is Map<String, dynamic>) {
    final args = settings.arguments as Map<String, dynamic>;
    taskId = args['taskId'] as String?;
  }

  return _createRoute(
    TodoTaskDetailScreen(taskId: taskId),
  );
```

## Best Practices

### 1. 数据提取

```dart
// ✅ 推荐：只提取必要字段
static Map<String, dynamic> _extractData(List<dynamic> dataArray) {
  final item = dataArray[0] as Map<String, dynamic>;
  return {
    'id': item['id'] as String,  // 必须保存 id
    'title': item['title'] as String?,
  };
}

// ❌ 避免：保存完整数据
static Map<String, dynamic> _extractData(List<dynamic> dataArray) {
  return dataArray[0] as Map<String, dynamic>;
}
```

### 2. 动态数据加载

```dart
// ✅ 推荐：使用 FutureBuilder 获取最新数据
static Widget _renderData(BuildContext context, SelectorResult result, ...) {
  final savedData = result.data as Map<String, dynamic>;
  final id = savedData['id'] as String?;

  return FutureBuilder<Item?>(
    future: _loadLatestData(id),
    builder: (context, snapshot) {
      final data = snapshot.data ?? savedData;
      return _buildWidgetUI(context, data);
    },
  );
}

// ❌ 避免：只使用保存的数据，不获取最新
static Widget _renderData(BuildContext context, SelectorResult result, ...) {
  final data = result.data as Map<String, dynamic>;
  return _buildWidgetUI(context, data);  // 不获取最新数据
}
```

### 3. 空值处理

```dart
// ✅ 推荐：安全的空值处理
final title = itemData['title'] as String? ?? 'Unknown';
final id = itemData['id'] as String? ?? '';

// ❌ 避免：直接访问可能为 null 的值
final title = itemData['title'] as String;  // 可能抛出异常
```

### 4. 错误处理

```dart
static Future<Item?> _loadLatestData(String id) async {
  try {
    final plugin = PluginManager.instance.getPlugin('[plugin_id]') as PluginClass?;
    if (plugin == null || id.isEmpty) return null;
    return await plugin.controller.getItemById(id);
  } catch (e) {
    debugPrint('加载数据失败: $e');
    return null;
  }
}
```

## Testing Checklist

完成后验证：

- [ ] `flutter analyze` 无错误
- [ ] 选择器能正常显示可选数据列表
- [ ] 选择后小组件正确显示配置状态
- [ ] 小组件点击后能正常导航到详情页
- [ ] 小组件显示的数据是最新的（通过 controller 获取）
- [ ] 重新选择后小组件正确更新
- [ ] 国际化字符串完整
- [ ] 删除/修改原始数据后小组件正确显示最新状态

## Troubleshooting

### 问题 1: 点击小组件没有反应

**检查清单**:
- [ ] `selectorId` 是否与 `SelectorDefinition.id` 完全一致？
- [ ] `dataRenderer` 和 `navigationHandler` 是否都已实现？
- [ ] `GenericSelectorWidget` 的 `widgetDefinition` 是否正确获取？

### 问题 2: 小组件显示的数据不是最新的

**原因**: `dataRenderer` 没有通过 controller 获取最新数据

**解决**:
```dart
// ✅ 确保这样写
return FutureBuilder<Item?>(
  future: plugin.controller.getItemById(itemId),  // 通过 controller 获取
  builder: (context, snapshot) {
    // ...
  },
);
```

### 问题 3: 选择后数据丢失

**原因**: `dataSelector` 函数返回空或格式错误

**解决**:
- 确保 `dataSelector` 返回 `Map<String, dynamic>`
- 确保返回的数据包含 `id` 字段

### 问题 4: 导航到详情页失败

**检查**:

1. **路由配置检查** - 最常见问题！

   `route.dart` 中有两套路由机制：
   - `routes` Map（静态路由定义）
   - `onGenerateRoute`（动态路由处理）

   如果 `routes` 中定义了路由，`onGenerateRoute` 不会被调用！

   ```dart
   // ❌ 错误：routes 中定义了 /tracker，导致 onGenerateRoute 不会执行
   static Map<String, WidgetBuilder> get routes => {
     // ...
     tracker: (context) => const TrackerMainView(),  // 移除这行！
   };

   // ✅ 正确：让 onGenerateRoute 处理（可接收参数）
   case '/tracker':
   case 'tracker':
     String? goalId;
     if (settings.arguments is Map<String, dynamic>) {
       goalId = (settings.arguments as Map<String, dynamic>)['goalId'] as String?;
     }
     if (goalId != null) {
       return _createRoute(GoalDetailScreen(goalId: goalId));
     }
     return _createRoute(const TrackerMainView());
   ```

2. **导航上下文检查**

   小组件回调中的 context 可能不在导航树中，使用 `navigatorKey.currentContext`：

   ```dart
   // ✅ 推荐：使用 navigatorKey
   final navContext = navigatorKey.currentContext ?? context;
   NavigationHelper.pushNamed(navContext, '/route', arguments: {...});
   ```

3. **参数类型检查**

   id 可能是 `int` 或 `String`：

   ```dart
   final id = data['id']?.toString();  // 安全处理
   ```

4. **详情页 Provider 依赖检查**

   如果详情页使用 `Consumer<Controller>` 或 `context.read<Controller>()`：
   - 需要在路由中用 `ChangeNotifierProvider.value` 包裹
   - 或让详情页直接使用 `Plugin.instance.controller` 单例

## Route Configuration Checklist

为新小组件添加路由时检查：

- [ ] 从 `routes` Map 中移除该路由（如果有）
- [ ] 在 `onGenerateRoute` 的 switch case 中添加路由处理
- [ ] 正确解析 `settings.arguments` 中的参数
- [ ] 使用 `navigatorKey.currentContext` 进行导航
- [ ] 详情页能正确获取 controller（使用单例或 Provider）

## Notes

- 使用中文注释与现有代码库保持一致
- 优先使用 `GenericSelectorWidget` 作为小组件构建器
- 通过 controller 获取最新数据而不是使用保存的静态数据
- 使用 `flutter analyze` 验证代码
- 参考 `lib/plugins/bill/home_widgets.dart` 获取完整实现示例
- 参考 `docs/SELECTOR_WIDGET_GUIDE.md` 获取详细指南
