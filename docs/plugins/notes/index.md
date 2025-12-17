# Notes - 无限层级笔记插件

![Notes Plugin](/icon.png)

📝 **Notes 无限层级笔记** - 构建您的个人知识库

## 插件概述

Notes 插件是 Memento 的核心功能模块之一，提供完整的笔记管理解决方案。

### 核心特性

- 🌳 **无限层级文件夹**：支持任意深度的文件夹树形结构
- ✍️ **Markdown 笔记编辑**：支持富文本格式的笔记内容
- 🏷️ **标签系统**：为笔记添加多个标签以便分类
- 🔍 **全文搜索**：支持标题、内容、标签、日期范围的复合搜索
- 📁 **笔记移动**：在文件夹之间自由移动笔记
- 🤖 **AI 数据分析**：注册到 OpenAI 插件，支持笔记数据提取
- 📡 **事件系统**：广播笔记的创建、更新、删除事件

## 使用场景

### 学习笔记
- **课程笔记**：按学科、章节组织学习内容
- **读书笔记**：记录读书心得和重点摘要
- **论文研究**：管理学术论文和研究资料
- **知识体系**：构建完整的学科知识框架

### 工作文档
- **项目文档**：管理项目文档和资料
- **会议记录**：记录会议内容和待办事项
- **标准流程**：建立标准操作流程文档
- **团队协作**：团队共享知识和经验

### 个人知识库
- **灵感收集**：随时记录突发灵感
- **经验总结**：总结工作和生活经验
- **攻略指南**：制作各种实用攻略
- **收藏整理**：整理网络优质内容

### 创作管理
- **文章草稿**：管理文章和创作草稿
- **素材库**：收集写作素材和参考资料
- **创作大纲**：规划长篇创作结构
- **灵感簿**：记录创作灵感

## 操作指南

### 创建笔记
1. 点击「+」按钮创建新笔记
2. 输入笔记标题和内容（支持 Markdown）
3. 选择所属文件夹
4. 添加标签（可选）
5. 保存笔记

### 管理层级
1. 点击文件夹进入下级目录
2. 长按笔记显示操作菜单
3. 选择编辑/移动/删除操作
4. 使用返回按钮导航上级目录

### 搜索笔记
1. 点击搜索按钮
2. 输入关键词搜索
3. 可选择标签和日期范围进行筛选
4. 查看搜索结果列表

## API 文档

### 核心控制器方法

#### 文件夹管理

```dart
// 获取文件夹
Folder? getFolder(String id)

// 获取所有文件夹
List<Folder> getAllFolders()

// 获取指定文件夹的子文件夹
List<Folder> getFolderChildren(String parentId)

// 创建新文件夹
Future<Folder> createFolder(String name, String? parentId)

// 重命名文件夹
Future<void> renameFolder(String folderId, String newName)

// 删除文件夹(递归删除子文件夹和笔记)
Future<void> deleteFolder(String folderId)
```

#### 笔记管理

```dart
// 获取文件夹中的笔记
List<Note> getFolderNotes(String folderId)

// 创建新笔记
Future<Note> createNote(String title, String content, String folderId)

// 更新笔记
Future<void> updateNote(Note note)

// 删除笔记
Future<void> deleteNote(String noteId)
Future<void> deleteNoteObject(Note note)

// 移动笔记到其他文件夹
Future<void> moveNote(String noteId, String targetFolderId)
```

#### 搜索功能

```dart
// 搜索笔记(支持标题/内容/标签/日期范围)
List<Note> searchNotes({
  required String query,
  List<String>? tags,
  DateTime? startDate,
  DateTime? endDate,
})
```

#### 统计接口

```dart
// 获取总笔记数
int getTotalNotesCount()

// 获取最近7天的笔记数
int getRecentNotesCount()
```

### AI 集成接口

#### 数据提取方法

```dart
// 获取指定文件夹或笔记ID的笔记数据(供 OpenAI 插件调用)
Future<String> getNotes(Map<String, dynamic> params)
// params: {
//   "folder_ids": ["folder1", "folder2"],  // 可选
//   "note_ids": ["note1", "note2"]         // 可选
// }
// 返回: JSON 字符串,包含笔记列表
// 示例: {"notes": [{"id": "...", "title": "...", "content": "...", "folder_name": "..."}]}
```

