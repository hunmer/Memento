import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../widgets/widget_config_editor/widget_config_editor.dart';
import '../../widgets/widget_config_editor/models/color_config.dart';
import '../../widgets/widget_config_editor/models/widget_config.dart';
import 'entry_editor/entry_editor_ui.dart';
import 'entry_editor/entry_editor_controller.dart';
import '../l10n/calendar_album_localizations.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/tag_controller.dart';
import 'package:provider/provider.dart';

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
  }

  /// 初始化小组件配置
  void _initWidgetConfig() {
    _widgetConfig = WidgetConfig(
      colors: [
        ColorConfig(
          key: 'primary',
          label: '背景色',
          defaultValue: const Color(0xFF5A9E9A), // 默认绿色
          currentValue: const Color(0xFF5A9E9A),
        ),
        ColorConfig(
          key: 'accent',
          label: '标题色',
          defaultValue: Colors.white,
          currentValue: Colors.white,
        ),
      ],
      opacity: 0.95, // 默认透明度
    );

    // 如果有 widgetId，尝试加载已保存的配置
    if (widgetId != null) {
      _loadSavedConfig();
    }
  }

  /// 加载已保存的配置
  Future<void> _loadSavedConfig() async {
    if (widgetId == null) return;

    try {
      // 加载颜色配置
      final primaryColorStr = await HomeWidget.getWidgetData<String>(
        'calendar_album_weekly_primary_color_${widgetId}',
      );
      final accentColorStr = await HomeWidget.getWidgetData<String>(
        'calendar_album_weekly_accent_color_${widgetId}',
      );
      final opacityStr = await HomeWidget.getWidgetData<String>(
        'calendar_album_weekly_opacity_${widgetId}',
      );
      final weekOffsetStr = await HomeWidget.getWidgetData<String>(
        'calendar_album_weekly_week_offset_${widgetId}',
      );

      setState(() {
        // 解析颜色值
        if (primaryColorStr != null) {
          final colorValue = int.tryParse(primaryColorStr);
          if (colorValue != null) {
            _widgetConfig.getColor('primary')?.currentValue = Color(colorValue);
          }
        }

        if (accentColorStr != null) {
          final colorValue = int.tryParse(accentColorStr);
          if (colorValue != null) {
            _widgetConfig.getColor('accent')?.currentValue = Color(colorValue);
          }
        }

        if (opacityStr != null) {
          _widgetConfig.opacity = double.tryParse(opacityStr) ?? 0.95;
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
    if (widgetId == null) return;

    try {
      // 1. 获取配置值
      final primaryColor = _widgetConfig.getColor('primary')?.currentValue ?? const Color(0xFF5A9E9A);
      final accentColor = _widgetConfig.getColor('accent')?.currentValue ?? Colors.white;
      final opacity = _widgetConfig.opacity;

      // 2. 保存颜色配置（必须使用 String 类型！）
      await HomeWidget.saveWidgetData<String>(
        'calendar_album_weekly_primary_color_${widgetId}',
        primaryColor.value.toString(), // Color.value 转为字符串
      );

      await HomeWidget.saveWidgetData<String>(
        'calendar_album_weekly_accent_color_${widgetId}',
        accentColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'calendar_album_weekly_opacity_${widgetId}',
        opacity.toString(), // double 转为字符串
      );

      // 3. 保存当前周偏移量
      await HomeWidget.saveWidgetData<String>(
        'calendar_album_weekly_week_offset_${widgetId}',
        _currentWeekOffset.toString(),
      );

      // 4. 同步数据并更新小组件
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
    try {
      final calendarController = CalendarController();
      final now = DateTime.now();
      final currentWeekStart = _getWeekStart(now);
      final targetWeekStart = currentWeekStart.add(Duration(days: _currentWeekOffset * 7));

      // 获取一周的日记数据
      final List<Map<String, dynamic>> weeklyData = [];
      for (int i = 0; i < 7; i++) {
        final date = targetWeekStart.add(Duration(days: i));
        final entries = calendarController.getEntriesForDate(date);

        // 获取该日期的所有图片
        final List<String> images = [];
        for (final entry in entries) {
          images.addAll(entry.imageUrls);
          images.addAll(entry.extractImagesFromMarkdown());
        }

        weeklyData.add({
          'dayIndex': i,
          'date': date.toIso8601String(),
          'dayName': _getDayName(i),
          'images': images.take(1).toList(), // 只取第一张图片作为缩略图
          'hasEntry': entries.isNotEmpty,
        });
      }

      // 保存数据
      final widgetData = {
        'weekOffset': _currentWeekOffset,
        'days': weeklyData,
      };

      await HomeWidget.saveWidgetData<String>(
        'calendar_album_weekly_data_${widgetId}',
        jsonEncode(widgetData),
      );

      debugPrint('同步每周相册数据完成');
    } catch (e) {
      debugPrint('同步数据失败: $e');
    }
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
  Widget _buildPreview(WidgetConfig config) {
    final primaryColor = config.getColor('primary')?.currentValue ?? const Color(0xFF5A9E9A);
    final accentColor = config.getColor('accent')?.currentValue ?? Colors.white;
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
            '一日一拍',
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // 周信息
          Text(
            '第 45 周・11月 3 - 11月 9',
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
    final l10n = CalendarAlbumLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('配置每周相册小组件'),
        actions: [
          TextButton(
            onPressed: _saveAndFinish,
            child: const Text('完成', style: TextStyle(color: Colors.white)),
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
                            '配置说明',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '每周相册小组件会显示一周的照片日记。\n配置后可在小组件上点击具体日期快速查看或添加日记。',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 主题配置编辑器
                  Text(
                    '小组件样式',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  WidgetConfigEditor(
                    config: _widgetConfig,
                    onConfigChanged: (newConfig) {
                      setState(() {
                        _widgetConfig = newConfig;
                      });
                    },
                    previewBuilder: (config) => _buildPreview(config),
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
