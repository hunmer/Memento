#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""更新 common_widgets.dart 文件，添加 sleepTrackingCard"""

file_path = r"D:\Memento\lib\screens\widgets_gallery\common_widgets\common_widgets.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. 添加导入语句
import_line = "import 'widgets/sleep_tracking_card_widget.dart';"
if import_line not in content:
    # 在 weekly_sleep_tracker_card 导入后添加
    content = content.replace(
        "import 'widgets/weekly_sleep_tracker_card.dart';",
        "import 'widgets/weekly_sleep_tracker_card.dart';\n" + import_line
    )

# 2. 添加枚举项
if 'sleepTrackingCard,' not in content:
    content = content.replace(
        'weeklySleepTrackerCard,\n  dailyTodoListCard,',
        'weeklySleepTrackerCard,\n  sleepTrackingCard,\n  dailyTodoListCard,'
    )

# 3. 添加元数据（在 weeklySleepTrackerCard 后面）
metadata_entry = """    CommonWidgetId.sleepTrackingCard: CommonWidgetMetadata(
      id: CommonWidgetId.sleepTrackingCard,
      name: '睡眠追踪卡片',
      description: '显示睡眠时长、标签和每周7天的进度环，支持动画效果',
      icon: Icons.bedtime_outlined,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
"""

if 'CommonWidgetId.sleepTrackingCard: CommonWidgetMetadata(' not in content:
    content = content.replace(
        "CommonWidgetId.dailyTodoListCard: CommonWidgetMetadata(",
        metadata_entry + "CommonWidgetId.dailyTodoListCard: CommonWidgetMetadata("
    )

# 4. 添加 switch case（在 weeklySleepTrackerCard 后面）
switch_case = """      case CommonWidgetId.sleepTrackingCard:
        return SleepTrackingCardWidget.fromProps(props, size);
"""

if 'case CommonWidgetId.sleepTrackingCard:' not in content:
    content = content.replace(
        "case CommonWidgetId.dailyTodoListCard:",
        switch_case + "case CommonWidgetId.dailyTodoListCard:"
    )

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("成功更新 common_widgets.dart")
