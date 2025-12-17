[根目录](../../../CLAUDE.md) > [lib](../../) > [plugins](../) > **database**

---

# 数据库插件 (Database Plugin) - 模块文档

## 模块职责

数据库插件是 Memento 的核心功能模块之一，提供灵活的自定义数据库功能：

- **自定义数据库结构**：用户可创建无限个数据库，每个数据库支持自定义名称、描述、封面图片
- **灵活的字段系统**：支持 11 种字段类型（文本、长文本、整数、复选框、下拉选择、日期、时间、日期时间、图片、URL、评分、密码）
- **记录管理**：完整的 CRUD 操作，支持创建、编辑、删除、查看数据库记录
- **双视图模式**：列表视图和网格视图两种展示方式，支持实时切换
- **字段可视化编辑**：支持字段拖拽排序、动态添加/编辑字段
- **数据持久化**：基于 JSON 的本地存储机制，数据安全可靠
- **数据库复制**：支持一键复制现有数据库结构（不含记录）
- **JS API 支持**：提供 15+ 个 JS API 方法，支持与 WebView 插件和其他模块交互
- **UseCase 架构**：采用 UseCase + Repository 架构模式，业务逻辑清晰，易于测试和扩展
- **主页小组件**：支持 1x1 快速访问和 2x2 统计信息小组件
- **国际化支持**：内置中英双语，支持动态切换
- **数据选择器**：支持数据库表和记录的跨模块选择

---

## 入口与启动

### 插件主类

**文件**: `database_plugin.dart`

```dart
class DatabasePlugin extends BasePlugin with JSBridgePlugin {
  @override
  String get id => 'database';

  @override
  Color get color => Colors.deepPurple;

  @override
  IconData get icon => Icons.storage;

  late final DatabaseService service = DatabaseService(this);
  late final DatabaseController controller = DatabaseController(service);
  late final ClientDatabaseRepository repository;
  late final DatabaseUseCase useCase;

  @override
  Future<void> initialize() async {
    // 1. 初始化默认数据
    await service.initializeDefaultData();

    // 2. 初始化 UseCase 架构
    repository = ClientDatabaseRepository(
      service: service,
      controller: controller,
    );
    useCase = DatabaseUseCase(repository);

    // 3. 注册数据选择器
    _registerDataSelectors();

    // 4. 注册 JS API（最后一步）
    await registerJSAPI();
  }
}
```

### 主界面入口

**文件**: `database_plugin.dart`

**路由**: 通过 `DatabasePlugin.buildMainView()` 返回 `DatabaseMainView`

**启动流程**:
1. `DatabasePlugin.initialize()` - 初始化默认数据库和 UseCase 架构
2. `DatabaseService.initializeDefaultData()` - 创建 'default_db' 默认数据库
3. `DatabaseMainView` → `DatabaseListWidget` - 显示数据库列表

### 主页小组件注册

**文件**: `home_widgets.dart`

通过 `DatabaseHomeWidgets.register()` 注册两种小组件：
- **1x1 快速访问**：显示数据库图标和名称
- **2x2 统计卡片**：显示数据库总数统计

---

## 对外接口

### JS API 接口

数据库插件提供 15+ 个 JS API 方法，支持与 WebView 和其他插件交互：

#### 数据库管理 API

```javascript
// 获取所有数据库（支持分页）
await invoke('database.getDatabases', { offset: 0, count: 10 });

// 创建数据库
await invoke('database.createDatabase', {
  name: '项目库',
  description: '项目管理数据库',
  fields: [
    { name: '项目名称', type: 'Text' },
    { name: '截止日期', type: 'Date' }
  ]
});

// 更新数据库
await invoke('database.updateDatabase', {
  id: 'db_id',
  name: '新名称',
  fields: [...]
});

// 删除数据库
await invoke('database.deleteDatabase', { id: 'db_id' });
```

#### 记录管理 API

