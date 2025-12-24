# widgets - 通用组件库

[根目录](../../CLAUDE.md) > [lib](../CLAUDE.md) > **widgets**

## 模块概述

`lib/widgets/` 是 Memento 应用的通用组件库，包含项目中多处使用的可复用 UI 组件。这些组件涵盖了编辑器、对话框、选择器、预览器等多种类型，为应用提供统一的用户界面和交互体验。

### 设计原则

- **可复用性**：组件设计为通用形式，可在不同插件和页面中使用
- **可配置性**：通过参数和回调提供灵活的配置选项
- **国际化支持**：集成多语言支持，适配中英文环境
- **状态管理**：合理使用 StatefulWidget 和 StatelessWidget
- **主题适配**：自动适应应用主题和深色模式

### 使用约定

1. **导入方式**：通常使用具名导入
   ```dart
   import 'package:Memento/widgets/markdown_editor/index.dart';
   import 'package:Memento/widgets/file_preview/index.dart';
   ```

2. **回调约定**：使用 `onXxx` 命名回调函数
3. **配置类**：复杂组件提供独立的配置类（如 `TagManagerConfig`）
4. **本地化**：使用 `Localizations` 提供多语言支持

## 组件分类

### 1. 编辑器类
- **QuillEditor**：Markdown 编辑器，支持预览和工具栏

### 2. 选择器类
- **LocationPicker**：位置选择器，支持搜索和当前定位
- **IconPickerDialog**：图标选择器，支持搜索和分页
- **ImagePickerDialog**：图片选择器，支持相册、相机和裁剪
- **AvatarPicker**：头像选择器，圆形头像显示
- **CircleIconPicker**：圆形图标选择器，支持图标和背景色选择
- **ColorPickerSection**：颜色选择器，提供常用颜色
- **GroupSelectorDialog**：分组选择器，支持增删改
- **SimpleGroupSelector**：简单分组选择器，仅支持选择
- **BackupTimePicker**：备份时间选择器，支持多种计划类型

### 3. 对话框类
- **TagManagerDialog**：标签管理对话框，功能强大的标签管理系统
- **CustomDialog**：自定义对话框，处理键盘遮挡
- **ImportDialog**：导入对话框，支持选择插件数据

### 4. 预览器类
- **FilePreviewScreen**：文件预览界面，支持图片、视频和文件
- **VideoPreview**：视频预览组件

### 5. 导航类
- **AppBarWidget**：应用栏组件，统一的顶部导航
- **AppDrawer**：应用抽屉，插件管理和设置入口

## 核心组件详解

### QuillEditor

Markdown 编辑器组件，提供完整的 Markdown 编辑和预览功能。

#### 构造函数参数

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|-----|------|-----|--------|------|
| initialTitle | String? | 否 | null | 初始标题内容 |
| initialContent | String? | 否 | null | 初始正文内容 |
| showTitle | bool | 否 | true | 是否显示标题输入框 |
| titleHint | String | 否 | '输入标题...' | 标题输入框提示文本 |
| contentHint | String | 否 | '输入内容...' | 内容输入框提示文本 |
| onSave | Function(String, String) | 是 | - | 保存回调，返回标题和内容 |
| onCancel | VoidCallback? | 否 | null | 取消回调 |
| showSaveButton | bool | 否 | true | 是否显示保存按钮 |
| showPreviewButton | bool | 否 | true | 是否显示预览按钮 |
| autofocus | bool | 否 | true | 是否自动聚焦到内容区 |
| actions | List<Widget>? | 否 | null | 自定义 AppBar 操作按钮 |
| extraActions | List<Widget>? | 否 | null | 额外的操作按钮 |

#### 功能特性

- **双模式切换**：编辑模式和预览模式无缝切换
- **富工具栏**：提供粗体、斜体、列表、代码块等常用格式
- **语法插入**：支持 Markdown 语法快速插入
- **实时预览**：使用 flutter_quill 渲染预览内容

#### 使用示例

```dart
import 'package:Memento/widgets/markdown_editor/index.dart';

// 基础使用
QuillEditor(
  initialTitle: '我的笔记',
  initialContent: '# 标题\n内容',
  onSave: (title, content) {
    print('保存: $title - $content');
  },
)

// 自定义工具栏
QuillEditor(
  showTitle: false,
  contentHint: '请输入备注...',
  actions: [
    IconButton(
      icon: Icon(Icons.attach_file),
      onPressed: () {
        // 附件功能
      },
    ),
  ],
  onSave: (title, content) {
    // 保存逻辑
  },
)
```

