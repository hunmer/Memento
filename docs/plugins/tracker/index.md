# Tracker - 目标追踪插件

![Tracker Plugin](/icon.png)

🎯 **Tracker 目标追踪** - 量化目标进度，见证成长轨迹

## 核心功能

### 🎯 目标管理系统
- **多周期目标**：支持每日、每周、每月及自定义日期范围目标
- **自定义分组**：按类别组织目标，支持多分组管理
- **图标自定义**：每个目标可设置专属图标和颜色
- **背景图片**：支持为目标设置个性化背景图片
- **循环重置**：自动在周期结束后重置目标进度

### 📊 进度追踪
- **实时进度**：动态计算并显示目标完成百分比
- **多种记录方式**：
  - 手动输入数值
  - 快速记录按钮
  - 内置计时器（适合时间类目标）
- **历史记录**：完整保存所有记录，支持查看和删除
- **备注功能**：每条记录可添加详细备注
- **进度统计**：今日完成数、本月完成数、整体进度

### ⏰ 智能提醒
- **每日定时提醒**：可设置每日特定时间提醒完成目标
- **即时通知**：支持显示即时通知
- **通知自定义**：支持自定义通知标题和内容

### 👁️ 多种视图
- **列表视图**：详细展示目标信息
- **网格视图**：2列网格布局，视觉更紧凑
- **卡片摘要**：主页卡片显示今日和本月完成统计

### 🔄 事件系统
- **插件联动**：支持与其他插件通过事件系统协作
- **记录广播**：添加记录时自动广播事件

## 使用场景

### 💪 健康管理
- **体重管理**：每日记录体重，追踪减重进度
- **运动追踪**：记录每日运动时长或步数
- **喝水目标**：设置每日喝水杯数
- **睡眠记录**：追踪每日睡眠时间

### 📚 学习成长
- **阅读目标**：每日阅读页数或分钟数
- **技能练习**：记录练习乐器、编程等技能的时间
- **词汇积累**：每日学习新单词数量
- **课程学习**：追踪在线课程学习进度

### 💼 工作效率
- **任务完成**：记录每日完成任务数
- **代码提交**：追踪每日代码提交次数
- **客户沟通**：记录每日客户联系次数
- **学习时长**：追踪专业技能学习时间

### 🎨 兴趣爱好
- **摄影练习**：每日拍摄照片数量
- **写作目标**：每日写作字数
- **绘画进度**：记录每日绘画时长
- **手工制作**：追踪手工项目完成进度

## 操作指南

### 创建目标
1. 点击主界面的「+」按钮
2. 填写目标信息：
   - **目标名称**：如"每日阅读"
   - **图标选择**：从图标库选择或自定义
   - **颜色设置**：选择主题色
   - **单位类型**：如"分钟"、"次"、"页"等
   - **目标值**：如 30（分钟）
   - **分组**：选择或创建新分组
3. 设置日期规则：
   - **每日目标**：每天都需要完成
   - **每周目标**：选择特定星期几
   - **每月目标**：选择月份中的特定日期
   - **自定义日期范围**：设置开始和结束日期
4. 设置提醒时间（可选）
5. 是否开启循环重置
6. 选择背景图片（可选）
7. 保存目标

### 记录进度
1. **快速记录**：
   - 在目标卡片上点击「➕」按钮
   - 输入数值
   - 添加备注（可选）
   - 点击保存

2. **计时器记录**：
   - 在目标卡片上点击「⏱」按钮
   - 选择倒计时或正计时
   - 开始计时
   - 暂停/继续（可选）
   - 完成后自动保存记录

3. **手动记录**：
   - 点击目标卡片进入详情页
   - 点击「添加记录」
   - 选择记录时间（可追溯历史）
   - 输入数值和备注
   - 保存记录

### 查看进度
1. **目标列表**：
   - 主界面显示所有目标
   - 切换列表/网格视图
   - 按分组筛选
   - 按状态筛选（全部/进行中/已完成）
   - 按时间筛选（最近/本周/本月）

2. **目标详情**：
   - 点击目标卡片查看详情
   - 查看进度条和完成百分比
   - 浏览历史记录列表
   - 编辑目标信息
   - 清空所有记录

3. **统计分析**：
   - 查看今日完成目标数
   - 查看本月完成目标数
   - 整体进度统计

## 数据结构

### 目标 (Goal)
每个目标包含以下信息：
- **基本信息**：ID、名称、图标、颜色、分组
- **数值设置**：单位类型、目标值、当前值
- **时间设置**：日期类型、开始/结束日期、选定星期、月份日期
- **提醒设置**：提醒时间、是否循环重置
- **样式设置**：背景图片路径、进度条颜色
- **创建时间**：目标创建的时间戳

### 记录 (Record)
每次进度记录包含：
- **关联目标**：目标ID
- **记录值**：本次记录的数值
- **记录时间**：记录发生的精确时间
- **备注信息**：可选的文本说明
- **持续时间**：计时器记录的时长（秒）

## 高级功能

### 通知系统
- **初始化通知**：应用启动时自动初始化
- **每日提醒**：可调度每日特定时间通知
- **即时通知**：手动触发立即显示的通知
- **通知管理**：支持更新和取消已调度的通知

### 数据管理
- **本地存储**：数据存储在 `tracker/` 目录下
  - `goals.json`：所有目标数据
  - `records.json`：所有记录数据
- **数据同步**：支持通过 WebDAV 同步
- **备份恢复**：定期备份重要数据

### 事件广播
- **onRecordAdded**：添加记录时触发
- **用途**：其他插件可监听此事件实现联动
  - 自动生成日记条目
  - 创建活动记录
  - 更新统计数据

## API 接口