```javascript
// 获取记录列表（支持分页）
await invoke('database.getRecords', {
  databaseId: 'db_id',
  offset: 0,
  count: 20
});

// 创建记录
await invoke('database.createRecord', {
  databaseId: 'db_id',
  fields: {
    '项目名称': 'Memento 开发',
    '进度': 80
  }
});

// 更新记录
await invoke('database.updateRecord', {
  id: 'record_id',
  fields: { '进度': 90 }
});

// 删除记录
await invoke('database.deleteRecord', { id: 'record_id' });
```

#### 查询和搜索 API

```javascript
// 搜索记录
await invoke('database.query', {
  databaseId: 'db_id',
  keyword: '关键词',
  offset: 0,
  count: 20
});

// 统计数量
await invoke('database.getCount', {
  type: 'databases' // 或 'records' + databaseId
});
```

#### 便捷查找 API

```javascript
// 查找数据库（支持多种查找方式）
await invoke('database.findDatabaseById', { id: 'db_id' });
await invoke('database.findDatabaseByName', { name: '项目库', fuzzy: true });
await invoke('database.findDatabaseBy', { field: 'name', value: '项目' });

// 查找记录
await invoke('database.findRecordById', { id: 'record_id' });
await invoke('database.findRecordBy', {
  databaseId: 'db_id',
  field: '项目名称',
  value: 'Memento'
});
```

### 数据选择器接口

插件注册了两个数据选择器，支持其他模块选择数据库和记录：

1. **数据库表选择器** (`database.table`)
   - 选择数据库表
   - 返回 DatabaseModel 对象

2. **记录选择器** (`database.record`)
   - 两级选择：先选择数据库，再选择记录
   - 返回 Record 对象
   - 智能显示记录标题（优先使用 title/name 字段）

---

## 关键依赖与配置

### 架构依赖

- **shared_models**: 提供了统一的 DTO 模型和 UseCase 基类
  - `DatabaseModelDto` - 数据库传输对象
  - `DatabaseRecordDto` - 记录传输对象
  - `DatabaseUseCase` - 业务逻辑基类
  - `IDatabaseRepository` - 数据访问接口

### 外部依赖

- `flutter/material.dart`: UI 组件库
- `uuid: ^4.x.x`: UUID 生成（用于数据库复制）
- `image_picker: ^1.x.x`: 图片选择器（字段类型：Image）
- `get/get.dart`: 状态管理和国际化
- `Memento/widgets/image_picker_dialog.dart`: 自定义图片选择对话框
- `Memento/utils/image_utils.dart`: 图片工具类

### 插件依赖

- **Core Storage Manager**: 数据持久化
- **Core Plugin Manager**: 插件管理与导航
- **JS Bridge**: WebView 通信支持
- **Plugin Data Selector**: 跨模块数据选择
- **Home Widget System**: 主页小组件支持

### 存储路径

**存储键名**:
- `databases/databases` - 所有数据库元数据
- `records_{databaseId}` - 各数据库的记录数据

**存储结构**:
```
storage/
├── databases/
│   └── databases.json              # 所有数据库的元数据
└── records_<databaseId>.json       # 每个数据库的记录数据
```

---

## 数据模型

### DatabaseModel (数据库)

**文件**: `models/database_model.dart`

```dart
@immutable
class DatabaseModel {
  final String id;                        // 唯一标识符
  final String name;                      // 数据库名称
  final String? description;              // 数据库描述(可选)
  final String? coverImage;               // 封面图片路径(可选)
  final List<DatabaseField> fields;       // 字段定义列表
  final DateTime createdAt;               // 创建时间
  final DateTime updatedAt;               // 更新时间

  Map<String, dynamic> toMap();
  factory DatabaseModel.fromMap(Map<String, dynamic> map);
  DatabaseModel copyWith({...});
}
```

