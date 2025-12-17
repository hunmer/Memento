# Diary - 日记记录插件

![Diary Plugin](/icon.png)

📔 **Diary 日记记录** - 用文字记录生活，用回忆温暖时光

## 核心功能

### 📅 日历视图
- **可视化浏览**：基于日历组件直观展示日记条目
- **心情标记**：日历格子显示当日心情表情符号
- **字数统计**：显示每日字数统计，激励持续写作
- **双击编辑**：双击日期快速进入编辑模式
- **智能限制**：禁止选择未来日期，保持日记的真实性

### ✍️ Markdown 编辑器
- **完整 Markdown 支持**：支持标题、列表、链接、代码等所有语法
- **标题与内容分离**：独立设置日记标题
- **实时保存**：编辑时自动保存到本地存储
- **优雅界面**：基于 flutter_quill 组件的流畅编辑体验

### 😊 心情记录
- **表情符号记录**：使用 10 种表情记录每日心情
  - `😊` `😢` `😡` `😴` `🤔` `😎` `😍` `🤮` `😱` `🥳`
- **心情可视化**：在日历上直观显示心情变化
- **数据分析**：结合 AI 分析心情趋势

### 📊 智能统计
- **今日字数**：实时统计当日写作字数
- **本月字数**：月度写作量统计
- **完成进度**：本月已写天数 / 总天数
- **卡片展示**：主屏幕卡片快速查看核心数据
- **缓存优化**：使用索引文件缓存统计数据，快速加载

### 🤖 AI 数据分析
- **深度分析**：集成 OpenAI 插件，提供智能日记分析
- **情感分析**：分析心情变化趋势和规律
- **主题提取**：自动提取日记中的关键词和主题
- **智能总结**：生成周报、月报等周期性总结

### 🔔 事件系统
- **实时广播**：支持日记创建、更新、删除事件
- **事件类型**：
  - `diary_entry_created` - 新建日记时触发
  - `diary_entry_updated` - 更新日记时触发
  - `diary_entry_deleted` - 删除日记时触发
- **跨插件通信**：其他插件可监听日记事件

## 数据模型

### DiaryEntry (日记条目)
```json
{
  "date": "2025-01-15",
  "title": "美好的一天",
  "content": "今天天气很好，完成了很多工作...",
  "createdAt": "2025-01-15T08:30:00.000Z",
  "updatedAt": "2025-01-15T20:15:00.000Z",
  "mood": "😊"
}
```

### 存储结构
```
diary/
├── diary_index.json              # 索引文件（包含 totalCharCount 统计）
├── 2025-01-15.json              # 具体日期的日记文件
├── 2025-01-16.json
└── ...
```

## 核心 API

### 统计接口
- `getTodayWordCount()` - 获取今日文字数
- `getMonthWordCount()` - 获取本月文字数
- `getMonthProgress()` - 获取本月完成进度（已完成天数/总天数）
- `getDiaryStats()` - 获取日记统计信息（总字数、条目数、平均字数）

### 数据操作
- `loadDiaryEntries()` - 加载所有日记条目
- `saveDiaryEntry(date, content, {title, mood})` - 保存日记条目
- `loadDiaryEntry(date)` - 加载特定日期的日记
- `deleteDiaryEntry(date)` - 删除特定日期的日记
- `hasEntryForDate(date)` - 检查特定日期是否有日记

### AI 分析接口
- `getDiaries(params)` - 获取指定日期范围的日记数据
  - 参数：`{ "startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD" }`
  - 返回：JSON 字符串，包含日记列表和总数

## 界面结构

### DiaryCalendarScreen (日历视图主界面)
```
Scaffold
├── AppBar (标题栏)
└── Column
    ├── Expanded (flex: 2) - 日历区域
    │   └── TableCalendar
    │       ├── 日期单元格（显示日期）
    │       └── markerBuilder（显示心情 + 字数）
    └── Expanded (flex: 1) - 预览区域
        └── 显示选中日期的日记预览
```

**交互方式**：
- 单击日期：显示日记预览
- 双击日期：打开编辑器
- 日历格子：显示心情表情和字数统计

### DiaryEditorScreen (日记编辑界面)
- **Markdown 编辑器**：基于 MarkdownEditor 组件
- **标题输入**：独立的标题字段
- **心情选择器**：10 种表情选择
- **自动保存**：实时保存到存储

## 使用场景

### 个人成长记录
- **每日反思**：记录每天的收获与不足
- **心情日记**：通过表情记录心情变化
- **学习笔记**：记录学习内容和心得体会
- **目标追踪**：记录目标进展，追踪成长轨迹

### 生活记录
- **旅行日记**：记录旅行见闻和美好回忆
- **美食记录**：记录品尝过的美食和烹饪心得
- **人际关系**：记录与朋友、家人的互动时光
- **创意灵感**：随时记录突发的创意想法

### 工作记录
- **工作日志**：记录每日工作内容和成果
- **会议纪要**：记录重要会议内容和决策
- **项目进展**：跟踪项目进展和遇到的问题
- **技能学习**：记录工作技能的学习过程

## 操作指南

### 创建日记
1. 在日历视图双击目标日期
2. 或点击「+」按钮创建新日记
3. 编写标题（可选）
4. 使用 Markdown 语法编写内容
5. 选择当日心情表情
6. 保存（自动保存）

