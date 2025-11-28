# 增强日历组件 (Enhanced Calendar)

这是一个支持背景图片和自定义样式的增强日历组件，基于 `table_calendar` 构建。

## 特性

- ✅ **背景图片支持** - 根据数据动态设置日历单元格背景图片
- ✅ **智能图片加载** - 自动识别网络图片、Asset图片、本地文件图片
- ✅ **自定义样式** - 支持自定义文本、颜色、圆角等
- ✅ **计数徽章** - 显示每个日期的条目数量
- ✅ **状态高亮** - 选中状态、今天状态、当前月份状态
- ✅ **事件回调** - 支持点击、长按、头部点击等交互
- ✅ **灵活配置** - 可配置导航、今天按钮、日期选择等功能
- ✅ **错误处理** - 图片加载失败时优雅降级

## 快速开始

### 基本用法

```dart
import 'package:Memento/widgets/enhanced_calendar/index.dart';

// 准备日期数据
final dayData = <DateTime, CalendarDayData>{
  DateTime(2025, 1, 15): CalendarDayData(
    date: DateTime(2025, 1, 15),
    backgroundImage: 'assets/images/special_day.png',
    count: 3,
    isSelected: false,
    isToday: false,
    isCurrentMonth: true,
  ),
  DateTime(2025, 1, 20): CalendarDayData(
    date: DateTime(2025, 1, 20),
    count: 1,
    isSelected: true,
    isToday: false,
    isCurrentMonth: true,
  ),
};

EnhancedCalendarWidget(
  dayData: dayData,
  focusedMonth: DateTime(2025, 1),
  selectedDate: DateTime(2025, 1, 20),
  onDaySelected: (selectedDay) {
    print('选择了日期: $selectedDay');
  },
  onDayLongPressed: (pressedDay) {
    print('长按了日期: $pressedDay');
  },
)
```

### 高级配置

```dart
EnhancedCalendarWidget(
  dayData: dayData,
  focusedMonth: DateTime(2025, 1),
  selectedDate: selectedDate,
  onDaySelected: (selectedDay) {
    setState(() {
      selectedDate = selectedDay;
    });
  },
  onDayLongPressed: (pressedDay) {
    // 长按显示菜单或导航到编辑页面
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(...),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Text('编辑日记'),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text('删除日记'),
        ),
      ],
    );
  },
  onHeaderTapped: (focusedMonth) {
    // 点击头部可以显示日期选择器
    showDatePicker(
      context: context,
      initialDate: focusedMonth,
      firstDate: DateTime(2010),
      lastDate: DateTime(2030),
    );
  },
  calendarFormat: CalendarFormat.month,
  enableNavigation: true,
  enableTodayButton: true,
  enableDateSelection: true,
  locale: 'zh_CN',
)
```

## API 参考

### CalendarDayData

日历日期数据模型，用于描述每个日期的显示内容。

```dart
class CalendarDayData {
  final DateTime date;           // 日期
  final String? backgroundImage; // 背景图片路径
  final int? count;              // 计数徽章数字
  final bool isSelected;         // 是否选中
  final bool isToday;           // 是否是今天
  final bool isCurrentMonth;    // 是否是当前月份
}
```

### EnhancedCalendarWidget

简化的日历组件构造函数。

#### 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `dayData` | `Map<DateTime, CalendarDayData>` | 必需 | 日期数据映射 |
| `focusedMonth` | `DateTime` | 必需 | 当前聚焦的月份 |
| `selectedDate` | `DateTime?` | `null` | 选中的日期 |
| `onDaySelected` | `Function(DateTime)?` | `null` | 日期选择回调 |
| `onDayLongPressed` | `Function(DateTime)?` | `null` | 日期长按回调 |
| `onHeaderTapped` | `Function(DateTime)?` | `null` | 头部点击回调 |
| `calendarFormat` | `CalendarFormat` | `month` | 日历格式 |
| `enableNavigation` | `bool` | `true` | 是否启用导航 |
| `enableTodayButton` | `bool` | `true` | 是否启用今天按钮 |
| `enableDateSelection` | `bool` | `true` | 是否启用日期选择 |
| `locale` | `String?` | `null` | 本地化设置 |