**示例数据**:
```json
{
  "id": "1234567890",
  "name": "项目管理",
  "description": "用于跟踪项目进度",
  "coverImage": "images/project_cover.jpg",
  "fields": [
    {"id": "f1", "name": "项目名称", "type": "Text", "isRequired": true},
    {"id": "f2", "name": "截止日期", "type": "Date", "isRequired": false},
    {"id": "f3", "name": "优先级", "type": "Rating", "isRequired": false}
  ],
  "createdAt": "2025-01-15T10:30:00.000Z",
  "updatedAt": "2025-01-16T14:20:00.000Z"
}
```

### DatabaseField (数据库字段)

**文件**: `models/database_field.dart`

```dart
@immutable
class DatabaseField {
  final String id;               // 字段唯一标识符
  final String name;             // 字段名称
  final String type;             // 字段类型
  final bool isRequired;         // 是否必填

  Map<String, dynamic> toMap();
  factory DatabaseField.fromMap(Map<String, dynamic> map);
  DatabaseField copyWith({...});
}
```

**支持的字段类型**:

| 类型 | 描述 | 图标 | 输入组件 |
|------|------|------|---------|
| `Text` | 单行文本 | `Icons.text_fields` | `TextField` |
| `Long Text` | 多行文本 | `Icons.notes` | `TextField(maxLines: 3)` |
| `Integer` | 整数 | `Icons.numbers` | `TextField(keyboardType: number)` |
| `Checkbox` | 复选框 | `Icons.check_box` | `CheckboxListTile` |
| `Dropdown` | 下拉选择 | `Icons.arrow_drop_down` | `DropdownButton` |
| `Date` | 日期 | `Icons.calendar_today` | `DatePicker` |
| `Time` | 时间 | `Icons.access_time` | `TimePicker` |
| `Date/Time` | 日期时间 | `Icons.date_range` | `DateTimePicker` |
| `Image` | 图片 | `Icons.image` | `ImagePicker` |
| `URL` | 网址 | `Icons.link` | `TextField` |
| `Rating` | 评分 | `Icons.star` | `Rating Widget` |
| `Password` | 密码 | `Icons.lock` | `TextField(obscureText: true)` |

### Record (记录)

**文件**: `models/record.dart`

```dart
class Record {
  final String id;                        // 记录唯一标识符
  final String tableId;                   // 所属数据库ID
  final Map<String, dynamic> fields;      // 字段数据(键=字段名,值=字段值)
  final DateTime createdAt;               // 创建时间
  final DateTime updatedAt;               // 更新时间

  Map<String, dynamic> toMap();
  factory Record.fromMap(Map<String, dynamic> map);
  Record copyWith({...});
}
```

**示例数据**:
```json
{
  "id": "1234567890123",
  "tableId": "1234567890",
  "fields": {
    "项目名称": "Memento 应用开发",
    "截止日期": "2025-03-01T00:00:00.000Z",
    "优先级": 5,
    "负责人": "张三",
    "完成状态": true
  },
  "createdAt": "2025-01-15T08:30:00.000Z",
  "updatedAt": "2025-01-16T10:15:00.000Z"
}
```

### FieldModel (字段模型)

**文件**: `models/field_model.dart`

```dart
class FieldModel {
  String id;               // 字段ID
  String name;             // 字段名称
  String type;             // 字段类型
  String? description;     // 字段描述(用于存储默认值等)

  FieldModel copyWith({...});
}
```

**注**: `FieldModel` 是 `DatabaseField` 的扩展版本，在编辑界面使用，支持额外的 `description` 字段。

---

## 业务逻辑层

### DatabaseService (数据服务)

**文件**: `services/database_service.dart`

核心功能：
- 管理数据库元数据的 CRUD 操作
- 初始化默认数据库
- 提供统计接口（数据库总数、今日记录数、总记录数）

### DatabaseController (控制器)

**文件**: `controllers/database_controller.dart`

核心功能：
- 管理当前加载的数据库
- 处理记录的 CRUD 操作
- 维护数据库与记录的关系

### FieldController (字段控制器)

**文件**: `controllers/field_controller.dart`

