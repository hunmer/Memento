import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../activity_plugin.dart';
import '../models/activity_weekly_widget_config.dart';
import '../models/activity_weekly_widget_data.dart';
import '../services/activity_widget_service.dart';
import '../../../widgets/widget_config_editor/index.dart';

/// 周视图活动列表小组件配置界面
///
/// 提供实时预览、双色配置和透明度调节功能
class ActivityWeeklyConfigScreen extends StatefulWidget {
  /// 小组件ID（Android appWidgetId）
  final int widgetId;

  const ActivityWeeklyConfigScreen({
    required this.widgetId,
    super.key,
  });

  @override
  State<ActivityWeeklyConfigScreen> createState() =>
      _ActivityWeeklyConfigScreenState();
}

class _ActivityWeeklyConfigScreenState
    extends State<ActivityWeeklyConfigScreen> {
  late WidgetConfig _widgetConfig;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeConfig();
    _loadSavedConfig();
  }

  /// 初始化默认配置
  void _initializeConfig() {
    _widgetConfig = WidgetConfig(
      colors: [
        const ColorConfig(
          key: 'primary',
          label: '背景色',
          defaultValue: Color(0xFFEFF7F0),
          currentValue: Color(0xFFEFF7F0),
        ),
        const ColorConfig(
          key: 'accent',
          label: '强调色',
          defaultValue: Color(0xFF607afb),
          currentValue: Color(0xFF607afb),
        ),
      ],
      opacity: 0.95,
    );
  }

  /// 加载已保存的配置
  Future<void> _loadSavedConfig() async {
    try {
      // 加载背景色
      final primaryColorStr = await HomeWidget.getWidgetData<String>(
        'activity_weekly_primary_color_${widget.widgetId}',
      );

      // 加载强调色
      final accentColorStr = await HomeWidget.getWidgetData<String>(
        'activity_weekly_accent_color_${widget.widgetId}',
      );

      // 加载透明度
      final opacityStr = await HomeWidget.getWidgetData<String>(
        'activity_weekly_opacity_${widget.widgetId}',
      );

      if (mounted) {
        setState(() {
          // 解析并设置背景色
          if (primaryColorStr != null) {
            final colorValue = int.tryParse(primaryColorStr);
            if (colorValue != null) {
              _widgetConfig =
                  _widgetConfig.updateColor('primary', Color(colorValue));
            }
          }

          // 解析并设置强调色
          if (accentColorStr != null) {
            final colorValue = int.tryParse(accentColorStr);
            if (colorValue != null) {
              _widgetConfig =
                  _widgetConfig.updateColor('accent', Color(colorValue));
            }
          }

          // 解析并设置透明度
          if (opacityStr != null) {
            final opacity = double.tryParse(opacityStr);
            if (opacity != null) {
              _widgetConfig = _widgetConfig.copyWith(opacity: opacity);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('加载配置失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('配置周视图小组件')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('配置周视图小组件'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: WidgetConfigEditor(
        widgetSize: WidgetSize.extraLarge,
        initialConfig: _widgetConfig,
        onConfigChanged: (newConfig) {
          setState(() => _widgetConfig = newConfig);
        },
        previewBuilder: (context, config) => _buildPreview(config),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveAndFinish,
        icon: const Icon(Icons.check),
        label: const Text('保存'),
      ),
    );
  }

  /// 构建预览组件
  Widget _buildPreview(WidgetConfig config) {
    final primaryColor =
        config.getColor('primary') ?? const Color(0xFFEFF7F0);
    final accentColor =
        config.getColor('accent') ?? const Color(0xFF607afb);

    return Container(
      width: 200,
      height: 140,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(config.opacity),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 周标题
          Row(
            children: [
              Icon(Icons.chevron_left, size: 16, color: accentColor),
              const SizedBox(width: 4),
              Text(
                '第1周 1.01-1.07',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),

          // 热力图模拟（简化版）
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(4),
              child: Center(
                child: Text(
                  '热力图',
                  style: TextStyle(
                    color: accentColor.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 标签示例
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  border: Border.all(color: accentColor, width: 1.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '示例标签 2時30分',
                style: TextStyle(
                  color: accentColor.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 保存配置并完成
  Future<void> _saveAndFinish() async {
    setState(() => _isSaving = true);

    try {
      final primaryColor =
          _widgetConfig.getColor('primary') ?? const Color(0xFFEFF7F0);
      final accentColor =
          _widgetConfig.getColor('accent') ?? const Color(0xFF607afb);
      final opacity = _widgetConfig.opacity;

      debugPrint('ActivityWeeklyConfig: 保存配置 widgetId=${widget.widgetId}');
      debugPrint('ActivityWeeklyConfig: primaryColor=${primaryColor.value}, accentColor=${accentColor.value}, opacity=$opacity');

      // 保存颜色配置（使用String类型）
      await HomeWidget.saveWidgetData<String>(
        'activity_weekly_primary_color_${widget.widgetId}',
        primaryColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'activity_weekly_accent_color_${widget.widgetId}',
        accentColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'activity_weekly_opacity_${widget.widgetId}',
        opacity.toString(),
      );

      // 生成初始数据
      final activityPlugin = ActivityPlugin.instance;
      final widgetService = ActivityWidgetService(activityPlugin);
      final weekData = await widgetService.calculateWeekData(0); // 本周

      // 保存完整数据
      final config = ActivityWeeklyWidgetConfig(
        widgetId: widget.widgetId,
        backgroundColor: primaryColor,
        accentColor: accentColor,
        opacity: opacity,
        currentWeekOffset: 0,
      );

      await _syncDataToWidget(config, weekData);

      debugPrint('ActivityWeeklyConfig: 数据已保存，准备调用 updateWidget');

      // 添加短暂延迟确保数据已写入 SharedPreferences
      await Future.delayed(const Duration(milliseconds: 100));

      // 更新小组件
      final result = await HomeWidget.updateWidget(
        name: 'ActivityWeeklyWidgetProvider',
        iOSName: 'ActivityWeeklyWidget',
        qualifiedAndroidName:
            'github.hunmer.memento.widgets.providers.ActivityWeeklyWidgetProvider',
      );

      debugPrint('ActivityWeeklyConfig: updateWidget result=$result');

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('保存配置失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// 同步数据到小组件
  Future<void> _syncDataToWidget(
    ActivityWeeklyWidgetConfig config,
    ActivityWeeklyData data,
  ) async {
    final widgetData = {
      'widgetId': widget.widgetId,
      'config': config.toJson(),
      'data': data.toJson(),
    };

    await HomeWidget.saveWidgetData<String>(
      'activity_weekly_data_${widget.widgetId}',
      jsonEncode(widgetData),
    );
  }
}