### 浏览日记
1. 在日历视图中点击日期查看预览
2. 双击日期进入编辑模式
3. 主屏幕卡片查看核心统计数据
4. 查看今日字数、本月字数、完成进度

### AI 分析
1. 在 OpenAI 插件中调用日记分析功能
2. 使用语法：`` {{`diary_getDiaries(startDate: "2025-01-01", endDate: "2025-01-31")`}} ``
3. AI 将返回指定日期范围内的日记数据
4. 基于数据进行心情趋势、主题分析等

## 国际化支持

- **简体中文 (zh)**
- **英语 (en)**

### 本地化接口
```dart
abstract class DiaryLocalizations {
  String get name;                      // 插件名称
  String get todayWordCount;            // 今日字数
  String get monthWordCount;            // 本月字数
  String get monthProgress;             // 本月进度
  String get titleHint;                 // 标题提示
  String get contentHint;               // 内容提示
  String get selectMood;                // 选择心情
  String get clearSelection;            // 清除选择
  String get cannotSelectFutureDate;    // 不能选择未来日期
  String get myDiary;                   // 我的日记
  String get moodSelectorTooltip;       // 心情选择器提示
}
```

## 高级功能

### 卡片视图
主屏幕提供卡片视图，展示：
```
┌─────────────────────────────┐
│ 📖 日记                    │
├─────────────────────────────┤
│  今日字数    │   本月字数   │
│     520     │    15,000    │
├─────────────────────────────┤
│        本月进度             │
│         15/31               │
└─────────────────────────────┘
```

### 索引文件机制
- 使用 `diary_index.json` 维护日记列表
- 缓存总字数统计，避免每次遍历目录
- 快速获取所有日记日期和最后更新时间
- 在保存/删除时自动更新索引

### 日期标准化
为避免时区问题，所有日期进行标准化处理：
```dart
static DateTime _normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
```

## 技术实现

### 目录结构
```
diary/
├── diary_plugin.dart                    # 插件主类 + 事件定义
├── models/
│   └── diary_entry.dart                 # 日记条目模型
├── services/
│   └── prompt_replacements.dart         # AI Prompt 替换方法
├── screens/
│   ├── diary_calendar_screen.dart       # 日历视图界面
│   └── diary_editor_screen.dart         # 编辑器界面
├── controls/
│   └── prompt_controller.dart           # Prompt 控制器（注册到 OpenAI）
├── utils/
│   └── diary_utils.dart                 # 工具类（CRUD + 统计）
└── l10n/
    ├── diary_localizations.dart         # 国际化接口
    ├── diary_localizations_zh.dart      # 中文翻译
    └── diary_localizations_en.dart      # 英文翻译
```

### 关键依赖
- **Flutter 包**：
  - `table_calendar: ^3.0.0` - 日历组件
  - `intl: ^0.18.0` - 日期格式化
  - `path: ^1.8.0` - 路径处理
  - `flutter_quill` - Markdown 渲染（通过 MarkdownEditor 组件）

- **核心依赖**：
  - `BasePlugin` - 插件基类
  - `StorageManager` - 数据持久化
  - `EventManager` - 事件广播系统
  - `PluginManager` - 插件管理器
  - `OpenAI Plugin` - AI 数据分析（可选）

### 延迟注册机制
由于插件初始化顺序不确定，使用延迟 + 重试机制注册到 OpenAI：
```dart
Future.delayed(const Duration(seconds: 1), () {
  _registerPromptMethods();
});
```

## 常见问题

**Q: 如何添加新的心情表情？**
A: 在 `diary_editor_screen.dart` 中修改 `_moods` 列表，添加新的表情符号。

**Q: 如何在 AI 分析中使用日记数据？**
A: 在 OpenAI 插件的系统提示词中使用：`` {{`diary_getDiaries(startDate: "2025-01-01", endDate: "2025-01-31")`}} ``

**Q: 日记的字数统计在哪里？**
A:
- 实时统计：`DiaryPlugin.getTodayWordCount()` / `getMonthWordCount()`
- 索引缓存：`diary_index.json` 中的 `totalCharCount` 字段
- 显示位置：插件卡片视图、日历日期格子

**Q: 如何修改日记存储格式？**
A: 当前使用 JSON 格式。如需改为 Markdown 文件，需要：
1. 修改 `DiaryUtils._getEntryPath()` 返回 `.md` 路径
2. 修改 `saveDiaryEntry()` 使用 `writeFile()` 而非 `writeJson()`
3. 修改 `loadDiaryEntry()` 解析 Markdown 文件头部的元数据

## 写作技巧

✍️ **建立习惯**：每天固定时间写日记，如睡前或早晨

✍️ **真诚记录**：记录真实的想法和感受，不刻意美化

✍️ **结构化**：使用标题、列表等结构化内容

✍️ **配图丰富**：适当添加图片，让日记更生动

✍️ **定期回顾**：定期回顾过往日记，发现成长轨迹

## 小贴士

💡 **备份重要**：建议定期导出重要日记进行备份

💡 **心情记录**：坚持使用表情记录心情，AI 可以帮你分析心情趋势

💡 **字数统计**：关注每日字数，养成写作习惯

💡 **AI 分析**：定期使用 AI 分析功能，了解自己的写作模式和心情规律

---

*让每一个平凡的日子都值得被记录*