核心功能：
- 定义所有支持的字段类型
- 根据字段类型动态生成输入组件
- 提供字段类型选择界面

### ClientDatabaseRepository (数据仓库)

**文件**: `repositories/client_database_repository.dart`

核心功能：
- 实现 `IDatabaseRepository` 接口
- 适配现有的 `DatabaseService` 和 `DatabaseController`
- 处理 DTO 与 Model 之间的转换
- 支持 UseCase 架构模式

---

## 界面层结构

### 主要界面组件

| 组件 | 文件 | 职责 |
|------|------|------|
| `DatabaseMainView` | `database_plugin.dart` | 插件主视图容器 |
| `DatabaseListWidget` | `widgets/database_list_widget.dart` | 数据库列表(网格视图) |
| `DatabaseDetailWidget` | `widgets/database_detail_widget.dart` | 数据库详情与记录列表 |
| `DatabaseEditWidget` | `widgets/database_edit_widget.dart` | 数据库编辑界面(双Tab) |
| `RecordEditWidget` | `widgets/record_edit_widget.dart` | 记录编辑界面 |
| `RecordDetailWidget` | `widgets/record_detail_widget.dart` | 记录详情界面 |

### DatabaseListWidget 布局

**布局结构**:
```
Scaffold
├── AppBar
│   ├── leading: 返回主页按钮
│   └── title: "数据库列表"
├── body: GridView
│   └── GridView.builder (2列网格)
│       └── Card - 数据库卡片
│           ├── 封面图片或默认图标
│           ├── 数据库名称
│           ├── onTap: 进入数据库详情
│           └── onLongPress: 显示操作菜单(编辑/复制/删除)
└── FloatingActionButton: 创建新数据库
```

**关键特性**:
- 网格布局(2列)
- 支持封面图片显示(网络/本地)
- 下拉刷新
- 长按显示操作菜单
- 空状态提示
- 错误处理与重试

### DatabaseDetailWidget 布局

**布局结构**:
```
Scaffold
├── AppBar
│   ├── title: 数据库名称
│   └── actions: [视图切换按钮(列表/网格), 编辑按钮]
├── body: 动态视图
│   ├── ListView (列表模式)
│   │   └── Dismissible - 记录列表项
│   │       ├── 左滑删除
│   │       ├── onTap: 查看记录详情
│   │       └── onLongPress: 显示操作菜单
│   └── GridView (网格模式)
│       └── Card - 记录卡片
└── FloatingActionButton: 创建新记录
```

**关键特性**:
- 列表/网格双视图模式切换
- 支持滑动删除记录
- 记录标题显示(取 `fields['title']` 或显示"未命名")
- 实时刷新数据

### DatabaseEditWidget 布局

**布局结构**:
```
Scaffold
├── AppBar
│   ├── title: "编辑数据库"
│   ├── bottom: TabBar
│   │   ├── Tab: "基本信息"
│   │   └── Tab: "字段"
│   └── actions: [保存按钮]
└── body: TabBarView
    ├── 基本信息 Tab
    │   ├── TextFormField: 数据库名称
    │   ├── Button: 上传封面图片
    │   └── TextFormField: 描述(多行)
    └── 字段 Tab
        ├── ReorderableListView: 字段列表(支持拖拽排序)
        │   └── ListTile: 字段名称、类型
        └── FloatingActionButton: 添加新字段
```

**关键特性**:
- 双Tab布局(基本信息/字段)
- 字段拖拽排序
- 图片裁剪功能(纵横比 1:1)
- 字段类型选择对话框
- 字段编辑对话框(支持默认值设置)

### RecordEditWidget 布局

**布局结构**:
```
Scaffold
├── AppBar
│   ├── title: "编辑记录"
│   └── actions: [保存按钮]
└── body: Form
    └── ListView
        └── 动态生成字段组件
            ├── Text → TextFormField
            ├── Integer → TextFormField(number)
            ├── Checkbox → CheckboxListTile
            ├── Date → DatePicker
            ├── Image → ImagePicker + Image.file
            └── ...
```