#### 注意事项

- 如果 `showTitle` 为 true，保存时会验证标题不为空
- 工具栏按钮在预览模式下会隐藏
- 使用 `actions` 会完全替换默认按钮，使用 `extraActions` 会追加按钮

---

### FilePreviewScreen

通用文件预览界面，支持多种文件类型的预览和分享。

#### 构造函数参数

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|-----|------|-----|--------|------|
| filePath | String | 是 | - | 文件路径（支持相对和绝对路径） |
| fileName | String | 是 | - | 文件名称 |
| mimeType | String | 是 | - | 文件 MIME 类型 |
| fileSize | int | 是 | - | 文件大小（字节） |
| isVideo | bool | 否 | false | 是否为视频文件 |

#### 功能特性

- **多格式支持**：图片、视频、通用文件
- **路径解析**：自动处理相对路径和绝对路径
- **文件验证**：检查文件是否存在
- **缩放预览**：图片支持缩放和拖动（PhotoView）
- **分享功能**：使用 share_plus 分享文件
- **文件信息**：显示文件位置和详细信息

#### 使用示例

```dart
import 'package:Memento/widgets/file_preview/index.dart';

// 预览图片
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FilePreviewScreen(
      filePath: 'app_data/images/photo.jpg',
      fileName: 'photo.jpg',
      mimeType: 'image/jpeg',
      fileSize: 1024000,
    ),
  ),
);

// 预览视频
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FilePreviewScreen(
      filePath: '/path/to/video.mp4',
      fileName: 'video.mp4',
      mimeType: 'video/mp4',
      fileSize: 5120000,
      isVideo: true,
    ),
  ),
);
```

#### 注意事项

- 相对路径会自动拼接应用文档目录
- 文件不存在时会显示错误提示
- 视频预览依赖 VideoPreview 组件
- 移动端点击"打开位置"显示文件信息对话框

---

### TagManagerDialog

功能强大的标签管理对话框，支持分组、编辑、选择等操作。

#### 构造函数参数

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|-----|------|-----|--------|------|
| groups | List&lt;TagGroup&gt; | 是 | - | 标签分组列表 |
| selectedTags | List&lt;String&gt; | 是 | - | 已选择的标签列表 |
| onGroupsChanged | Function(List&lt;TagGroup&gt;) | 是 | - | 标签分组变更回调 |
| onTagsSelected | Function(List&lt;String&gt;)? | 否 | null | 标签选择变更回调 |
| enableEditing | bool | 否 | true | 是否启用编辑功能 |
| onAddTag | Future&lt;String?&gt; Function(String, {String?})? | 否 | null | 添加标签回调 |
| config | TagManagerConfig? | 否 | null | 配置选项 |
| onRefreshData | Future&lt;List&lt;TagGroup&gt;&gt; Function()? | 否 | null | 获取最新数据源的回调 |

#### TagGroup 数据模型

```dart
class TagGroup {
  final String name;         // 分组名称
  final List<String> tags;   // 标签列表
  final List<String>? tagIds; // 标签 ID 列表（可选）

  const TagGroup({
    required this.name,
    required this.tags,
    this.tagIds,
  });
}
```

#### TagManagerConfig 配置

```dart
class TagManagerConfig {
  final String title;              // 对话框标题
  final String addGroupHint;       // 添加分组提示
  final String addTagHint;         // 添加标签提示
  final String editGroupHint;      // 编辑分组提示
  final String allTagsLabel;       // "所有标签"标签
  final String newGroupLabel;      // "新建分组"标签
  final Color? selectedTagColor;   // 选中标签颜色
  final Color? checkmarkColor;     // 勾选标记颜色
}
```

#### 使用示例