### EnhancedCalendarConfig

完整的日历配置类，提供更多自定义选项。

```dart
final config = EnhancedCalendarConfig(
  dayData: dayData,
  focusedDay: focusedMonth,
  selectedDay: selectedDate,
  dayTextStyle: TextStyle(fontSize: 16, color: Colors.black),
  selectedDayTextStyle: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
  todayTextStyle: TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold),
  selectedDayDecoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(8),
  ),
  todayDecoration: BoxDecoration(
    color: Colors.blue.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.blue, width: 1.5),
  ),
  dayMargin: EdgeInsets.all(4),
  dayRadius: 8,
);

EnhancedCalendar(config: config)
```

## 使用示例

### Calendar Album 插件示例

```dart
/// 在 calendar_album/screens/calendar_screen.dart 中使用

Map<DateTime, CalendarDayData> _getCalendarDayData() {
  final calendarController = Provider.of<CalendarController>(context, listen: false);
  final selectedDate = calendarController.selectedDate;
  final Map<DateTime, CalendarDayData> dayData = {};

  calendarController.entries.forEach((date, entries) {
    String? backgroundImage;

    // 优先获取当天日记的第一张图片作为背景
    for (var entry in entries) {
      // 首先检查直接的图片URLs
      if (entry.imageUrls.isNotEmpty) {
        backgroundImage = entry.imageUrls.first;
        break;
      }

      // 然后检查Markdown中提取的图片
      final markdownImages = entry.extractImagesFromMarkdown();
      if (markdownImages.isNotEmpty) {
        backgroundImage = markdownImages.first;
        break;
      }
    }

    dayData[date] = CalendarDayData(
      date: date,
      backgroundImage: backgroundImage,
      count: entries.length,
      isSelected: isSameDay(date, selectedDate),
      isToday: isSameDay(date, DateTime.now()),
      isCurrentMonth: date.month == _focusedDay.month,
    );
  });

  return dayData;
}

@override
Widget build(BuildContext context) {
  return EnhancedCalendarWidget(
    dayData: _getCalendarDayData(),
    focusedMonth: _focusedDay,
    selectedDate: calendarController.selectedDate,
    onDaySelected: (selectedDay) {
      calendarController.selectDate(selectedDay);
      setState(() => _focusedDay = selectedDay);
    },
    onDayLongPressed: (pressedDay) {
      // 长按日期打开编辑器
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => EntryEditorScreen(
          initialDate: pressedDay,
          isEditing: false,
        ),
      ));
    },
  );
}
```

### 背景图片优先级

Calendar Album 插件使用以下优先级获取背景图片：

1. **第一优先级**：日记的直接图片URLs (`entry.imageUrls.first`)
2. **第二优先级**：Markdown内容中的第一张图片
3. **多日记处理**：按日记顺序，使用第一篇日记的第一张图片
4. **无图片处理**：如果没有图片，则不设置背景图片

这种设计确保用户在日历中能看到当天的实际照片内容，而不是固定的背景图案。

## 智能图片加载

组件使用 `ImageUtils.createImageProvider()` 方法智能识别和加载不同类型的图片：

### 支持的图片类型

1. **网络图片**
   ```dart
   backgroundImage: 'https://example.com/image.jpg'
   ```

2. **Asset图片**
   ```dart
   backgroundImage: 'assets/images/bg.png'
   // 或
   backgroundImage: 'lib/plugins/calendar_album/assets/images/flower_bg.png'
   ```

3. **本地文件图片**
   ```dart
   backgroundImage: '/path/to/local/image.jpg'
   backgroundImage: './relative/path/image.jpg'
   ```

### 自动路径转换

