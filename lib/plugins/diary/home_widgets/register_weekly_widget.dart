/// 日记插件 - 七日周报组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import '../models/diary_entry.dart';
import '../utils/diary_utils.dart';
import 'utils.dart';
import 'widgets.dart';

/// 注册七日周报小组件（4x1 宽屏卡片）
void registerWeeklyWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'diary_weekly',
      pluginId: 'diary',
      name: 'diary_weeklyName'.tr,
      description: 'diary_weeklyDescription'.tr,
      icon: Icons.calendar_view_week,
      color: Colors.indigo,
      defaultSize: const Wide2Size(),
      supportedSizes: [const WideSize(), const Wide2Size()],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => _buildWeeklyWidget(context, config),
    ),
  );
}

/// 构建七日日记小组件
Widget _buildWeeklyWidget(
  BuildContext context,
  Map<String, dynamic> config,
) {
  return FutureBuilder<Map<DateTime, DiaryEntry>>(
    future: DiaryUtils.loadDiaryEntries(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final entries = snapshot.data ?? {};
      final now = DateTime.now();
      final weekDays = getCurrentWeekDays(now);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 七天卡片
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    weekDays.map((date) {
                      final entry = entries[date];
                      final cardData = createWeekCardData(date, entry);
                      return buildDayCard(context, date, cardData);
                    }).toList(),
              ),
            ),
          ],
        ),
      );
    },
  );
}