```dart
import 'package:Memento/widgets/tag_manager_dialog.dart';

// 基础使用
final result = await showDialog<List<String>>(
  context: context,
  builder: (context) => TagManagerDialog(
    groups: [
      TagGroup(name: '工作', tags: ['重要', '紧急']),
      TagGroup(name: '生活', tags: ['购物', '娱乐']),
    ],
    selectedTags: ['重要'],
    onGroupsChanged: (newGroups) {
      // 保存新的分组结构
      _saveGroups(newGroups);
    },
  ),
);

if (result != null) {
  print('选择的标签: $result');
}

// 高级使用 - 带配置和回调
showDialog<List<String>>(
  context: context,
  builder: (context) => TagManagerDialog(
    groups: _tagGroups,
    selectedTags: _selectedTags,
    enableEditing: true,
    config: TagManagerConfig(
      title: '我的标签',
      addTagHint: '输入标签名称',
      selectedTagColor: Colors.blue,
    ),
    onGroupsChanged: (groups) {
      setState(() => _tagGroups = groups);
    },
    onTagsSelected: (tags) {
      print('实时选择: $tags');
    },
    onAddTag: (group, {tag}) async {
      // 自定义添加逻辑
      return await _addTagToDatabase(group, tag);
    },
    onRefreshData: () async {
      return await _fetchLatestTags();
    },
  ),
);
```

#### 注意事项

- `onGroupsChanged` 在分组结构变化时触发（添加、删除、重命名）
- `onTagsSelected` 实时返回当前选中的标签
- 对话框关闭时返回最终选中的标签列表
- 禁用编辑时隐藏添加、删除、编辑按钮

---

### LocationPicker

位置选择器，集成高德地图 API，支持搜索和定位。

#### 构造函数参数

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|-----|------|-----|--------|------|
| onLocationSelected | ValueChanged&lt;String&gt; | 是 | - | 位置选择回调 |
| isMobile | bool | 是 | - | 是否为移动端 |

#### 功能特性

- **搜索功能**：支持关键词搜索地点
- **当前定位**：获取用户当前位置和周边 POI
- **地址显示**：显示详细地址信息
- **权限处理**：自动请求定位权限

#### 使用示例

```dart
import 'package:Memento/widgets/location_picker.dart';

showDialog(
  context: context,
  builder: (context) => LocationPicker(
    isMobile: Platform.isAndroid || Platform.isIOS,
    onLocationSelected: (address) {
      print('选择的位置: $address');
      _saveLocation(address);
    },
  ),
);
```

#### 注意事项

- 使用高德地图 API（需要 API Key）
- 需要定位权限（location 包）
- 搜索结果包含地点名称和详细地址
- 移动端和桌面端有不同的交互

---

### ImagePickerDialog

图片选择器，支持相册、相机和图片裁剪。

#### 构造函数参数

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|-----|------|-----|--------|------|
| initialUrl | String? | 否 | null | 初始图片 URL |
| saveDirectory | String | 否 | 'app_images' | 图片保存目录 |
| enableCrop | bool | 否 | false | 是否启用裁剪 |
| cropAspectRatio | double? | 否 | null | 裁剪比例（如 1.0 表示 1:1） |
| multiple | bool | 否 | false | 是否允许多选 |

#### 返回值

```dart
// 单张图片
Map<String, dynamic> {
  'url': String,           // 图片相对路径
  'bytes': Uint8List?,     // 图片字节数据（可选）
}

// 多张图片
List<Map<String, dynamic>>
```

#### 使用示例

```dart
import 'package:Memento/widgets/image_picker_dialog.dart';

// 单图选择
final result = await showDialog<Map<String, dynamic>>(
  context: context,
  builder: (context) => ImagePickerDialog(
    saveDirectory: 'avatars',
  ),
);

if (result != null) {
  final imagePath = result['url'] as String;
  setState(() => _imagePath = imagePath);
}

// 裁剪为圆形头像
final result = await showDialog<Map<String, dynamic>>(
  context: context,
  builder: (context) => ImagePickerDialog(
    saveDirectory: 'avatars',
    enableCrop: true,
    cropAspectRatio: 1.0,
  ),
);

// 多图选择
final results = await showDialog<List<Map<String, dynamic>>>(
  context: context,
  builder: (context) => ImagePickerDialog(
    multiple: true,
    saveDirectory: 'photos',
  ),
);

if (results != null) {
  for (var item in results) {
    final path = item['url'] as String;
    _imageList.add(path);
  }
}
```

#### 注意事项

- 图片自动保存到 `app_data/{saveDirectory}/` 目录
- 裁剪后会替换原文件
- 返回的 `url` 是相对路径，需要使用 `ImageUtils.getAbsolutePath()` 转换
- 支持在线 URL 输入

---

### AvatarPicker

圆形头像选择器，专门用于用户头像选择。

