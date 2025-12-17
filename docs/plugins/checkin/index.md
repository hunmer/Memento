# Checkin - 签到管理插件

![Checkin Plugin](/icon.png)

✅ **Checkin 签到管理** - 培养良好习惯，用坚持成就更好的自己

## 核心功能

### 📋 签到项目管理
- **项目分类**：基于分组的签到项目展示，支持自定义分组
- **自定义项目**：创建专属的签到目标，如读书、运动、喝水等
- **项目图标**：为每个项目设置独特图标和颜色
- **拖拽排序**：支持分组内项目的拖拽排序

### 📅 智能签到系统
- **一键签到**：简单点击完成每日签到
- **时间段记录**：支持记录开始时间、结束时间和打卡时间
- **备注功能**：每次打卡可添加备注信息
- **提醒设置**：支持每周/每月/特定日期提醒功能

### 📊 连续性统计
- **连续天数追踪**：自动计算并显示连续打卡天数（连击）
- **打卡趋势图表**：柱状图展示每日打卡数量，支持周/月视图
- **连续打卡排行榜**：显示所有项目的连续天数排名
- **分组占比分析**：饼图展示各分组的打卡项目分布

### 🏆 数据可视化
- **完成度统计**：显示今日完成数/总数和完成率
- **Weekly打卡圈**：7天打卡状态可视化圆圈
- **统计卡片**：首页卡片显示今日打卡数和总打卡数
- **Android小组件**：支持1x1和2x2尺寸的桌面小组件

## 技术架构

### 核心组件

#### 插件主类
- **文件**: `checkin_plugin.dart`
- **职责**: 插件入口，管理打卡项目和界面导航
- **主界面**: 使用 NavigationBar 切换「打卡列表」和「打卡统计」

#### 数据模型

**CheckinItem (打卡项目)**
```dart
- id: 唯一ID (时间戳)
- name: 项目名称
- icon: 图标 (codePoint存储)
- color: 颜色 (整数值)
- group: 分组名称
- description: 描述
- frequency: 每周频率 (7个布尔值)
- reminderSettings: 提醒设置
- checkInRecords: 打卡记录 (按日期分组)
```

**CheckinRecord (打卡记录)**
```dart
- startTime: 开始时间
- endTime: 结束时间
- checkinTime: 打卡时间
- note: 备注 (可选)
```

**ReminderSettings (提醒设置)**
```dart
- type: 提醒类型 (weekly/monthly/specific)
- weekdays: 每周提醒的星期
- dayOfMonth: 每月提醒的日期
- specificDate: 特定日期提醒
- timeOfDay: 提醒时间
```

### 界面层结构

| 组件 | 文件 | 职责 |
|------|------|------|
| `CheckinMainView` | `checkin_plugin.dart` | 插件主视图容器 (双Tab导航) |
| `CheckinListScreen` | `screens/checkin_list_screen/` | 打卡列表主界面 |
| `CheckinStatsScreen` | `screens/checkin_stats_screen/` | 统计分析界面 |
| `CheckinFormScreen` | `screens/checkin_form_screen.dart` | 打卡项目表单 (创建/编辑) |
| `CheckinRecordScreen` | `screens/checkin_record_screen.dart` | 打卡记录历史界面 |
| `GroupListView` | `screens/checkin_list_screen/components/` | 分组列表视图 |

### API 接口

#### 统计接口
```dart
// 获取总打卡数
int getTotalCheckins();

// 获取今日打卡数
int getTodayCheckins();

// 触发保存
Future<void> triggerSave();
```

#### CheckinListController
```dart
// 获取所有分组
List<String> get groups;

// 构建分组列表项
List<Map<String, dynamic>> buildGroupListItems();

// 按分组获取打卡项目
Map<String, List<CheckinItem>> get groupedItems;

// 获取统计信息
Map<String, dynamic> getStatistics();

// 显示分组排序对话框
Future<void> showGroupSortDialog();

// 显示打卡项目操作菜单
void showItemOptionsDialog(CheckinItem item);
```

### 分组排序系统

#### 排序类型
- **按即将发生排序**: 按未打卡项目数量降序 (紧急程度)
- **按打卡频率排序**: 按平均每周打卡天数排序
- **按添加日期排序**: 使用ID(时间戳)作为创建时间参考

#### 排序持久化
- 使用 `SharedPreferences` 存储排序设置
- 自动恢复上次排序设置

### AI 数据分析集成

#### 工作流程
插件注册到 OpenAI 插件，支持通过 Prompt 调用打卡历史数据：

```dart
// 注册方法名: checkin_getCheckinHistory
{{checkin_getCheckinHistory(startDate: "2025-01-01", endDate: "2025-01-31")}}
```

#### 返回数据格式
```json
[
  {
    "name": "早起",
    "group": "健康习惯",
    "done": "2025/01/15 06:30",
    "start": "2025/01/15 06:00",
    "end": "2025/01/15 06:30",
    "note": "今天起床很顺利"
  }
]
```

