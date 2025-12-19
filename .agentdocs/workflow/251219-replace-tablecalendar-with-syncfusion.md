# TableCalendar 替换为 Syncfusion Flutter Calendar 任务文档

## 任务概述

将项目中所有 `table_calendar` 替换为 `syncfusion_flutter_calendar`，并保持原有的自定义样式和功能。

## 任务背景

- **目标**: 使用 Syncfusion Flutter Calendar 替换 TableCalendar
- **原因**: （用户需求）
- **范围**: 7 个文件需要修改

## 影响分析

### 涉及文件

1. **lib/widgets/enhanced_calendar/enhanced_calendar.dart**
   - 增强版日历组件
   - 支持背景图片、计数徽章、心情表情等自定义样式
   - 核心组件，被多个插件使用

2. **lib/plugins/diary/screens/diary_calendar_screen.dart**
   - 日记插件的日历视图
   - 显示日记条目的心情和字数
   - 使用 MonthSelector + TableCalendar 组合

3. **lib/widgets/data_selector_sheet/views/calendar_selection_view.dart**
   - 数据选择器中的日历视图
   - 用于在选择器中展示日历形式的选项

4. **lib/plugins/bill/screens/bill_list_screen.dart**
   - 账单插件的账单列表
   - 显示每日的收支情况

5. **lib/plugins/bill/screens/bill_list_screen_supercupertino.dart**
   - 账单的另一个界面版本

6. **lib/plugins/chat/screens/chat_screen/dialogs/calendar_date_picker_dialog.dart**
   - 聊天插件的日期选择对话框
   - 显示可用日期和消息数量

7. **pubspec.yaml**
   - 移除 table_calendar 依赖

## TableCalendar 功能分析

### 核心特性使用

1. **CalendarFormat** - 日历格式（月/周/两周）
2. **CalendarBuilders** - 自定义日期单元格构建器
3. **CalendarStyle** - 样式配置
4. **HeaderStyle** - 头部样式配置
5. **DaysOfWeekStyle** - 星期标题样式
6. **eventLoader** - 事件加载器（显示标记）
7. **selectedDayPredicate** - 选中日期判断
8. **onDaySelected** - 日期选择回调
9. **focusedDay** - 聚焦日期
10. **markerBuilder** - 标记构建器

### enhanced_calendar 特有功能

- 背景图片支持（DecorationImage）
- 计数徽章（右上角显示数字）
- 自定义边框和圆角
- 选中状态和今日高亮
- 禁用手势交互（AvailableGestures.none）

## Syncfusion Calendar API 映射

### 核心组件

```dart
SfCalendar(
  view: CalendarView.month,              // 对应 CalendarFormat
  dataSource: MeetingDataSource,         // 对应 eventLoader
  monthViewSettings: MonthViewSettings,  // 对应 CalendarStyle
  headerStyle: CalendarHeaderStyle,      // 对应 HeaderStyle
  cellBorderColor: Colors.transparent,   // 样式配置
  todayHighlightColor: Colors.blue,      // 今日高亮
  selectionDecoration: BoxDecoration,    // 选中样式
  onTap: CalendarTapCallback,            // 对应 onDaySelected
  onViewChanged: ViewChangedCallback,    // 页面切换回调
  monthCellBuilder: MonthCellBuilder,    // 对应 CalendarBuilders
)
```

### 关键差异

| TableCalendar | Syncfusion Calendar | 说明 |
|--------------|---------------------|------|
| `CalendarBuilders` | `monthCellBuilder` | 自定义单元格构建 |
| `eventLoader` | `dataSource` + `Appointment` | 事件数据源 |
| `selectedDayPredicate` | `selectedDate` | 选中日期 |
| `focusedDay` | `initialDisplayDate` | 初始显示日期 |
| `onDaySelected` | `onTap` | 点击回调 |
| `CalendarFormat` | `CalendarView` | 视图类型 |

### 自定义样式实现

Syncfusion 使用 `monthCellBuilder` 回调来自定义每个日期单元格：