#### 构造函数参数

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|-----|------|-----|--------|------|
| size | double | 否 | 80.0 | 头像大小 |
| username | String | 是 | - | 用户名（用于默认头像） |
| currentAvatarPath | String? | 否 | null | 当前头像路径 |
| saveDirectory | String | 否 | 'avatars' | 头像保存目录 |
| onAvatarChanged | Function(String)? | 否 | null | 头像变更回调 |
| showPickerDialog | Function? | 否 | null | 自定义选择器对话框 |

#### 使用示例

```dart
import 'package:Memento/widgets/avatar_picker.dart';

AvatarPicker(
  size: 100,
  username: 'John Doe',
  currentAvatarPath: _avatarPath,
  onAvatarChanged: (newPath) {
    setState(() => _avatarPath = newPath);
    _saveAvatar(newPath);
  },
)
```

#### 注意事项

- 点击头像触发选择
- 无头像时显示用户名首字母
- 自动处理图片缓存更新
- 强制 1:1 裁剪比例
- 文件名自动生成为随机字符串

---

### IconPickerDialog

图标选择器对话框，提供大量预定义图标。

#### 使用方法

```dart
import 'package:Memento/widgets/icon_picker_dialog.dart';

// 显示图标选择器
final IconData? selectedIcon = await showIconPickerDialog(
  context,
  Icons.home,  // 当前图标
);

if (selectedIcon != null) {
  setState(() => _icon = selectedIcon);
}
```

#### 功能特性

- **搜索功能**：支持按名称搜索图标
- **分页显示**：每页显示 200 个图标
- **预定义集合**：使用 `AppIcons.predefinedIcons` 中的图标
- **防抖搜索**：500ms 延迟搜索

---

### GroupSelectorDialog

分组选择器，支持分组的增删改查。

#### 构造函数参数

| 参数 | 类型 | 必需 | 说明 |
|-----|------|-----|------|
| groups | List&lt;String&gt; | 是 | 分组列表 |
| onGroupRenamed | OnGroupRenamed | 是 | 分组重命名回调 |
| onGroupDeleted | OnGroupDeleted | 是 | 分组删除回调 |
| initialSelectedGroup | String? | 否 | 初始选中的分组 |

#### 使用示例

```dart
import 'package:Memento/widgets/group_selector_dialog.dart';

final selectedGroup = await showDialog<String>(
  context: context,
  builder: (context) => GroupSelectorDialog(
    groups: ['工作', '生活', '学习'],
    initialSelectedGroup: '工作',
    onGroupRenamed: (oldName, newName) {
      _renameGroup(oldName, newName);
    },
    onGroupDeleted: (groupName) {
      _deleteGroup(groupName);
    },
  ),
);

if (selectedGroup != null) {
  print('选择的分组: $selectedGroup');
}
```

---

### CustomDialog

自定义对话框，解决键盘遮挡问题。

#### 构造函数参数

| 参数 | 类型 | 必需 | 说明 |
|-----|------|-----|------|
| title | String | 是 | 对话框标题 |
| content | Widget | 是 | 对话框内容 |
| actions | List&lt;Widget&gt; | 是 | 操作按钮列表 |

#### 使用示例

```dart
import 'package:Memento/widgets/custom_dialog.dart';

showDialog(
  context: context,
  builder: (context) => CustomDialog(
    title: '设置',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(decoration: InputDecoration(labelText: '名称')),
        SizedBox(height: 16),
        TextField(decoration: InputDecoration(labelText: '描述')),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('取消'),
      ),
      ElevatedButton(
        onPressed: () {
          // 保存逻辑
          Navigator.pop(context);
        },
        child: Text('保存'),
      ),
    ],
  ),
);
```

---

### BackupTimePicker

备份时间选择器，支持多种备份计划。

#### BackupScheduleType 类型

```dart
enum BackupScheduleType {
  specificDate,  // 指定日期
  daily,         // 每天
  weekly,        // 每周指定日
  monthly,       // 每月指定日
}
```

#### 使用示例

```dart
import 'package:Memento/widgets/backup_time_picker.dart';

showDialog(
  context: context,
  builder: (context) => BackupTimePicker(
    initialSchedule: _currentSchedule,
    onScheduleSelected: (schedule) {
      setState(() => _backupSchedule = schedule);
      _saveSchedule(schedule);
    },
  ),
);
```

---

## 目录结构