- **插件Asset路径**: `lib/plugins/calendar_album/assets/images/bg.png` → `assets/plugins/calendar_album/bg.png`
- **相对路径**: `./images/bg.png` → 应用文档目录下的绝对路径
- **网络路径**: 直接使用，无需转换

## 背景图片说明

### 图片要求

- **格式**: PNG、JPG
- **透明度**: 建议使用半透明图片，确保文字可读
- **尺寸**: 建议与日历单元格尺寸匹配
- **路径**: 支持网络、Asset、本地文件路径

### 背景图片叠加效果

组件会自动为背景图片添加以下效果：

1. **透明度处理**: 默认添加 0.8 的透明度，确保背景图片不会过于突出
2. **暗色调叠加**: 添加暗色调叠加确保文字可读性
3. **错误处理**: 加载失败时优雅降级为纯色背景
4. **优先级逻辑**: 背景图片优先显示，不受选中状态影响

```dart
image: backgroundImage != null
    ? DecorationImage(
        image: ImageUtils.createImageProvider(backgroundImage),
        fit: BoxFit.cover,
        opacity: 0.8,
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.2),
          BlendMode.darken,
        ),
      )
    : null,
```

### 文字颜色智能适配

组件会根据背景图片自动调整文字颜色：

1. **有背景图片时**:
   - 文字颜色：白色
   - 字体粗细：bold
   - 文字阴影：添加黑色阴影确保可读性
   - 选中状态：添加下划线标识

2. **无背景图片时**:
   - 当前月份：黑色文字
   - 非当前月份：灰色文字
   - 今天状态：主题色文字
   - 选中状态：主题色文字 + 下划线

### 选中状态优化

- **移除背景颜色**: 选中状态不再显示背景色，避免遮挡背景图片
- **文字标识**: 使用下划线和颜色变化标识选中状态
- **描边效果**: 选中状态使用2像素宽的主题色描边，清晰标识选中状态
- **优先级处理**: 选中状态边框优先级高于今天状态边框

### 背景图片叠加效果

组件会自动为背景图片添加以下效果：

1. **透明度处理**: 默认添加 0.7 的透明度
2. **暗色调叠加**: 添加轻微的暗色调确保文字可读
3. **优先级逻辑**: 选中状态 > 背景图片 > 今天高亮

```dart
image: backgroundImage != null && !isSelected
    ? DecorationImage(
        image: AssetImage(backgroundImage),
        fit: BoxFit.cover,
        opacity: 0.7,
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.1),
          BlendMode.darken,
        ),
      )
    : null,
```

## 自定义样式示例

### 自定义选中效果

```dart
EnhancedCalendarWidget(
  // ... 其他参数
  // 通过 EnhancedCalendarConfig 进行高级配置
)

final config = EnhancedCalendarConfig(
  // ... 基本配置
  selectedDayDecoration: BoxDecoration(
    color: Colors.purple,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.purple.withValues(alpha: 0.3),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  selectedDayTextStyle: TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 18,
  ),
);
```

### 自定义今日效果

```dart
final config = EnhancedCalendarConfig(
  // ... 基本配置
  todayDecoration: BoxDecoration(
    color: Colors.orange.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: Colors.orange,
      width: 2,
    ),
  ),
  todayTextStyle: TextStyle(
    color: Colors.orange,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
);
```

## 注意事项

1. **图片路径**: 确保背景图片路径正确，使用相对路径
2. **性能考虑**: 避免在大量数据时使用复杂的背景图片
3. **可读性**: 确保背景图片不会影响文字的可读性
4. **国际化**: 使用 `locale` 参数设置合适的本地化
5. **日期标准化**: 使用 `DateTime(year, month, day)` 确保日期格式一致

## 依赖关系

- `table_calendar`: 核心日历组件
- `intl`: 日期格式化
- `flutter/material.dart`: Material Design 组件

## 更新日志

### v1.0.0
- ✅ 初始版本发布
- ✅ 支持背景图片
- ✅ 自定义样式配置
- ✅ 事件回调支持
- ✅ 简化的构造函数