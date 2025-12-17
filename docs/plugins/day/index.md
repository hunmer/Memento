# Day - 纪念日插件

🎂 **Day 纪念日管理** - 珍藏每一个特殊的日子

## 核心功能

### 纪念日管理
- **创建纪念日**：记录生日、结婚纪念日、节日等重要日期
- **编辑与删除**：随时修改或删除纪念日信息
- **笔记备注**：为每个纪念日添加多条笔记

### 倒计时功能
- **自动计算**：自动计算剩余天数或已过天数
- **今日提醒**：标记今天到期的纪念日
- **即将到来**：7天内的纪念日一目了然

### 多视图展示
- **卡片视图**：精美卡片展示，支持背景颜色和图片
- **列表视图**：紧凑列表展示，便于快速浏览
- **一键切换**：在两种视图间自由切换

### 灵活排序
- **即将发生**：按剩余天数排序，最近的在前
- **最近添加**：按创建时间排序，新添加的在前
- **手动排序**：拖拽重排序，自定义顺序

### 自定义外观
- **背景颜色**：为每个纪念日选择专属颜色
- **背景图片**：支持本地或网络图片作为背景
- **随机配色**：新建时自动分配柔和色调

## 数据模型

### MemorialDay 纪念日

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | 唯一标识符 (UUID) |
| `title` | String | 纪念日标题 |
| `creationDate` | DateTime | 创建时间 |
| `targetDate` | DateTime | 目标日期 |
| `notes` | List\<String\> | 笔记列表 |
| `backgroundColor` | Color | 背景颜色 |
| `backgroundImageUrl` | String? | 背景图片 URL |
| `sortIndex` | int | 手动排序索引 |

**计算属性**：
- `daysRemaining`：剩余天数（负数表示已过期）
- `isExpired`：是否已过期
- `daysPassed`：已过天数
- `isToday`：是否是今天

## API 接口

### DayController 控制器

```dart
// 获取所有纪念日
List<MemorialDay> get memorialDays;

// 添加纪念日
Future<void> addMemorialDay(MemorialDay memorialDay);

// 更新纪念日
Future<void> updateMemorialDay(MemorialDay memorialDay);

// 删除纪念日
Future<void> deleteMemorialDay(String id);

// 手动重新排序
Future<void> reorderMemorialDays(int oldIndex, int newIndex);

// 设置排序模式
Future<void> setSortMode(SortMode mode);

// 切换视图模式
void toggleView();
```

### 统计接口

```dart
// 获取纪念日总数
int getMemorialDayCount();

// 获取即将到来的纪念日（7天内）
List<String> getUpcomingMemorialDays();
```

## 排序模式

```dart
enum SortMode {
  upcoming,  // 按剩余天数排序
  recent,    // 按创建时间排序
  manual,    // 手动排序（支持拖拽）
}
```

## AI 数据集成

### Prompt 替换方法

插件注册到 OpenAI 插件，支持 AI 数据分析：

```
{{day_getDays(startDate: "2025-01-01", endDate: "2025-12-31")}}
```

**参数**：
- `startDate`：开始日期 (YYYY-MM-DD)
- `endDate`：结束日期 (YYYY-MM-DD)

**返回格式**：
```json
{
  "records": [
    {
      "date": "2025-06-15",
      "title": "生日",
      "daysRemaining": 120,
      "notes": ["准备礼物"]
    }
  ]
}
```

## 主页卡片

插件在主页提供统计卡片：
- 纪念日总数
- 即将到来的事件（7天内）

## 存储结构

```
day/
├── memorial_days.json      # 所有纪念日数据
└── view_preference.json    # 视图偏好设置
```

## 界面组件

| 组件 | 职责 |
|------|------|
| `DayHomeScreen` | 纪念日列表主界面 |
| `EditMemorialDayDialog` | 编辑对话框（信息/笔记/外观三标签页） |
| `MemorialDayCard` | 卡片视图组件 |
| `MemorialDayListItem` | 列表视图组件 |

### 编辑对话框标签页

1. **信息 (Information)**：标题、目标日期
2. **笔记 (Notes)**：笔记列表管理
3. **外观 (Appearance)**：颜色选择、背景图片

## 状态颜色

列表视图使用文本颜色区分状态：
- 🟢 绿色：今天
- ⚫ 灰色：已过期
- 🟠 橙色：7天内
- 🔵 蓝色：其他

## 操作指南

### 添加纪念日
1. 点击右上角「+」按钮
2. 填写标题和目标日期
3. 可选添加笔记
4. 可选设置背景颜色或图片
5. 点击保存

### 管理纪念日
1. 点击纪念日卡片/列表项进入编辑
2. 使用排序菜单切换排序模式
3. 手动排序模式下可拖拽重排

### 切换视图
点击标题栏的视图切换按钮在卡片/列表视图间切换

## 国际化

支持语言：
- 简体中文 (zh)
- 英语 (en)

## 常见问题

**Q: 如何使用 AI 分析纪念日数据？**

在 OpenAI 插件的 Prompt 中使用：
```
请分析我在 {{day_getDays(startDate: "2025-01-01", endDate: "2025-12-31")}} 的纪念日
```

**Q: 手动排序模式下如何重新排序？**

选择「手动排序」模式后，长按卡片或列表项即可拖拽重排序。

**Q: 可以为纪念日添加背景图片吗？**

可以，在编辑对话框的「外观」标签页中选择本地或网络图片。

**Q: 纪念日数据存储在哪里？**

数据存储在本地 `day/memorial_days.json` 文件中，支持 WebDAV 同步。

---

*让每一个特殊的日子都闪闪发光*