```dart
SfCalendar(
  monthCellBuilder: (context, details) {
    // details.date - 日期
    // details.appointments - 该日期的事件列表
    // details.visibleDates - 可见日期范围
    return CustomDayCell(date: details.date);
  },
)
```

## 替换策略

### 阶段 1: EnhancedCalendar 重构

1. 创建 `Appointment` 数据源类
2. 实现 `monthCellBuilder` 自定义单元格
3. 保持现有的 `CalendarDayData` 数据模型
4. 移植背景图片、徽章、边框等样式

### 阶段 2: 各插件适配

1. **diary_calendar_screen**:
   - 适配心情表情显示
   - 保持 MonthSelector 组件
   - 适配日记预览逻辑

2. **bill_list_screen**:
   - 适配收支统计显示
   - 保持时间段选择器

3. **calendar_selection_view**:
   - 适配数据选择器逻辑
   - 保持多选/单选模式

4. **calendar_date_picker_dialog**:
   - 适配日期筛选逻辑
   - 保持消息数量标记

### 阶段 3: 依赖清理

1. 移除 pubspec.yaml 中的 table_calendar
2. 删除所有 table_calendar import
3. 运行 flutter pub get

### 阶段 4: 测试验证

1. 测试所有日历视图的显示
2. 测试日期选择功能
3. 测试自定义样式是否保持
4. 测试事件标记显示

## 实施计划

### TODO 列表

- [x] 分析 TableCalendar 当前使用情况和自定义样式
- [ ] 研究 syncfusion_flutter_calendar API 与 TableCalendar 的对应关系
- [ ] 替换 enhanced_calendar 组件中的 TableCalendar
- [ ] 替换 diary_calendar_screen 中的 TableCalendar
- [ ] 替换 calendar_selection_view 中的 TableCalendar
- [ ] 替换 bill_list_screen 中的 TableCalendar
- [ ] 替换 calendar_date_picker_dialog 中的 TableCalendar
- [ ] 从 pubspec.yaml 中移除 table_calendar 依赖
- [ ] 运行 flutter pub get 更新依赖
- [ ] 测试所有日历功能是否正常工作

## 技术决策

### 自定义样式保留方案

使用 `monthCellBuilder` + `Container` + `DecorationImage` 方案：

```dart
monthCellBuilder: (context, details) {
  final dayData = getDayData(details.date);

  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      image: dayData.backgroundImage != null
        ? DecorationImage(image: FileImage(...), fit: BoxFit.cover)
        : null,
      border: isSelected ? Border.all(...) : null,
    ),
    child: Stack(
      children: [
        // 日期数字
        Center(child: Text('${details.date.day}')),
        // 计数徽章
        if (dayData.count != null)
          Positioned(child: Badge(...)),
      ],
    ),
  );
}
```

### 数据源适配方案

创建 `CalendarDataSource` 类继承 `CalendarDataSource<Object>`：

```dart
class EnhancedCalendarDataSource extends CalendarDataSource {
  EnhancedCalendarDataSource(List<Appointment> appointments) {
    this.appointments = appointments;
  }
}
```

## 风险与挑战

1. **样式差异**: Syncfusion 的样式系统与 TableCalendar 不完全兼容，需要手动适配
2. **性能考虑**: 大量自定义单元格可能影响性能
3. **手势冲突**: 需要正确处理禁用手势的情况
4. **事件系统**: Appointment 模型与现有的 CalendarDayData 需要映射

## 参考资料

- [Syncfusion Flutter Calendar Documentation](https://help.syncfusion.com/flutter/calendar/overview)
- [TableCalendar Documentation](https://pub.dev/packages/table_calendar)
- 项目现有代码: `lib/widgets/enhanced_calendar/enhanced_calendar.dart`

## 备注

- 保持所有现有功能不变
- 确保自定义样式完整迁移
- 优先测试核心功能（enhanced_calendar、diary_calendar_screen）
- 考虑性能优化（大量日期的渲染）