**调用示例**：

在 OpenAI 插件的 Prompt 中使用：
```
分析我在"工作笔记"文件夹中的笔记内容:
{{notes_getNotes(folder_ids: ["1234567890"])}}
```

或指定笔记ID：
```
总结这些笔记的要点:
{{notes_getNotes(note_ids: ["123", "456", "789"])}}
```

## 数据模型

### Folder (文件夹)

```dart
class Folder {
  String id;               // 唯一标识符(时间戳字符串)
  String name;             // 文件夹名称
  String? parentId;        // 父文件夹ID(null 表示根文件夹)
  DateTime createdAt;      // 创建时间
  DateTime updatedAt;      // 更新时间
  Color color;             // 文件夹颜色(默认蓝色)
  IconData icon;           // 文件夹图标(默认 folder 图标)
}
```

**层级结构实现**：
- 使用 `parentId` 字段建立父子关系
- `parentId = null` 表示根文件夹
- 通过 `getFolderChildren(parentId)` 获取子文件夹
- 支持无限层级嵌套

### Note (笔记)

```dart
class Note {
  String id;               // 唯一标识符(时间戳字符串)
  String title;            // 笔记标题
  String content;          // 笔记内容(Markdown 格式)
  String folderId;         // 所属文件夹ID
  DateTime createdAt;      // 创建时间
  DateTime updatedAt;      // 更新时间
  List<String> tags;       // 标签列表
}
```

## 数据存储

### 存储路径

**根目录**: `notes/`

### 存储结构

```
notes/
├── folders.json              # 所有文件夹数据
└── notes.json                # 所有笔记数据
```

### 数据格式

**folders.json**:
```json
[
  {
    "id": "root",
    "name": "Root",
    "parentId": null,
    "createdAt": "2025-01-15T10:30:00.000Z",
    "updatedAt": "2025-01-15T10:30:00.000Z",
    "color": 4280391411,
    "icon": 57415
  }
]
```

**notes.json**:
```json
[
  {
    "id": "1234567890123",
    "title": "项目计划",
    "content": "# 项目计划\n\n本周目标:\n- 完成设计稿\n- 开发核心功能",
    "folderId": "1234567890",
    "createdAt": "2025-01-15T08:30:00.000Z",
    "updatedAt": "2025-01-15T20:15:00.000Z",
    "tags": ["工作", "计划"]
  }
]
```

## 事件系统

### 事件类型

| 事件名 | 事件类 | 触发时机 | 参数 |
|-------|--------|---------|------|
| `note_added` | `ItemEventArgs` | 创建笔记时 | `itemId`, `title`, `action` |
| `note_deleted` | `ItemEventArgs` | 删除笔记时 | `itemId`, `title`, `action` |

### 事件广播示例

```dart
// 创建笔记时
await _saveNotes();
_notifyEvent('added', note);

// 删除笔记时
notes.removeAt(noteIndex);
_notifyEvent('deleted', note);
await _saveNotes();
```

## 卡片视图

插件在主页提供卡片视图，展示:

**布局**:
```
┌─────────────────────────────┐
│ 📝 笔记                    │
├─────────────────────────────┤
│  总笔记数    │   最近笔记   │
│     128     │      15      │
│             │   (7天内)    │
└─────────────────────────────┘
```

## 目录结构