**关键特性**:
- 根据数据库字段定义动态生成表单
- 不同字段类型使用不同输入组件
- 自动初始化字段默认值
- 表单验证

---

## 测试与质量

### 当前状态
- **单元测试**: 无
- **集成测试**: 无
- **代码分析**: 通过 Flutter analyze，仅 1 个文档注释警告
- **架构迁移**: 2025-12-12 完成到 UseCase 架构的迁移

### 测试建议

1. **高优先级**:
   - `DatabaseService.createDatabase()` - 测试数据库创建和存储
   - `DatabaseService.deleteDatabase()` - 测试删除逻辑
   - `DatabaseController.getRecords()` - 测试记录读取
   - `FieldController.buildFieldWidget()` - 测试所有 11 种字段类型组件
   - `ClientDatabaseRepository` - 测试 DTO 转换和适配逻辑

2. **中优先级**:
   - `DatabaseUseCase` - 测试所有业务方法（15个）
   - JS API 测试 - 验证所有 15+ 个 API 方法
   - 字段拖拽排序 - 测试排序逻辑
   - 图片上传与裁剪 - 测试图片处理流程
   - 数据选择器 - 测试跨模块选择功能

3. **低优先级**:
   - UI 交互逻辑
   - 国际化字符串完整性
   - 空状态显示
   - 错误处理与重试

---

## 国际化

### 支持语言

- 简体中文 (zh)
- 英语 (en)

### 本地化文件

| 文件 | 语言 |
|------|------|
| `l10n/database_translations.dart` | 本地化接口 |
| `l10n/database_translations_zh.dart` | 中文翻译 |
| `l10n/database_translations_en.dart` | 英文翻译 |

### 关键字符串

```dart
// 插件基本信息
'database_name': '数据库',
'database_plugin_description': '用于管理数据库的插件',

// 数据库操作
'database_database_list_title': '数据库列表',
'database_edit_database_title': '编辑数据库',
'database_new_database_default_name': '新建数据库',
'database_database_name_label': '数据库名称',

// 字段操作
'database_fields_tab_title': '字段',
'database_field_name_label': '字段名称',
'database_select_field_type_title': '选择字段类型',

// 记录操作
'database_untitled_record': '未命名',
'database_delete_record_title': '删除记录',

// 统计信息
'database_total_databases_count': '总数据库数',
```

---

## 常见问题 (FAQ)

### Q1: 如何添加新的字段类型?

在 `FieldController` 中添加新字段类型:

```dart
// 1. 在 fieldTypes Map 中添加类型定义
static const Map<String, IconData> fieldTypes = {
  'Text': Icons.text_fields,
  // ... 现有类型
  'Color': Icons.color_lens,  // 新增颜色字段
};

// 2. 在 buildFieldWidget() 中添加对应的组件
case 'Color':
  return ListTile(
    title: Text(field.name),
    trailing: Container(
      width: 40,
      height: 40,
      color: Color(initialValue ?? 0xFF000000),
    ),
    onTap: () async {
      final color = await showDialog<Color>(
        context: context,
        builder: (context) => ColorPickerDialog(),
      );
      if (color != null) onChanged(color.value);
    },
  );
```

### Q2: 数据库的ID是如何生成的?

使用时间戳作为唯一标识符:

```dart
// 创建数据库时
_editedDatabase = _editedDatabase.copyWith(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
);

// 复制数据库时使用 UUID
final newDatabase = database.copyWith(id: Uuid().v4());
```

**优点**: 简单、递增、无需额外依赖(时间戳)/全局唯一(UUID)
**缺点**: 高并发下时间戳可能重复(当前场景下无问题)

### Q3: 如何通过 JS API 操作数据库?

