# lib/screens - 应用屏幕层

[根目录](../../CLAUDE.md) > [lib](../) > **screens**

---

## 模块概述

`lib/screens/` 是 Memento 应用的屏幕层，包含应用的主要页面和界面组件。每个屏幕负责特定的用户界面功能，如主屏幕、设置、测试页面等。

### 已有文档的模块

| 模块 | 说明 | 文档 |
|-----|------|-----|
| home_screen | 主屏幕，插件卡片布局和小组件系统 | [查看](home_screen/CLAUDE.md) |
| js_console | JavaScript 控制台 | [查看](js_console/CLAUDE.md) |
| settings_screen | 设置界面 | [查看](settings_screen/CLAUDE.md) |

---

## 模块列表

### 1. home_screen (主屏幕)

**职责**: 应用的主入口，展示插件卡片和小组件网格

**主要文件**:
- `home_screen.dart` - 主屏幕入口
- `home_screen_controller.dart` - 控制器
- `home_screen_view.dart` - 视图
- `managers/home_layout_manager.dart` - 布局管理器
- `managers/home_widget_registry.dart` - 小组件注册中心
- `widgets/home_grid.dart` - 网格布局
- `widgets/home_card.dart` - 卡片组件
- `widgets/add_widget_dialog.dart` - 添加组件对话框
- `widgets/create_folder_dialog.dart` - 创建文件夹对话框
- `widgets/folder_dialog.dart` - 文件夹内容对话框

**详细文档**: [home_screen/CLAUDE.md](home_screen/CLAUDE.md)

---

### 2. js_console (JavaScript 控制台)

**职责**: JavaScript 代码执行和调试控制台

**主要文件**:
- `js_console_screen.dart` - 控制台界面
- `controllers/js_console_controller.dart` - 控制器
- `widgets/code_editor.dart` - 代码编辑器
- `widgets/output_viewer.dart` - 输出查看器
- `widgets/example_buttons.dart` - 示例按钮

**功能**:
- 代码编辑和执行
- 输出显示
- 示例代码快速插入

---

### 3. settings_screen (设置界面)

**职责**: 应用设置、数据管理、同步配置等

**主要文件**:
- `settings_screen.dart` - 设置主界面
- `screens/data_management_screen.dart` - 数据管理界面
- `screens/live_activities_test_screen.dart` - Live Activities 测试
- `controllers/settings_screen_controller.dart` - 设置控制器
- `controllers/webdav_controller.dart` - WebDAV 控制器
- `controllers/webdav_sync_controller.dart` - 同步控制器
- `controllers/export_controller.dart` - 导出控制器
- `controllers/import_controller.dart` - 导入控制器
- `controllers/auto_update_controller.dart` - 自动更新控制器
- `controllers/rebuild_controller.dart` - 重建控制器
- `controllers/permission_controller.dart` - 权限控制器
- `widgets/webdav_settings_section.dart` - WebDAV 设置
- `widgets/server_sync_settings_section.dart` - 服务器同步设置
- `widgets/folder_selection_dialog.dart` - 文件夹选择对话框
- `widgets/plugin_selection_dialog.dart` - 插件选择对话框
- `widgets/backup_progress_dialog.dart` - 备份进度对话框
- `widgets/permission_request_dialog.dart` - 权限请求对话框
- `models/webdav_config.dart` - WebDAV 配置模型
- `models/server_sync_config.dart` - 服务器同步配置模型

**详细文档**: [settings_screen/CLAUDE.md](settings_screen/CLAUDE.md)

---

### 4. about_screen (关于界面)

**职责**: 显示应用信息和版本

**主要文件**:
- `about_screen.dart` - 关于界面

---

### 5. floating_widget_screen (悬浮小组件测试)

**职责**: 悬浮小组件测试界面

**主要文件**:
- `floating_widget_screen.dart` - 悬浮小组件测试界面

---

### 6. widgets_gallery (组件展示)

**职责**: 展示应用中的各种 UI 组件使用示例

**主要文件**:
- `widgets_gallery_screen.dart` - 展示主页
- `screens/` - 各组件示例页面
  - `color_picker_example.dart` - 颜色选择器示例
  - `icon_picker_example.dart` - 图标选择器示例
  - `avatar_picker_example.dart` - 头像选择器示例
  - `circle_icon_picker_example.dart` - 圆形图标选择器示例
  - `calendar_strip_picker_example.dart` - 日历条选择器示例
  - `image_picker_example.dart` - 图片选择器示例
  - `location_picker_example.dart` - 位置选择器示例
  - `backup_time_picker_example.dart` - 备份时间选择器示例
  - `memento_editor_example.dart` - 编辑器示例
  - `data_selector_example.dart` - 数据选择器示例
  - `enhanced_calendar_example.dart` - 增强日历示例
  - `group_selector_example.dart` - 分组选择器示例
  - `simple_group_selector_example.dart` - 简单分组选择器示例
  - `tag_manager_example.dart` - 标签管理器示例
  - `statistics_example.dart` - 统计组件示例
  - `custom_dialog_example.dart` - 自定义对话框示例
  - `smooth_bottom_sheet_example.dart` - 底部面板示例
  - `file_preview_example.dart` - 文件预览示例
  - `app_drawer_example.dart` - 抽屉示例
  - `widget_config_editor_example.dart` - 组件配置编辑器示例
  - `preset_edit_form_example.dart` - 预设编辑表单示例
  - `super_cupertino_navigation_example.dart` - 导航示例