```
lib/widgets/
├── custom_dialog.dart                          # 自定义对话框
├── app_bar_widget.dart                         # 应用栏组件
├── app_drawer.dart                             # 应用抽屉
│
├── markdown_editor/                            # Quill 富文本编辑器模块
│   ├── index.dart                              # 导出文件
│   ├── quill_editor.dart                       # 编辑器实现
│   └── quill_viewer.dart                       # 查看器实现
│
├── file_preview/                               # 文件预览模块
│   ├── index.dart                              # 导出文件
│   ├── file_preview_screen.dart                # 预览界面
│   ├── video_preview.dart                      # 视频预览组件
│   └── l10n/                                   # 本地化
│       ├── file_preview_localizations.dart
│       ├── file_preview_localizations_en.dart
│       └── file_preview_localizations_zh.dart
│
├── tag_manager_dialog/                         # 标签管理对话框模块
│   ├── models/                                 # 数据模型
│   │   ├── tag_group.dart                      # 标签分组模型
│   │   └── tag_manager_config.dart             # 配置模型
│   ├── states/                                 # 状态管理
│   │   └── tag_manager_dialog_state.dart       # 对话框状态
│   ├── widgets/                                # UI 组件
│   │   ├── tag_manager_dialog.dart             # 主对话框
│   │   ├── dialog_toolbar.dart                 # 工具栏
│   │   ├── dialog_actions.dart                 # 底部操作
│   │   └── tag_list.dart                       # 标签列表
│   ├── services/                               # 服务
│   │   └── dialog_service.dart                 # 对话框服务
│   └── l10n/                                   # 本地化
│       ├── tag_manager_localizations.dart
│       └── tag_manager_dialog_localizations.dart
│
├── tag_manager_dialog.dart                     # 标签管理对话框导出
├── location_picker.dart                        # 位置选择器
├── icon_picker_dialog.dart                     # 图标选择器
├── image_picker_dialog.dart                    # 图片选择器
├── avatar_picker.dart                          # 头像选择器
├── circle_icon_picker.dart                     # 圆形图标选择器
├── color_picker_section.dart                   # 颜色选择器
├── group_selector_dialog.dart                  # 分组选择器（完整功能）
├── simple_group_selector.dart                  # 简单分组选择器
├── backup_time_picker.dart                     # 备份时间选择器
├── import_dialog.dart                          # 导入对话框
│
└── l10n/                                       # 本地化文件
    ├── group_selector_localizations.dart
    ├── group_selector_localizations_en.dart
    ├── group_selector_localizations_zh.dart
    ├── location_picker_localizations.dart
    ├── location_picker_localizations_en.dart
    ├── location_picker_localizations_zh.dart
    ├── image_picker_localizations.dart
    ├── image_picker_localizations_en.dart
    └── image_picker_localizations_zh.dart
```

## 依赖关系

### 核心依赖

- **flutter/material.dart**：Flutter 框架基础
- **Memento/l10n/app_localizations.dart**：应用国际化

### 第三方包依赖

| 包名 | 用途 | 使用组件 |
|-----|------|---------|
| flutter_quill | Markdown 渲染 | QuillEditor |
| photo_view | 图片缩放预览 | FilePreviewScreen |
| share_plus | 文件分享 | FilePreviewScreen |
| image_picker | 图片选择 | ImagePickerDialog, AvatarPicker |
| crop_your_image | 图片裁剪 | ImagePickerDialog |
| location | 位置服务 | LocationPicker |
| http | 网络请求 | LocationPicker |
| flutter_colorpicker | 颜色选择 | CircleIconPicker |
| path | 路径处理 | 多个组件 |

### 内部依赖

- **core/storage/storage_manager.dart**：存储管理
- **core/plugin_base.dart**：插件基类
- **constants/app_icons.dart**：图标常量
- **utils/image_utils.dart**：图片工具类

## 开发指南

### 添加新组件

1. **创建组件文件**
   ```dart
   // lib/widgets/my_component.dart
   import 'package:flutter/material.dart';

   class MyComponent extends StatelessWidget {
     const MyComponent({super.key});

     @override
     Widget build(BuildContext context) {
       return Container();
     }
   }
   ```

2. **添加国际化支持**（如需要）
   ```dart
   // lib/widgets/l10n/my_component_localizations.dart
   ```

3. **复杂组件使用模块化结构**
   ```
   lib/widgets/my_component/
   ├── index.dart
   ├── my_component.dart
   ├── models/
   ├── widgets/
   └── l10n/
   ```

### 组件命名规范

