import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:Memento/widgets/widget_config_editor/widget_config_editor.dart';
import 'package:Memento/widgets/widget_config_editor/models/color_config.dart';
import 'package:Memento/widgets/widget_config_editor/models/widget_config.dart';
import 'package:Memento/widgets/widget_config_editor/models/widget_size.dart';
import 'package:Memento/plugins/calendar_album/controllers/calendar_controller.dart';

/// 每周相册小组件配置界面
class CalendarAlbumWeeklySelectorScreen extends StatefulWidget {
  final int? widgetId;

  const CalendarAlbumWeeklySelectorScreen({
    super.key,
    this.widgetId,
  });

  @override
  State<CalendarAlbumWeeklySelectorScreen> createState() =>
      _CalendarAlbumWeeklySelectorScreenState();
}

class _CalendarAlbumWeeklySelectorScreenState
    extends State<CalendarAlbumWeeklySelectorScreen> {
  late WidgetConfig _widgetConfig;
  int _currentWeekOffset = 0;

  @override
  void initState() {
    super.initState();
    _initWidgetConfig();
    // 加载配置
    _loadSavedConfig();
  }

  /// 初始化小组件配置
  void _initWidgetConfig() {
    _widgetConfig = WidgetConfig(
      colors: [
        ColorConfig(
          key: 'primary',
          label: '背景色',
          defaultValue: const Color(0xFF5A9E9A),
          currentValue: const Color(0xFF5A9E9A),
        ),
        ColorConfig(
          key: 'accent',
          label: '标题色',
          defaultValue: Colors.white,
          currentValue: Colors.white,
        ),
      ],
      opacity: 0.95,
    );
  }

  /// 加载已保存的配置
  Future<void> _loadSavedConfig() async {
    final widgetId = widget.widgetId;
    if (widgetId == null) return;

    try {
      final primaryColorStr = await HomeWidget.getWidgetData<String>(
        'calendar_album_weekly_primary_color_$widgetId',
      );
      final accentColorStr = await HomeWidget.getWidgetData<String>(
        'calendar_album_weekly_accent_color_$widgetId',
      );
      final opacityStr = await HomeWidget.getWidgetData<String>(
        'calendar_album_weekly_opacity_$widgetId',
      );
      final weekOffsetStr = await HomeWidget.getWidgetData<String>(
        'calendar_album_weekly_week_offset_$widgetId',
      );

      setState(() {
        final colors = <ColorConfig>[];

        if (primaryColorStr != null) {
          final colorValue = int.tryParse(primaryColorStr);
          if (colorValue != null) {
            colors.add(ColorConfig(
              key: 'primary',
              label: '背景色',
              defaultValue: const Color(0xFF5A9E9A),
              currentValue: Color(colorValue),
            ));
          }
        }

        if (accentColorStr != null) {
          final colorValue = int.tryParse(accentColorStr);
          if (colorValue != null) {
            colors.add(ColorConfig(
              key: 'accent',
              label: '标题色',
              defaultValue: Colors.white,
              currentValue: Color(colorValue),
            ));
          }
        }

        if (colors.isNotEmpty) {
          _widgetConfig = WidgetConfig(
            colors: colors,
            opacity: opacityStr != null
                ? (double.tryParse(opacityStr) ?? 0.95)
                : 0.95,
          );
        }

        if (weekOffsetStr != null) {
          _currentWeekOffset = int.tryParse(weekOffsetStr) ?? 0;
        }
      });
    } catch (e) {
      debugPrint('加载配置失败: $e');
    }
  }

  /// 保存配置并完成设置
  Future<void> _saveAndFinish() async {
    final widgetId = widget.widgetId;
    if (widgetId == null) return;

    try {
      final primaryColor = _widgetConfig.getColor('primary') ?? const Color(0xFF5A9E9A);
      final accentColor = _widgetConfig.getColor('accent') ?? Colors.white;
      final opacity = _widgetConfig.opacity;

      await HomeWidget.saveWidgetData<String>(
        'calendar_album_weekly_primary_color_$widgetId',
        primaryColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'calendar_album_weekly_accent_color_$widgetId',
        accentColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'calendar_album_weekly_opacity_$widgetId',
        opacity.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'calendar_album_weekly_week_offset_$widgetId',
        _currentWeekOffset.toString(),
      );

      await _syncDataToWidget();
      await HomeWidget.updateWidget(
        name: 'CalendarAlbumWeeklyWidgetProvider',
        iOSName: 'CalendarAlbumWeeklyWidget',
        qualifiedAndroidName: 'github.hunmer.memento.widgets.providers.CalendarAlbumWeeklyWidgetProvider',
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('保存配置失败: $e');
    }
  }

  /// 同步数据到小组件
  Future<void> _syncDataToWidget() async {
    final widgetId = widget.widgetId;
    if (widgetId == null) return;

    try {
      final calendarController = CalendarController();
      final now = DateTime.now();
      final currentWeekStart = _getWeekStart(now);
      final targetWeekStart = currentWeekStart.add(Duration(days: _currentWeekOffset * 7));

      final List<Map<String, dynamic>> weeklyData = [];
      for (int i = 0; i < 7; i++) {
        final date = targetWeekStart.add(Duration(days: i));
        final entries = calendarController.getEntriesForDate(date);

        final List<String> images = [];
        for (final entry in entries) {
          images.addAll(entry.imageUrls);
          images.addAll(entry.extractImagesFromMarkdown());
        }

        weeklyData.add({
          'dayIndex': i,
          'date': date.toIso8601String(),
          'dayName': _getDayName(i),
          'images': images.take(1).toList(),
          'hasEntry': entries.isNotEmpty,
        });
      }

      final weekInfo = _getWeeklyInfo(weekOffset: _currentWeekOffset);

      final widgetData = {
        'weekInfo': {
          'weekNumber': weekInfo['weekNumber'],
          'startDateStr': weekInfo['startDateStr'],
          'endDateStr': weekInfo['endDateStr'],
        },
        'days': weeklyData,
      };

      await HomeWidget.saveWidgetData<String>(
        'calendar_album_weekly_data_$widgetId',
        jsonEncode(widgetData),
      );

      debugPrint('同步每周相册数据完成');
    } catch (e) {
      debugPrint('同步数据失败: $e');
    }
  }

  /// 获取周信息
  Map<String, dynamic> _getWeeklyInfo({int weekOffset = 0}) {
    final now = DateTime.now();
    final currentWeekStart = _getWeekStart(now);
    final targetWeekStart = currentWeekStart.add(Duration(days: weekOffset * 7));
    final weekEnd = targetWeekStart.add(const Duration(days: 6));

    final yearStart = DateTime(now.year, 1, 1);
    final yearWeekStart = _getWeekStart(yearStart);
    final weekNumber = ((targetWeekStart.difference(yearWeekStart).inDays) / 7).floor() + 1;

    return {
      'weekNumber': weekNumber,
      'startDate': targetWeekStart,
      'endDate': weekEnd,
      'startDateStr': '${targetWeekStart.month}月 ${targetWeekStart.day}日',
      'endDateStr': '${weekEnd.month}月 ${weekEnd.day}日',
    };
  }

  /// 计算指定日期所在周的周一
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// 获取星期名称
  String _getDayName(int index) {
    const dayNames = ['一', '二', '三', '四', '五', '六', '日'];
    return dayNames[index];
  }

  /// 构建实时预览组件
  Widget _buildPreview(BuildContext context, WidgetConfig config) {
    final primaryColor = config.getColor('primary') ?? const Color(0xFF5A9E9A);
    final accentColor = config.getColor('accent') ?? Colors.white;
    final opacity = config.opacity;

    return Container(
      width: 280,
      height: 180,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部标题
          Text(
            'calendar_album_one_day_one_photo'.tr,
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // 周信息
          Text(
            'calendar_album_week_info'.tr,
            style: TextStyle(
              color: accentColor.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          // 星期按钮预览
          Row(
            children: List.generate(7, (index) {
              final dayName = _getDayName(index);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.image,
                        size: 20,
                        color: accentColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayName,
                      style: TextStyle(
                        color: accentColor.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('calendar_album_config_weekly_album_widget'.tr),
        actions: [
          TextButton(
            onPressed: _saveAndFinish,
            child: Text('calendar_album_complete'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 配置说明
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'calendar_album_config_description'.tr,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'calendar_album_config_description_text'.tr,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 主题配置编辑器
                  Text(
                    'calendar_album_widget_style'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  WidgetConfigEditor(
                    widgetSize: WidgetSize.large,
                    initialConfig: _widgetConfig,
                    onConfigChanged: (newConfig) {
                      setState(() {
                        _widgetConfig = newConfig;
                      });
                    },
                    previewBuilder: (context, config) => _buildPreview(context, config),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