```javascript
// 创建数据库
const dbResult = await invoke('database.createDatabase', {
  name: '我的数据库',
  description: '描述信息',
  fields: [
    { name: '标题', type: 'Text', isRequired: true },
    { name: '日期', type: 'Date' }
  ]
});

// 添加记录
const recordResult = await invoke('database.createRecord', {
  databaseId: dbResult.id,
  fields: {
    '标题': '第一条记录',
    '日期': new Date().toISOString()
  }
});

// 查询记录
const records = await invoke('database.query', {
  databaseId: dbResult.id,
  keyword: '关键词'
});
```

### Q4: 如何实现数据导入导出功能?

建议添加导入导出方法:

```dart
// 导出数据库(包含结构和记录)
Future<String> exportDatabase(String databaseId) async {
  final database = await getAllDatabases()
      .then((dbs) => dbs.firstWhere((db) => db.id == databaseId));
  final records = await controller.getRecords(databaseId);

  final exportData = {
    'database': database.toMap(),
    'records': records.map((r) => r.toMap()).toList(),
  };

  return jsonEncode(exportData);
}

// 导入数据库
Future<void> importDatabase(String jsonData) async {
  final data = jsonDecode(jsonData);
  final database = DatabaseModel.fromMap(data['database']);
  final records = (data['records'] as List)
      .map((r) => Record.fromMap(r))
      .toList();

  // 生成新ID避免冲突
  final newDatabase = database.copyWith(
    id: Uuid().v4(),
  );

  await createDatabase(newDatabase);
  for (var record in records) {
    await controller.createRecord(
      record.copyWith(
        id: Uuid().v4(),
        tableId: newDatabase.id,
      ),
    );
  }
}
```

### Q5: 如何实现记录搜索功能?

使用 UseCase 的搜索方法:

```dart
// 在 Controller 中
Future<List<Record>> searchRecords({
  required String databaseId,
  required String query,
}) async {
  final result = await useCase.searchRecords(DatabaseRecordQuery(
    tableId: databaseId,
    fieldKeyword: query,
  ));

  if (result.isSuccess) {
    return result.data!.map(_dtoToRecord).toList();
  }
  return [];
}
```

### Q6: UseCase 架构的优势是什么?

迁移后的架构优势：

1. **业务逻辑集中**: 所有业务规则在 UseCase 层
2. **数据访问抽象**: 通过 Repository 接口隔离数据层
3. **易于测试**: UseCase 和 Repository 可独立测试
4. **代码复用**: UseCase 可被多个入口复用
5. **错误处理**: 统一的 Result 模式错误处理
6. **分页支持**: 内置分页逻辑，减少重复代码

---

## 目录结构

```
database/
├── database_plugin.dart                # 插件主类（635行）
├── home_widgets.dart                   # 主页小组件注册
├── MIGRATION_REPORT.md                # UseCase 架构迁移报告
├── models/
│   ├── database_model.dart             # 数据库模型（72行）
│   ├── database_field.dart             # 数据库字段模型（58行）
│   ├── field_model.dart                # 字段模型（编辑用）
│   └── record.dart                     # 记录模型（52行）
├── services/
│   └── database_service.dart           # 数据库服务（134行）
├── controllers/
│   ├── database_controller.dart        # 数据库控制器（74行）
│   └── field_controller.dart           # 字段控制器（119行）
├── repositories/
│   └── client_database_repository.dart # 客户端仓库实现（342行）
├── widgets/
│   ├── database_list_widget.dart       # 数据库列表组件
│   ├── database_detail_widget.dart     # 数据库详情组件
│   ├── database_edit_widget.dart       # 数据库编辑组件
│   ├── record_edit_widget.dart         # 记录编辑组件
│   └── record_detail_widget.dart       # 记录详情组件
└── l10n/
    ├── database_translations.dart     # 国际化接口
    ├── database_translations_zh.dart  # 中文翻译
    └── database_translations_en.dart  # 英文翻译
```

---

## 关键实现细节

### 1. UseCase 架构模式

插件已迁移到 UseCase 架构，实现了业务逻辑与数据访问的分离：

