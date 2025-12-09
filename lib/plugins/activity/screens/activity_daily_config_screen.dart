import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'package:Memento/plugins/activity/models/activity_daily_widget_config.dart';
import 'package:Memento/plugins/activity/models/activity_daily_widget_data.dart';
import 'package:Memento/plugins/activity/services/activity_widget_service.dart';
import 'package:Memento/widgets/widget_config_editor/index.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 日视图活动列表小组件配置界面
///
/// 提供实时预览、双色配置和透明度调节功能
class ActivityDailyConfigScreen extends StatefulWidget {
  /// 小组件ID（Android appWidgetId）
  final int widgetId;

  const ActivityDailyConfigScreen({
    required this.widgetId,
    super.key,
  });

  @override
  State<ActivityDailyConfigScreen> createState() =>
      _ActivityDailyConfigScreenState();
}

class _ActivityDailyConfigScreenState
    extends State<ActivityDailyConfigScreen> {
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
        'activity_daily_primary_color_${widget.widgetId}',
      );

      // 加载强调色
      final accentColorStr = await HomeWidget.getWidgetData<String>(
        'activity_daily_accent_color_${widget.widgetId}',
      );

      // 加载透明度
      final opacityStr = await HomeWidget.getWidgetData<String>(
        'activity_daily_opacity_${widget.widgetId}',
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

  /// 保存配置
  Future<void> _saveConfig() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final primaryColor =
          _widgetConfig.getColor('primary') ?? const Color(0xFFEFF7F0);
      final accentColor =
          _widgetConfig.getColor('accent') ?? const Color(0xFF607afb);
      final opacity = _widgetConfig.opacity;

      debugPrint('ActivityDailyConfig: 保存配置 widgetId=${widget.widgetId}');
      debugPrint('ActivityDailyConfig: primaryColor=${primaryColor.value}, accentColor=${accentColor.value}, opacity=$opacity');

      // 保存颜色配置（使用String类型）
      await HomeWidget.saveWidgetData<String>(
        'activity_daily_primary_color_${widget.widgetId}',
        primaryColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'activity_daily_accent_color_${widget.widgetId}',
        accentColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'activity_daily_opacity_${widget.widgetId}',
        opacity.toString(),
      );

      // 生成完整数据并保存
      final config = ActivityDailyWidgetConfig(
        widgetId: widget.widgetId,
        backgroundColor: primaryColor,
        accentColor: accentColor,
        opacity: opacity,
      );

      await HomeWidget.saveWidgetData<String>(
        'activity_daily_config_${widget.widgetId}',
        jsonEncode(config.toJson()),
      );

      // 生成初始数据
      final activityPlugin = ActivityPlugin.instance;
      final widgetService = ActivityWidgetService(activityPlugin);
      final dayData = await widgetService.calculateDayData(0); // 今天

      await _syncDataToWidget(config, dayData);

      // 将 widgetId 添加到已配置列表中
      await _registerWidgetId(widget.widgetId);

      debugPrint('ActivityDailyConfig: 数据已保存，准备调用 updateWidget');

      // 添加短暂延迟确保数据已写入 SharedPreferences
      await Future.delayed(const Duration(milliseconds: 100));

      // 更新小组件
      final result = await HomeWidget.updateWidget(
        name: 'ActivityDailyWidgetProvider',
        iOSName: 'ActivityDailyWidget',
        qualifiedAndroidName:
            'github.hunmer.memento.widgets.providers.ActivityDailyWidgetProvider',
      );

      debugPrint('ActivityDailyConfig: updateWidget result=$result');

      if (mounted) {
        ToastService.instance.showToast('配置已保存');
      }
    } catch (e) {
      debugPrint('保存配置失败: $e');
      if (mounted) {
        ToastService.instance.showToast('保存失败: $e');
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// 注册小组件ID到已配置列表
  Future<void> _registerWidgetId(int widgetId) async {
    // 获取现有列表
    final existingIdsJson = await HomeWidget.getWidgetData<String>(
      'activity_daily_widget_ids',
    );

    List<int> widgetIds = [];
    if (existingIdsJson != null && existingIdsJson.isNotEmpty) {
      try {
        widgetIds = List<int>.from(jsonDecode(existingIdsJson) as List);
      } catch (e) {
        debugPrint('Failed to parse existing widget IDs, creating new list: $e');
      }
    }

    // 添加新 widgetId（如果不存在）
    if (!widgetIds.contains(widgetId)) {
      widgetIds.add(widgetId);
      debugPrint('ActivityDailyConfig: Registered widgetId $widgetId (total: ${widgetIds.length})');
    } else {
      debugPrint('ActivityDailyConfig: widgetId $widgetId already registered');
    }

    // 保存更新后的列表
    await HomeWidget.saveWidgetData<String>(
      'activity_daily_widget_ids',
      jsonEncode(widgetIds),
    );

    debugPrint('ActivityDailyConfig: Saved widget IDs list: $widgetIds');
  }

  /// 同步数据到小组件
  Future<void> _syncDataToWidget(
    ActivityDailyWidgetConfig config,
    ActivityDailyWidgetData data,
  ) async {
    final widgetData = {
      'widgetId': widget.widgetId,
      'config': config.toJson(),
      'data': data.toJson(),
    };

    await HomeWidget.saveWidgetData<String>(
      'activity_daily_data_${widget.widgetId}',
      jsonEncode(widgetData),
    );
  }

  /// 构建预览组件
  Widget _buildPreview(WidgetConfig config) {
    final primaryColor =
        config.getColor('primary') ?? const Color(0xFFEFF7F0);
    final accentColor =
        config.getColor('accent') ?? const Color(0xFF607afb);

    return Container(
      width: 220,
      height: 140,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(config.opacity),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // 左侧：24小时时间轴
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // 时间轴标题
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('activity_morning'.tr, style: TextStyle(fontSize: 10, color: accentColor)),
                    Text('activity_afternoon'.tr, style: TextStyle(fontSize: 10, color: accentColor)),
                  ],
                ),
                const SizedBox(height: 4),
                // 时间网格（简化版）
                Expanded(
                  child: ListView.builder(
                    itemCount: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final hour = index;
                      final isWorkHour = hour >= 8 && hour <= 18;
                      final hasActivity = hour % 3 == 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isWorkHour
                                      ? accentColor.withOpacity(0.3)
                                      : accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$hour',
                              style: TextStyle(
                                fontSize: 8,
                                color: accentColor.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (hasActivity)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              )
                            else
                              const SizedBox(width: 4, height: 4),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 右侧：圆环图和统计信息
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // 日期标题
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chevron_left, size: 14, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      '5月28日',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 14, color: accentColor),
                  ],
                ),
                const SizedBox(height: 4),
                // 圆环进度图（简化）
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withOpacity(0.3),
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '83%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // 活动标签示例
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPreviewTag(
                        icon: '💤',
                        label: '睡眠',
                        duration: '8.3h',
                        color: const Color(0xFFa2e0b5),
                        accentColor: accentColor,
                      ),
                      _buildPreviewTag(
                        icon: '🐮',
                        label: '工作',
                        duration: '6.2h',
                        color: const Color(0xFFfdd8d8),
                        accentColor: accentColor,
                      ),
                      _buildPreviewTag(
                        icon: '🥳',
                        label: '娱乐',
                        duration: '1.8h',
                        color: const Color(0xFFfcd34d),
                        accentColor: accentColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建预览标签项
  Widget _buildPreviewTag({
    required String icon,
    required String label,
    required String duration,
    required Color color,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            icon,
            style: const TextStyle(fontSize: 8),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: accentColor.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            duration,
            style: TextStyle(
              fontSize: 8,
              color: accentColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('activity_configDailyWidget'.tr)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('activity_configDailyWidget'.tr),
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
        widgetSize: WidgetSize.huge,
        initialConfig: _widgetConfig,
        onConfigChanged: (newConfig) {
          setState(() => _widgetConfig = newConfig);
        },
        previewBuilder: (context, config) => _buildPreview(config),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveConfig,
        icon: const Icon(Icons.check),
        label: Text('activity_save'.tr),
      ),
    );
  }
}