### 统计查询
```dart
// 获取今日完成的目标数
int getTodayCompletedGoals();

// 获取本月完成的目标数
int getMonthCompletedGoals();

// 获取本月新增的目标数
int getMonthAddedGoals();

// 获取今日记录数
int getTodayRecordCount();
```

### 目标管理
```dart
// 创建新目标
Future<void> addGoal(Goal goal);

// 更新目标
Future<void> updateGoal(String id, Goal newGoal);

// 删除目标
Future<void> deleteGoal(String id);

// 切换目标完成状态
Future<void> toggleGoalCompletion(String id);

// 获取所有目标
Future<List<Goal>> getAllGoals();

// 按状态获取目标
Future<List<Goal>> getGoalsByStatus(String status);

// 获取所有分组
List<String> getAllGroups();
```

### 记录管理
```dart
// 添加记录
Future<void> addRecord(Record record, Goal goal);

// 删除记录
Future<void> deleteRecord(String recordId);

// 清空目标的所有记录
Future<void> clearRecordsForGoal(String goalId);

// 获取目标的所有记录
Future<List<Record>> getRecordsForGoal(String goalId);

// 监听目标记录变化（实时更新）
Stream<List<Record>> watchRecordsForGoal(String goalId);
```

### 进度计算
```dart
// 计算单个目标进度
double calculateProgress(Goal goal);

// 计算整体进度
double calculateOverallProgress();

// 获取目标总数
int getGoalCount();
```

## 开发者信息

### 技术栈
- **框架**：Flutter + Dart
- **状态管理**：Provider + ChangeNotifier
- **存储**：本地文件系统 / WebDAV
- **通知**：flutter_local_notifications
- **依赖**：uuid, provider, logging

### 目录结构
```
tracker/
├── tracker_plugin.dart              # 插件主类
├── models/                          # 数据模型
│   ├── goal.dart                   # 目标模型
│   └── record.dart                 # 记录模型
├── controllers/                     # 业务逻辑
│   └── tracker_controller.dart     # 控制器
├── screens/                        # 界面层
│   ├── home_screen.dart           # 主界面
│   └── goal_detail_screen.dart    # 目标详情
├── widgets/                        # UI 组件
│   ├── goal_card.dart             # 目标卡片
│   ├── goal_edit_page.dart        # 编辑对话框
│   ├── record_dialog.dart         # 记录对话框
│   ├── timer_dialog.dart          # 计时器
│   └── tracker_summary_card.dart  # 统计卡片
├── utils/                          # 工具类
│   ├── date_utils.dart            # 日期工具
│   └── tracker_notification_utils.dart  # 通知工具
└── l10n/                           # 国际化
    ├── tracker_localizations.dart
    ├── tracker_localizations_zh.dart
    └── tracker_localizations_en.dart
```

### 存储格式

**goals.json**：
```json
{
  "goals": [
    {
      "id": "1234567890",
      "name": "每日阅读",
      "icon": "57455",
      "iconColor": 4294198070,
      "unitType": "分钟",
      "targetValue": 30,
      "currentValue": 15,
      "dateSettings": {
        "type": "daily",
        "startDate": null,
        "endDate": null,
        "selectedDays": null,
        "monthDay": null
      },
      "reminderTime": "09:00",
      "isLoopReset": true,
      "createdAt": "2025-01-15T08:30:00.000Z",
      "group": "学习",
      "imagePath": "/storage/tracker/images/reading.jpg",
      "progressColor": 4283215696
    }
  ],
  "lastUpdated": "2025-01-15T20:15:00.000Z"
}
```

**records.json**：
```json
{
  "records": [
    {
      "id": "1736950800123",
      "goalId": "1234567890",
      "value": 15,
      "note": "阅读技术文档",
      "recordedAt": "2025-01-15T09:30:00.000Z",
      "durationSeconds": 900
    }
  ],
  "lastUpdated": "2025-01-15T09:30:00.000Z"
}
```

## 常见问题

**Q: 如何实现目标的循环重置？**
A: 在目标设置中开启「循环重置」选项。系统会在每个周期结束后自动将当前值重置为 0。需手动触发重置检查。

**Q: 计时器功能和普通记录有什么区别？**
A: 计时器会记录精确的持续时间（秒），适合时间类目标如「每日运动30分钟」。普通记录只需输入数值。

**Q: 可以为目标设置背景图片吗？**
A: 可以。在编辑目标时选择图片，图片会保存到本地，目标卡片会显示该背景。

**Q: 如何监听目标完成事件？**
A: 当前插件提供 `onRecordAdded` 事件监听。如需目标完成事件，建议自行在 `updateGoal()` 中添加事件广播。

**Q: 数据的存储路径在哪里？**
A: 数据存储在应用的 `tracker/` 目录下，包含 `goals.json` 和 `records.json` 两个文件。

**Q: 如何实现插件间联动？**
A: 通过事件系统。其他插件可以监听 `onRecordAdded` 事件，在添加记录时自动执行相应操作。

**Q: 支持哪些日期设置类型？**
A: 支持四种类型：
- `daily`：每日目标
- `weekly`：每周目标（指定星期几）
- `monthly`：每月目标（指定日期）
- `custom`：自定义日期范围

**Q: 进度计算是如何实现的？**
A: 进度 = 当前值 / 目标值。当前值超过目标值时，进度条可能超过 100%。

## 更新日志

- **2025-11-13**：初始化目标追踪插件
  - 实现目标管理系统
  - 实现进度追踪功能
  - 实现记录管理功能
  - 实现通知系统
  - 实现事件广播
  - 添加多视图支持
  - 添加计时器功能

---

*让每一个进步都可见，让每一份努力都有意义*