```dart
// 架构层次
DatabasePlugin (JS API 适配层)
    ↓
DatabaseUseCase (业务逻辑层)
    ↓
ClientDatabaseRepository (数据访问适配层)
    ↓
DatabaseService + DatabaseController (具体实现)
```

**优势**：
- 业务逻辑集中在 UseCase
- 通过 Repository 接口解耦
- 支持多种数据源实现
- 易于单元测试

### 2. 动态字段组件生成

**核心机制**: 根据字段类型动态生成输入组件

```dart
// FieldController.buildFieldWidget() 的工作原理
switch (field.type) {
  case 'Text':
    return TextFormField(...);
  case 'Integer':
    return TextFormField(keyboardType: TextInputType.number, ...);
  case 'Checkbox':
    return CheckboxListTile(...);
  case 'Date':
    return ListTile(onTap: () => showDatePicker(...));
  // ... 其他类型
}
```

### 3. JS API 实现模式

所有 JS API 遵循统一模式：

```dart
Future<String> _jsCreateDatabase(Map<String, dynamic> params) async {
  // 1. 调用 UseCase
  final result = await useCase.createDatabase(params);

  // 2. 处理结果
  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  // 3. 返回成功数据
  return jsonEncode(result.dataOrNull);
}
```

### 4. 数据选择器实现

支持两级数据选择：

```dart
// 数据库表选择器（单级）
SelectorStep(
  id: 'table',
  title: '数据库表列表',
  dataLoader: (_) async {
    final databases = await service.getAllDatabases();
    return databases.map((db) => SelectableItem(
      id: db.id,
      title: db.name,
      rawData: db,
    )).toList();
  },
)

// 记录选择器（两级）
// 第一级：选择数据库
// 第二级：选择记录（智能显示标题）
```

### 5. 主页小组件系统

```dart
// 1x1 快速访问
registry.register(HomeWidget(
  id: 'database_icon',
  builder: (context, config) => GenericIconWidget(...),
));

// 2x2 统计卡片
registry.register(HomeWidget(
  id: 'database_overview',
  builder: (context, config) => GenericPluginWidget(
    availableItems: [
      StatItemData(
        id: 'total_databases',
        label: '总数据库数',
        value: '$databaseCount',
      ),
    ],
  ),
));
```

---

## 架构演进

### UseCase 迁移（2025-12-12）

从直接业务逻辑迁移到 UseCase 架构：

**迁移前**:
- JS API 直接调用 Service/Controller
- 业务逻辑分散
- 难以测试

**迁移后**:
- JS API → UseCase → Repository → Service
- 业务逻辑集中
- 易于测试和扩展

**迁移成果**：
- ✅ 15 个 JS API 方法全部迁移
- ✅ 新增 ClientDatabaseRepository 适配器
- ✅ 保持向后兼容
- ✅ 支持分页和搜索功能

### 后续优化建议

1. **缓存层**: 添加查询结果缓存
2. **批量操作**: 支持批量创建/更新记录
3. **事务支持**: 支持多操作事务
4. **事件系统**: 数据变更事件通知
5. **数据验证**: 字段级别的验证规则
6. **导入导出**: CSV/Excel 格式支持
7. **关系字段**: 支持数据库间关联
8. **视图定制**: 自定义列表/表格视图

---

## 变更记录 (Changelog)

- **2025-12-17T12:10:45+08:00**: 完整更新 database 模块文档 - 新增 JS API 详解、UseCase 架构说明、数据选择器、主页小组件等内容
- **2025-12-12**: 完成 UseCase 架构迁移，实现业务逻辑与数据访问分离
- **2025-11-13**: 初始化数据库插件文档，识别 20 个文件、4 个数据模型、11 种字段类型

---

**相关链接**:
- [迁移报告](MIGRATION_REPORT.md) - 查看 UseCase 架构迁移详情
- [返回插件目录](../CLAUDE.md) | [返回根文档](../../../CLAUDE.md)