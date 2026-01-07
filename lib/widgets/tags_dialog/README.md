# TagsDialog 使用指南

全新的标签管理组件，基于 SuperCupertinoNavigationWrapper 构建，提供强大的标签管理功能。

## 功能特性

- ✅ 支持 JSON 文件存储（自动读取/保存）
- ✅ 支持直接传入数据参数
- ✅ 搜索功能（标题、注释搜索）
- ✅ 多条件过滤（分组过滤、排序）
- ✅ 长按弹出底部抽屉（编辑、删除）
- ✅ 批量编辑功能
- ✅ 单击选择模式（单选/多选/无选择）
- ✅ 嵌入/对话框两种显示模式

## 目录结构

```
lib/widgets/tags_dialog/
├── models/
│   ├── tag_item.dart           # 标签数据模型
│   ├── tags_dialog_config.dart # 配置类
│   └── models.dart             # 模型导出
├── widgets/
│   ├── tags_dialog.dart        # 主组件
│   ├── tags_list.dart          # 标签列表
│   ├── bottom_sheet_menu.dart  # 底部抽屉菜单
│   └── widgets.dart            # 组件导出
├── utils/
│   ├── json_storage.dart       # JSON 存储工具
│   └── utils.dart              # 工具导出
├── tags_dialog.dart            # 主导出文件
└── README.md                   # 使用文档
```

## 数据模型

### TagItem

```dart
class TagItem {
  final String name;              // 标签名称
  final IconData icon;            // 标签图标
  final String group;             // 标签分组
  final String? comment;          // 标签注释
  final DateTime createdAt;       // 添加时间
  final DateTime? lastUsedAt;     // 最后使用时间
}
```

### TagGroupWithTags

```dart
class TagGroupWithTags {
  final String name;              // 分组名称
  final List<TagItem> tags;       // 标签列表
}
```

## 使用示例

### 1. 对话框模式 + JSON 文件存储

```dart
import 'package:Memento/widgets/tags_dialog/tags_dialog.dart';

// 显示对话框，自动从 JSON 文件读取和保存
final selectedTags = await TagsDialog.show(
  context,
  jsonFilePath: 'app_data/tags.json',
  config: TagsDialogConfig(
    title: '标签管理',
    selectionMode: TagsSelectionMode.multiple,
  ),
);

if (selectedTags != null) {
  print('选择的标签: $selectedTags');
}
```

### 2. 对话框模式 + 直接传参

```dart
final groups = [
  TagGroupWithTags(
    name: '工作',
    tags: [
      TagItem(
        name: '重要',
        group: '工作',
        icon: Icons.star,
        createdAt: DateTime.now(),
      ),
      TagItem(
        name: '紧急',
        group: '工作',
        icon: Icons.priority_high,
        comment: '需要立即处理',
        createdAt: DateTime.now(),
      ),
    ],
  ),
  TagGroupWithTags(
    name: '生活',
    tags: [
      TagItem(
        name: '购物',
        group: '生活',
        icon: Icons.shopping_cart,
        createdAt: DateTime.now(),
      ),
    ],
  ),
];

final result = await TagsDialog.show(
  context,
  groups: groups,
  selectedTags: ['重要'],
  config: TagsDialogConfig(
    title: '选择标签',
    selectionMode: TagsSelectionMode.multiple,
  ),
  onGroupsChanged: (newGroups) {
    // 保存更新后的分组数据
    _saveGroups(newGroups);
  },
);
```

### 3. 嵌入模式（作为页面的一部分）

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TagsDialog(
      displayMode: TagsDisplayMode.embedded,
      groups: _myGroups,
      config: TagsDialogConfig(
        title: '标签管理',
        largeTitle: '我的标签',
        enableEditing: true,
        enableBatchEdit: true,
        selectionMode: TagsSelectionMode.none,
      ),
      onGroupsChanged: (groups) {
        setState(() {
          _myGroups = groups;
        });
      },
      onAddTag: (group, {tag}) async {
        // 自定义添加标签逻辑
        final newTag = await _showAddTagDialog(group);
        return newTag;
      },
      onDeleteTag: (tag) async {
        // 自定义删除逻辑
        return await _confirmDelete(tag);
      },
      onEditTag: (oldTag, newTag) async {
        // 自定义编辑逻辑
        return await _editTag(oldTag, newTag);
      },
    );
  }
}
```

### 4. 单选模式

```dart
final result = await TagsDialog.show(
  context,
  groups: _myGroups,
  config: TagsDialogConfig(
    title: '选择一个标签',
    selectionMode: TagsSelectionMode.single,
  ),
);

if (result != null && result.isNotEmpty) {
  final selectedTag = result.first;
  print('选择的标签: $selectedTag');
}
```

### 5. 多选模式

```dart
final result = await TagsDialog.show(
  context,
  groups: _myGroups,
  selectedTags: _initialSelection,
  config: TagsDialogConfig(
    title: '选择多个标签',
    selectionMode: TagsSelectionMode.multiple,
  ),
);