- **选择器类**：使用 `XxxPicker` 或 `XxxSelector`
- **对话框类**：使用 `XxxDialog`
- **预览器类**：使用 `XxxPreview` 或 `XxxScreen`
- **工具类**：使用 `XxxWidget` 或具体名称

### 代码风格要求

1. **参数顺序**：必需参数 → 可选参数 → 回调函数
2. **构造函数**：使用 `const` 构造函数（如可能）
3. **类型安全**：明确指定泛型类型
4. **注释**：为公共 API 添加文档注释
5. **状态管理**：优先使用 StatelessWidget，必要时使用 StatefulWidget
6. **资源释放**：在 `dispose()` 中释放资源

### 示例模板

```dart
import 'package:flutter/material.dart';
import 'package:Memento/l10n/app_localizations.dart';

/// [组件名称] - 简要描述
///
/// 详细说明...
class MyComponent extends StatefulWidget {
  /// 必需参数描述
  final String requiredParam;

  /// 可选参数描述
  final String? optionalParam;

  /// 回调函数描述
  final ValueChanged<String>? onChanged;

  const MyComponent({
    super.key,
    required this.requiredParam,
    this.optionalParam,
    this.onChanged,
  });

  @override
  State<MyComponent> createState() => _MyComponentState();
}

class _MyComponentState extends State<MyComponent> {
  // 状态变量

  @override
  void initState() {
    super.initState();
    // 初始化
  }

  @override
  void dispose() {
    // 清理资源
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // UI 实现
    );
  }
}
```

## 常见问题

### Q1: 如何在组件中使用国际化？

```dart
import 'package:Memento/l10n/app_localizations.dart';

// 在 build 方法中
Text(AppLocalizations.of(context)!.someKey)
```

### Q2: 如何处理组件的异步操作？

使用 `FutureBuilder` 或 `async/await` 配合状态管理：

```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  try {
    final data = await fetchData();
    setState(() {
      _data = data;
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    // 错误处理
  }
}
```

### Q3: 如何处理键盘遮挡输入框？

使用 `CustomDialog` 或在布局中使用 `MediaQuery.of(context).viewInsets.bottom`：

```dart
Padding(
  padding: EdgeInsets.only(
    bottom: MediaQuery.of(context).viewInsets.bottom,
  ),
  child: TextField(),
)
```

### Q4: 如何实现组件的主题适配？

使用 `Theme.of(context)` 获取主题：

```dart
Container(
  color: Theme.of(context).colorScheme.primary,
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.titleLarge,
  ),
)
```

### Q5: ImagePickerDialog 返回的路径如何使用？

```dart
// 获取相对路径
final result = await showDialog(...);
final relativePath = result['url'] as String;

// 转换为绝对路径
final absolutePath = await ImageUtils.getAbsolutePath(relativePath);

// 使用文件
final file = File(absolutePath);
if (await file.exists()) {
  // 显示图片
  Image.file(file)
}
```

### Q6: 如何自定义 TagManagerDialog 的样式？

```dart
TagManagerDialog(
  // ... 其他参数
  config: TagManagerConfig(
    title: '我的标签',
    selectedTagColor: Colors.blue,
    checkmarkColor: Colors.white,
    addTagHint: '添加新标签',
  ),
)
```

### Q7: 如何处理文件选择和权限问题？

```dart
try {
  final result = await ImagePicker().pickImage(source: ImageSource.gallery);
  // 处理结果
} catch (e) {
  if (e.toString().contains('permission')) {
    // 显示权限提示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('需要权限'),
        content: Text('请在设置中授予相册访问权限'),
      ),
    );
  }
}
```

## 最佳实践

1. **组件复用**：优先使用现有组件，避免重复造轮
2. **状态提升**：将状态提升到需要共享的最低公共父组件
3. **性能优化**：使用 `const` 构造函数，避免不必要的重建
4. **错误处理**：为异步操作添加错误处理和加载状态
5. **国际化**：所有用户可见的文本都应该国际化
6. **无障碍**：为图标按钮添加 `tooltip` 和语义标签
7. **测试**：为复杂组件编写单元测试和集成测试

## 维护说明

- **负责人**：Widgets 团队
- **更新频率**：根据需求持续迭代
- **版本兼容性**：遵循应用主版本
- **文档同步**：组件更新时同步更新此文档

---

**相关文档**：
- [lib/core - 核心功能](../core/CLAUDE.md)
- [lib/plugins - 插件系统](../plugins/CLAUDE.md)
- [lib/l10n - 国际化](../l10n/CLAUDE.md)