---

### 7. test_screens (测试页面)

**职责**: 各种功能的测试页面

**主要文件**:
- `swipe_action_test_screen.dart` - 滑动操作测试

---

### 8. data_selector_test (数据选择器测试)

**职责**: 数据选择器组件测试

**主要文件**:
- `data_selector_test_screen.dart` - 测试界面

---

### 9. form_fields_test (表单字段测试)

**职责**: 表单字段组件测试

**主要文件**:
- `form_fields_test_screen.dart` - 测试界面

---

### 10. 其他测试页面

| 页面 | 文件 | 说明 |
|-----|------|------|
| 通知测试 | `notification_test/notification_test_page.dart` | 通知功能测试 |
| 意图测试 | `intent_test_screen/intent_test_screen.dart` | 意图处理测试 |
| JSON 动态测试 | `json_dynamic_test/json_dynamic_test_screen.dart` | JSON 解析测试 |
| Toast 测试 | `toast_test/toast_test_screen.dart` | Toast 提示测试 |

---

## 路由配置

**路由文件**: `route.dart`

**路由管理器**: `AppRoutes`

### 主要路由

| 路径 | 屏幕 | 说明 |
|-----|------|------|
| `/` | HomeScreen | 主屏幕（默认） |
| `/settings` | SettingsScreen | 设置界面 |
| `/js_console` | JSConsoleScreen | JavaScript 控制台 |
| `/widgets_gallery` | WidgetsGalleryScreen | 组件展示 |
| `/floating_ball` | FloatingBallScreen | 悬浮球设置 |
| `/about` | AboutScreen | 关于界面 |

### 测试路由

| 路径 | 屏幕 |
|-----|------|
| `/notification_test` | NotificationTestPage |
| `/json_dynamic_test` | JsonDynamicTestScreen |
| `/data_selector_test` | DataSelectorTestScreen |
| `/swipe_action_test` | SwipeActionTestScreen |
| `/form_fields_test` | FormFieldsTestScreen |

### 组件展示路由

| 路径 | 屏幕 |
|-----|------|
| `/widgets_gallery/color_picker` | ColorPickerExample |
| `/widgets_gallery/icon_picker` | IconPickerExample |
| `/widgets_gallery/image_picker` | ImagePickerExample |
| `/widgets_gallery/*` | 其他组件示例 |

---

## 公共组件

### l10n (国际化)

**文件**:
- `screens_translations.dart` - 翻译接口
- `screens_translations_zh.dart` - 中文翻译
- `screens_translations_en.dart` - 英文翻译

---

## 屏幕开发指南

### 创建新屏幕

1. **创建屏幕文件**
   ```dart
   // lib/screens/my_screen/my_screen.dart
   import 'package:flutter/material.dart';

   class MyScreen extends StatelessWidget {
     const MyScreen({super.key});

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text('My Screen')),
         body: Center(child: Text('Hello')),
       );
     }
   }
   ```

2. **添加路由**
   ```dart
   // 在 lib/screens/route.dart 中
   static const String myScreen = '/my_screen';

   case '/my_screen':
   case 'my_screen':
     return _createRoute(const MyScreen());
   ```

3. **导航到屏幕**
   ```dart
   Navigator.pushNamed(context, AppRoutes.myScreen);
   ```

### 使用控制器模式

```dart
// 控制器
class MyScreenController {
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  Future<void> loadData() async {
    isLoading.value = true;
    // 加载数据
    isLoading.value = false;
  }

  void dispose() {
    isLoading.dispose();
  }
}

// 屏幕
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final MyScreenController _controller = MyScreenController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: _controller.isLoading,
        builder: (context, loading, _) {
          if (loading) return CircularProgressIndicator();
          return ContentWidget();
        },
      ),
    );
  }
}
```

---

## 常见问题

### Q1: 如何在设置中添加新选项？

在 `settings_screen.dart` 的 `build` 方法中添加新的 `ListTile`：

```dart
ListTile(
  leading: Icon(Icons.new_feature),
  title: Text('新功能'),
  trailing: Icon(Icons.chevron_right),
  onTap: () {
    // 导航到设置页面
  },
),
```

### Q2: 如何创建测试页面？

在相应的测试目录中创建新文件，并在 `route.dart` 中添加路由：

```dart
case '/my_test':
  return _createRoute(const MyTestScreen());
```

### Q3: 如何在组件展示中添加新示例？

1. 在 `widgets_gallery/screens/` 创建示例文件
2. 在 `WidgetsGalleryScreen` 中添加列表项
3. 在 `route.dart` 中添加路由

---

## 相关文档

- [lib/widgets - 通用组件库](../widgets/CLAUDE.md)
- [lib/core - 核心功能](../core/CLAUDE.md)
- [lib/plugins - 插件系统](../plugins/CLAUDE.md)