if (result != null) {
  print('选择了 ${result.length} 个标签: $result');
}
```

## 配置选项

### TagsDialogConfig

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| title | String | '标签管理' | 标题 |
| largeTitle | String | '标签' | 大标题 |
| searchPlaceholder | String | '搜索标签名称、注释...' | 搜索框占位符 |
| defaultIcon | IconData | Icons.label | 默认图标 |
| enableEditing | bool | true | 是否启用编辑功能 |
| enableBatchEdit | bool | true | 是否启用批量编辑 |
| enableLongPressMenu | bool | true | 是否启用长按菜单 |
| selectionMode | TagsSelectionMode | none | 选择模式 |
| confirmButtonText | String | '确定' | 确认按钮文本 |
| cancelButtonText | String | '取消' | 取消按钮文本 |
| deleteButtonText | String | '删除' | 删除按钮文本 |
| editButtonText | String | '编辑' | 编辑按钮文本 |
| addTagText | String | '添加标签' | 添加标签文本 |
| addGroupText | String | '添加分组' | 添加分组文本 |
| emptyStateText | String | '暂无标签' | 空状态提示文本 |
| selectedTagColor | Color? | null | 选中标签颜色 |
| tagCardRadius | double | 8 | 标签卡片圆角 |
| tagCardHeight | double | 60 | 标签卡片高度 |

## JSON 文件格式

```json
[
  {
    "name": "工作",
    "tags": [
      {
        "name": "重要",
        "icon": "57394",
        "group": "工作",
        "comment": "重要的事情",
        "createdAt": "2024-01-01T00:00:00.000Z",
        "lastUsedAt": "2024-01-02T00:00:00.000Z"
      },
      {
        "name": "紧急",
        "icon": "57368",
        "group": "工作",
        "comment": null,
        "createdAt": "2024-01-01T00:00:00.000Z",
        "lastUsedAt": null
      }
    ]
  },
  {
    "name": "生活",
    "tags": [
      {
        "name": "购物",
        "icon": "57395",
        "group": "生活",
        "comment": "日常购物",
        "createdAt": "2024-01-01T00:00:00.000Z",
        "lastUsedAt": "2024-01-03T00:00:00.000Z"
      }
    ]
  }
]
```

## 交互说明

### 搜索
- 在搜索框中输入关键词，实时过滤标签
- 搜索范围：标签名称、注释

### 过滤
- 点击右上角过滤按钮显示/隐藏过滤栏
- 分组过滤：选择特定分组显示
- 排序方式：
  - 添加时间：按标签创建时间排序
  - 使用时间：按最后使用时间排序
  - 名称：按标签名称字母排序

### 批量编辑
- 点击右上角编辑按钮进入批量编辑模式
- 点击标签右侧的删除按钮删除标签
- 再次点击编辑按钮退出批量编辑模式

### 长按菜单
- 长按标签弹出底部抽屉
- 可选择：编辑、删除

### 选择模式
- 无选择模式：仅查看和管理标签
- 单选模式：点击标签选择一个
- 多选模式：点击标签选择多个
- 选择后点击确定按钮返回结果

## 迁移指南

### 从 TagManagerDialog 迁移到 TagsDialog

```dart
// 旧代码
final result = await showDialog<List<String>>(
  context: context,
  builder: (context) => TagManagerDialog(
    groups: [
      TagGroup(name: '工作', tags: ['重要', '紧急']),
      TagGroup(name: '生活', tags: ['购物']),
    ],
    selectedTags: ['重要'],
    onGroupsChanged: (groups) {
      _saveGroups(groups);
    },
  ),
);

// 新代码
final result = await TagsDialog.show(
  context,
  groups: [
    TagGroupWithTags(
      name: '工作',
      tags: [
        TagItem(name: '重要', group: '工作', createdAt: DateTime.now()),
        TagItem(name: '紧急', group: '工作', createdAt: DateTime.now()),
      ],
    ),
    TagGroupWithTags(
      name: '生活',
      tags: [
        TagItem(name: '购物', group: '生活', createdAt: DateTime.now()),
      ],
    ),
  ],
  selectedTags: ['重要'],
  onGroupsChanged: (groups) {
    _saveGroups(groups);
  },
);
```

## 注意事项

1. **图标存储**：图标使用 codePoint 存储在 JSON 中，需要 Material Icons 字体支持
2. **时间格式**：时间使用 ISO 8601 格式存储
3. **JSON 路径**：使用相对路径，会自动创建目录
4. **回调函数**：提供回调函数可实现自定义的增删改逻辑
5. **状态管理**：组件内部管理状态，通过回调通知外部变更

## 示例场景

### 场景1：日记标签管理

```dart
final tags = await TagsDialog.show(
  context,
  jsonFilePath: 'app_data/diary_tags.json',
  config: TagsDialogConfig(
    title: '日记标签',
    largeTitle: '标签',
    enableEditing: true,
    enableBatchEdit: false,
    selectionMode: TagsSelectionMode.multiple,
  ),
);

if (tags != null) {
  _diary.tags = tags;
  _saveDiary();
}
```

### 场景2：任务标签选择

```dart
final tag = await TagsDialog.show(
  context,
  jsonFilePath: 'app_data/task_tags.json',
  config: TagsDialogConfig(
    title: '选择任务标签',
    selectionMode: TagsSelectionMode.single,
    enableEditing: false,
  ),
);

if (tag != null && tag.isNotEmpty) {
  _task.tag = tag.first;
}
```

### 场景3：嵌入式标签管理页面

```dart
class TagsManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TagsDialog(
      displayMode: TagsDisplayMode.embedded,
      jsonFilePath: 'app_data/tags.json',
      config: TagsDialogConfig(
        title: '标签管理',
        largeTitle: '所有标签',
        enableEditing: true,
        enableBatchEdit: true,
        enableLongPressMenu: true,
        selectionMode: TagsSelectionMode.none,
      ),
    );
  }
}
```

---

**维护者**: Memento 开发团队
**最后更新**: 2025-01-07