#### 字段说明
- `name`: 打卡项目名称
- `group`: 所属分组 (可能为null)
- `done`: 打卡时间 (格式: yyyy/MM/dd HH:mm)
- `start`: 开始时间 (可选,仅当与结束时间相差至少1分钟时显示)
- `end`: 结束时间 (可选)
- `note`: 备注 (可选,非空时显示)

## 使用场景

### 个人成长
- **学习打卡**：每日学习、阅读、英语练习等
- **健康习惯**：运动、喝水、早睡早起等
- **技能提升**：练习乐器、绘画、编程等
- **生活优化**：冥想、记账、整理等

## 操作指南

### 创建签到项目
1. 点击「+」创建新项目
2. 输入项目名称 (必填,不允许重复)
3. 选择图标和颜色
4. 设置分组 (支持现有分组)
5. 设置提醒类型：
   - 无提醒
   - 每周提醒 (选择星期几)
   - 每月提醒 (选择几号)
   - 特定日期提醒 (日期选择器)
6. 设置提醒时间
7. 保存项目

### 日常签到
1. 在首页查看今日待签到项目
2. 点击项目卡片进入详情或直接点击打卡按钮
3. 可选：记录开始时间、结束时间和备注
4. 确认打卡
5. 查看历史记录和进度

### 分组管理
1. 点击打卡列表界面的分组管理按钮 (文件夹图标)
2. 可执行操作：
   - 添加新分组
   - 编辑分组名称
   - 删除空分组
   - 拖拽项目到不同分组

### 查看统计
1. 切换到「统计」标签
2. 查看三种图表：
   - **打卡趋势图** (柱状图): 支持周/月视图切换
   - **连续打卡排行榜**: 显示所有项目的连续天数
   - **分组占比饼图**: 按分组统计打卡项目数量

### 排序设置
1. 点击右上角排序按钮 (Icons.sort)
2. 选择排序类型：
   - 即将发生
   - 频率
   - 添加日期
3. 可选择正序/倒序
4. 设置会自动保存

## 数据存储

### 存储路径
- **根目录**: `checkin/`
- **数据文件**: `checkin/checkin_items.json`

### 数据结构
```json
{
  "items": [
    {
      "id": "1705308000000",
      "name": "早起",
      "icon": 59524,
      "color": 4280391411,
      "group": "健康习惯",
      "reminderSettings": {
        "type": 0,
        "weekdays": [1, 2, 3, 4, 5],
        "timeOfDay": {
          "hour": 6,
          "minute": 0
        }
      },
      "checkInRecords": {
        "2025-01-15": [
          {
            "startTime": "2025-01-15T06:00:00.000Z",
            "endTime": "2025-01-15T06:30:00.000Z",
            "checkinTime": "2025-01-15T06:30:00.000Z",
            "note": "今天起床很顺利"
          }
        ]
      }
    }
  ]
}
```

## 外部依赖

### 第三方包
- `intl`: 日期格式化
- `shared_preferences`: 存储排序设置
- `fl_chart`: 统计图表绘制

### 插件依赖
- **OpenAI Plugin**: AI 数据分析功能 (可选)
- **Core Event System**: 消息事件广播
- **StorageManager**: 数据存储
- **TagManagerDialog**: 分组管理对话框

## 国际化支持

### 支持语言
- 简体中文 (zh)
- 英语 (en)

### 本地化文件
- `l10n/checkin_localizations.dart` - 本地化接口
- `l10n/checkin_localizations_zh.dart` - 中文翻译
- `l10n/checkin_localizations_en.dart` - 英文翻译

## 事件系统

### 事件类型
| 事件名 | 触发时机 | 参数 |
|-------|---------|------|
| `checkin_deleted` | 删除打卡项目时 | `ItemEventArgs(itemId, title, action: 'deleted')` |

### 用途
通知其他模块 (如活动记录、日记等) 打卡项目的变更。

## 常见问题

**Q: 如何自定义分组？**
A: 点击打卡列表界面的分组管理按钮 (文件夹图标) → 添加/编辑/删除分组 → 拖拽项目到不同分组。

**Q: 如何计算连续打卡天数？**
A: 从今天开始倒推，遇到第一个未打卡的日期停止，最多检查365天。连续天数会在打卡项目卡片上显示。

**Q: 如何在 AI 分析中使用打卡数据？**
A: 在 OpenAI 插件的系统提示词中使用：`` {{`checkin_getCheckinHistory(startDate: "2025-01-01", endDate: "2025-01-31")`}} ``

**Q: 打卡记录如何存储？**
A: 打卡记录存储在 `CheckinItem.checkInRecords` 中，类型为 `Map<String, List<CheckinRecord>>`，Key为日期字符串 (yyyy-MM-dd格式)，Value为该日期的打卡记录列表。

**Q: 提醒功能如何实现？**
A: 当前 `ReminderSettings` 只负责存储提醒配置，实际的系统通知需要在应用层实现，建议使用 `flutter_local_notifications`。

**Q: 如何导出打卡数据？**
A: 当前未实现导出功能，可参考文档中的实现建议添加 CSV 导出功能。

---

*每一个今天的签到，都是为了成就更好的明天*