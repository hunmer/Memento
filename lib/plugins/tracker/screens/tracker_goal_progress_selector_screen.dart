import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';
import 'package:Memento/widgets/widget_config_editor/index.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 目标进度条小组件选择器界面(用于小组件配置)
///
/// 提供实时预览、颜色配置和透明度调节功能。
/// 预览样式：白色卡片 + 进度条
class TrackerGoalProgressSelectorScreen extends StatefulWidget {
  /// 小组件ID(Android appWidgetId)
  final int? widgetId;

  const TrackerGoalProgressSelectorScreen({
    super.key,
    this.widgetId,
  });

  @override
  State<TrackerGoalProgressSelectorScreen> createState() =>
      _TrackerGoalProgressSelectorScreenState();
}

class _TrackerGoalProgressSelectorScreenState
    extends State<TrackerGoalProgressSelectorScreen> {
  final TrackerPlugin _trackerPlugin = TrackerPlugin.instance;
  String? _selectedGoalId;
  late WidgetConfig _widgetConfig;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 初始化默认配置（白色背景）
    _widgetConfig = WidgetConfig(
      colors: [
        ColorConfig(
          key: 'primary',
          label: '背景色',
          defaultValue: Colors.white,
          currentValue: Colors.white,
        ),
        ColorConfig(
          key: 'accent',
          label: '进度条颜色',
          defaultValue: const Color(0xFF64B5F6), // 蓝色
          currentValue: const Color(0xFF64B5F6),
        ),
      ],
      opacity: 1.0,
    );
    _loadSavedConfig();
  }

  /// 加载已保存的配置
  Future<void> _loadSavedConfig() async {
    if (widget.widgetId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 加载目标ID
      final savedGoalId = await HomeWidget.getWidgetData<String>(
        'tracker_goal_id_${widget.widgetId}',
      );
      if (savedGoalId != null) {
        _selectedGoalId = savedGoalId;
      }

      // 加载背景色
      final savedColorStr = await HomeWidget.getWidgetData<String>(
        'tracker_widget_primary_color_${widget.widgetId}',
      );
      if (savedColorStr != null) {
        final colorValue = int.tryParse(savedColorStr);
        if (colorValue != null) {
          _widgetConfig =
              _widgetConfig.updateColor('primary', Color(colorValue));
        }
      }

      // 加载进度条颜色
      final savedAccentColorStr = await HomeWidget.getWidgetData<String>(
        'tracker_widget_accent_color_${widget.widgetId}',
      );
      if (savedAccentColorStr != null) {
        final colorValue = int.tryParse(savedAccentColorStr);
        if (colorValue != null) {
          _widgetConfig =
              _widgetConfig.updateColor('accent', Color(colorValue));
        }
      }

      // 加载透明度
      final savedOpacityStr = await HomeWidget.getWidgetData<String>(
        'tracker_widget_opacity_${widget.widgetId}',
      );
      if (savedOpacityStr != null) {
        final opacity = double.tryParse(savedOpacityStr);
        if (opacity != null) {
          _widgetConfig = _widgetConfig.copyWith(opacity: opacity);
        }
      }
    } catch (e) {
      debugPrint('加载配置失败: $e');
    }

    setState(() => _isLoading = false);
  }

  /// 获取选中的目标
  Goal? _getSelectedGoal() {
    if (_selectedGoalId == null) return null;
    try {
      return _trackerPlugin.controller.goals
          .firstWhere((goal) => goal.id == _selectedGoalId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final goals = _trackerPlugin.controller.goals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('配置目标进度条小组件'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: goals.isEmpty
          ? _buildEmptyState()
          : WidgetConfigEditor(
              widgetSize: WidgetSize.large,
              initialConfig: _widgetConfig,
              previewTitle: '进度条预览',
              onConfigChanged: (config) {
                setState(() => _widgetConfig = config);
              },
              previewBuilder: _buildPreview,
              customConfigWidgets: [
                _buildGoalSelector(),
              ],
            ),
      bottomNavigationBar: _selectedGoalId != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _saveAndFinish,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '确认配置',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无目标',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请先在目标追踪插件中创建目标',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建预览（进度条样式）
  Widget _buildPreview(BuildContext context, WidgetConfig config) {
    final primaryColor = config.getColor('primary') ?? Colors.white;
    final accentColor = config.getColor('accent') ?? const Color(0xFF64B5F6);
    final selectedGoal = _getSelectedGoal();

    if (selectedGoal == null) {
      return Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey.shade200.withOpacity(config.opacity),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.track_changes, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                '请选择目标',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // 计算进度百分比
    final progress = selectedGoal.targetValue > 0
        ? selectedGoal.currentValue / selectedGoal.targetValue
        : 0.0;
    final progressPercent = (progress * 100).clamp(0, 100).toInt();

    // 渲染进度条样式小组件预览（白色卡片）
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(config.opacity),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：标题 + 加号按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  selectedGoal.name,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(
                  Icons.add,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 中间：大号进度数字
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${selectedGoal.currentValue.toInt()}',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              Text(
                '/${selectedGoal.targetValue.toInt()}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 24,
                  height: 1.0,
                ),
              ),
            ],
          ),

          const Spacer(),

          // 底部：百分比 + 进度条
          Text(
            '$progressPercent%',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建目标选择器
  Widget _buildGoalSelector() {
    final theme = Theme.of(context);
    final goals = _trackerPlugin.controller.goals;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '选择追踪目标',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...goals.map((goal) {
              final isSelected = _selectedGoalId == goal.id;
              // 计算进度百分比
              final progress = goal.currentValue / goal.targetValue;
              final progressPercent = (progress * 100).clamp(0, 100).toInt();

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _onGoalSelected(goal),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.05)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        // 图标
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: goal.iconColor != null
                                ? Color(goal.iconColor!).withAlpha(30)
                                : Colors.blue.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            IconData(
                              int.parse(goal.icon),
                              fontFamily: 'MaterialIcons',
                            ),
                            color: goal.iconColor != null
                                ? Color(goal.iconColor!)
                                : Colors.blue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 目标信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${goal.currentValue.toInt()}/${goal.targetValue.toInt()} ${goal.unitType} ($progressPercent%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 选中标记
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey[400],
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 选中目标
  void _onGoalSelected(Goal goal) {
    setState(() {
      _selectedGoalId = goal.id;
      // 可以选择性地更新进度条颜色为目标的颜色
      if (goal.progressColor != null) {
        _widgetConfig =
            _widgetConfig.updateColor('accent', Color(goal.progressColor!));
      } else if (goal.iconColor != null) {
        _widgetConfig =
            _widgetConfig.updateColor('accent', Color(goal.iconColor!));
      }
    });
  }

  /// 保存配置并关闭界面
  Future<void> _saveAndFinish() async {
    if (_selectedGoalId == null || widget.widgetId == null) {
      Navigator.of(context).pop();
      return;
    }

    try {
      // 保存目标ID
      await HomeWidget.saveWidgetData<String>(
        'tracker_goal_id_${widget.widgetId}',
        _selectedGoalId!,
      );

      // 保存背景色(使用 String 存储,因为 HomeWidget 不支持 int)
      final primaryColor = _widgetConfig.getColor('primary');
      if (primaryColor != null) {
        await HomeWidget.saveWidgetData<String>(
          'tracker_widget_primary_color_${widget.widgetId}',
          primaryColor.value.toString(),
        );
      }

      // 保存进度条颜色(使用 String 存储)
      final accentColor = _widgetConfig.getColor('accent');
      if (accentColor != null) {
        await HomeWidget.saveWidgetData<String>(
          'tracker_widget_accent_color_${widget.widgetId}',
          accentColor.value.toString(),
        );
      }

      // 保存透明度(使用 String 存储)
      await HomeWidget.saveWidgetData<String>(
        'tracker_widget_opacity_${widget.widgetId}',
        _widgetConfig.opacity.toString(),
      );

      // 获取选中的目标
      final selectedGoal = _getSelectedGoal()!;

      // 同步目标数据到小组件
      await _syncGoalToWidget(selectedGoal);

      // 更新小组件（进度条样式）
      await HomeWidget.updateWidget(
        name: 'TrackerGoalProgressWidgetProvider',
        iOSName: 'TrackerGoalProgressWidgetProvider',
        qualifiedAndroidName:
            'github.hunmer.memento.widgets.providers.TrackerGoalProgressWidgetProvider',
      );

      if (mounted) {
        Toast.success('已配置 "${selectedGoal.name}"');

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        Toast.error('配置失败: $e');
      }
    }
  }

  /// 同步目标数据到小组件
  Future<void> _syncGoalToWidget(Goal goal) async {
    try {
      final widgetData = jsonEncode({
        'goals': [
          {
            'id': goal.id,
            'name': goal.name,
            'currentValue': goal.currentValue,
            'targetValue': goal.targetValue,
            'unitType': goal.unitType,
          }
        ],
      });

      await HomeWidget.saveWidgetData<String>(
        'tracker_goal_widget_data',
        widgetData,
      );

      debugPrint(
          '目标数据已同步: ${goal.name}, ${goal.currentValue}/${goal.targetValue} ${goal.unitType}');
    } catch (e) {
      debugPrint('同步目标数据失败: $e');
    }
  }
}