```
notes/
├── notes_plugin.dart                    # 插件主类
├── notes_plugin_entry.dart              # 插件入口点
├── models/
│   ├── folder.dart                      # 文件夹模型
│   └── note.dart                        # 笔记模型
├── controllers/
│   └── notes_controller.dart            # 核心控制器(CRUD + 搜索)
├── services/
│   └── prompt_replacements.dart         # AI Prompt 替换方法
├── controls/
│   └── prompt_controller.dart           # Prompt 控制器(注册到 OpenAI)
├── screens/
│   ├── notes_screen.dart                # 主界面
│   ├── note_edit_screen.dart            # 编辑界面
│   ├── search_screen.dart               # 搜索界面
│   ├── folder_list_screen.dart          # 文件夹列表界面
│   ├── notes_screen/                    # 主界面模块化组件
│   │   ├── notes_screen_state.dart      # 状态基类
│   │   ├── folder_operations.dart       # 文件夹操作 Mixin
│   │   ├── note_operations.dart         # 笔记操作 Mixin
│   │   ├── folder_item.dart             # 文件夹项 Mixin
│   │   ├── note_item.dart               # 笔记项 Mixin
│   │   └── folder_selection_dialog.dart # 文件夹选择对话框 Mixin
│   └── note_screen/                     # 笔记界面组件(备用)
│       ├── index.dart
│       ├── notes_screen.dart
│       ├── notes_list_view.dart
│       ├── notes_app_bar.dart
│       ├── folder_list_tile.dart
│       ├── note_list_tile.dart
│       ├── folder_selection_dialog.dart
│       ├── folder_operations.dart
│       └── note_operations.dart
├── widgets/
│   ├── folder_item.dart                 # 文件夹列表项组件
│   ├── note_item.dart                   # 笔记列表项组件
│   ├── search_note_item.dart            # 搜索结果项组件
│   └── tag_input.dart                   # 标签输入组件
├── utils/
│   └── text_highlight.dart              # 文本高亮工具
└── l10n/
    ├── notes_localizations.dart         # 国际化接口
    ├── notes_localizations_zh.dart      # 中文翻译
    └── notes_localizations_en.dart      # 英文翻译
```

## 国际化

### 支持语言

- 简体中文 (zh)
- 英语 (en)

### 本地化文件

| 文件 | 语言 |
|------|------|
| `l10n/notes_localizations.dart` | 本地化接口 |
| `l10n/notes_localizations_zh.dart` | 中文翻译 |
| `l10n/notes_localizations_en.dart` | 英文翻译 |

### 关键字符串

```dart
abstract class NotesLocalizations {
  String get name;                  // 插件名称
  String get totalNotes;            // 总笔记数
  String get recentNotes;           // 最近笔记
  String get newNote;               // 新建笔记
  String get newFolder;             // 新建文件夹
  String get editNote;              // 编辑
  String get moveNote;              // 移动到
  String get deleteNote;            // 删除
  String get deleteNoteConfirm;     // 删除确认
  String get renameFolder;          // 重命名文件夹
  String get deleteFolder;          // 删除文件夹
  String get deleteFolderConfirm;   // 删除文件夹确认
  String get search;                // 搜索
  String get emptyFolder;           // 空文件夹提示
  String get folders;               // 文件夹
  String get notes;                 // 笔记
  String get tags;                  // 标签
  String get dateRange;             // 日期范围
}
```

## 关键实现细节

### 1. 无限层级文件夹实现

**核心数据结构**:
```dart
class Folder {
  String id;
  String? parentId;  // 指向父文件夹
}

// 内存存储: Map<String, Folder>
Map<String, Folder> _folders = {};
```

**树形遍历**:
```dart
// 获取子文件夹
List<Folder> getFolderChildren(String parentId) {
  return _folders.values
      .where((folder) => folder.parentId == parentId)
      .toList();
}

// 递归删除
Future<void> deleteFolder(String folderId) async {
  final children = getFolderChildren(folderId);
  for (var child in children) {
    await deleteFolder(child.id);  // 深度优先删除
  }
  _folders.remove(folderId);
  _notes.remove(folderId);
}
```

**导航历史**:
```dart
// 在 NotesMainViewState 中
List<String> _folderHistory = ['root'];

void navigateToFolder(Folder folder) {
  _folderHistory.add(folder.id);
  loadCurrentFolder();
}

void navigateBack() {
  if (_folderHistory.length > 1) {
    _folderHistory.removeLast();
    loadCurrentFolder();
  }
}
```

### 2. 数据持久化机制

**单文件存储**:
- `folders.json`: 所有文件夹数据的 JSON 数组
- `notes.json`: 所有笔记数据的 JSON 数组

**优点**:
- 简单易维护
- 一次读取所有数据,内存操作快速
- 适合中小规模数据(<1000条)

**缺点**:
- 每次保存需要序列化全部数据
- 大数据量下性能下降

### 3. Mixin 架构设计

将界面逻辑拆分为多个 Mixin,组合使用:

```dart
// 基类 - 提供状态字段
abstract class NotesMainViewState extends State<NotesMainView> {
  late NotesController controller;
  Folder? currentFolder;
  List<Folder> subFolders = [];
  List<Note> notes = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
}

// Mixin - 文件夹操作
mixin FolderOperations on NotesMainViewState {
  Future<void> createNewFolder() async { /* ... */ }
  Future<void> renameFolder(Folder folder) async { /* ... */ }
  Future<void> deleteFolder(Folder folder) async { /* ... */ }
}

// Mixin - 笔记操作
mixin NoteOperations on NotesMainViewState {
  void createNewNote() { /* ... */ }
  void editNote(Note note) { /* ... */ }
  Future<void> moveNote(Note note) async { /* ... */ }
  Future<void> deleteNote(Note note) async { /* ... */ }
}

// 最终组合
class _NotesMainViewState extends NotesMainViewState
    with FolderOperations, NoteOperations, FolderItem, NoteItem {
  // 拥有所有 Mixin 的方法
}
```

**优点**:
- 职责分离,代码清晰
- 易于单独测试每个 Mixin
- 避免单文件过长(>1000行)

### 4. 搜索复合条件实现

```dart
List<Note> searchNotes({
  required String query,
  List<String>? tags,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final allNotes = _notes.values.expand((notes) => notes).toList();
  return allNotes.where((note) {
    // 条件1: 标题或内容匹配
    if (!note.title.toLowerCase().contains(query.toLowerCase()) &&
        !note.content.toLowerCase().contains(query.toLowerCase())) {
      return false;
    }

    // 条件2: 标签匹配(任一标签匹配即可)
    if (tags != null && tags.isNotEmpty) {
      if (!tags.any((tag) => note.tags.contains(tag))) {
        return false;
      }
    }

    // 条件3: 日期范围匹配
    if (startDate != null && note.createdAt.isBefore(startDate)) {
      return false;
    }
    if (endDate != null) {
      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23, 59, 59,
      );
      if (note.createdAt.isAfter(endOfDay)) {
        return false;
      }
    }

    return true;
  }).toList();
}
```

## 依赖关系

### 核心依赖

- **BasePlugin**: 插件基类
- **StorageManager**: 数据持久化
- **EventManager**: 事件广播系统
- **PluginManager**: 插件管理器

### 第三方包依赖

无外部第三方包依赖(仅使用 Flutter SDK)

### 其他插件依赖

- **OpenAI Plugin**: 可选依赖,用于 AI 数据分析

**依赖方向**: `notes` → `openai`(通过 `PluginManager` 获取)

## 常见问题

**Q: 如何实现无限层级文件夹?**
A: 使用 `parentId` 字段建立树形结构,`parentId = null` 表示根文件夹,通过 `getFolderChildren(parentId)` 获取子文件夹,支持无限层级嵌套。

**Q: 如何添加新的搜索条件?**
A: 在 `searchNotes()` 方法中添加过滤逻辑,可以添加文件夹过滤、标签过滤等条件。

**Q: 如何在 AI 分析中使用笔记数据?**
A: 在 OpenAI 插件的系统提示词或用户消息中使用 `` {{`notes_getNotes(folder_ids: ["1234567890"])`}} `` 格式调用。

**Q: 笔记内容支持哪些格式?**
A: 当前支持 Markdown 格式,存储在 `content` 字段。

**Q: 文件夹和笔记的ID是如何生成的?**
A: 使用时间戳作为唯一标识符,简单、递增、无需额外依赖。

---

## 小贴士

💡 **快捷键使用**：熟练使用快捷键提高编辑效率

💡 **大纲视图**：使用大纲视图快速浏览结构

💡 **全屏编辑**：全屏模式下专注写作

💡 **自动保存**：开启自动保存避免数据丢失

💡 **多端同步**：开启云同步多设备访问

💡 **层级命名规范**：建立统一的文件夹命名规范

💡 **定期整理**：定期整理笔记，删除无用内容

💡 **交叉链接**：使用链接在相关笔记间跳转

💡 **模板复用**：创建常用模板提高效率

---

*让知识有序生长，让思考触手可及*
