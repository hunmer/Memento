import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../habits_plugin.dart';
import '../models/habit.dart';
import '../../../widgets/widget_config_editor/index.dart';

/// 习惯计时器选择器界面（用于小组件配置）
///
/// 功能：
/// 1. 选择要计时的习惯
/// 2. 配置小组件颜色主题（背景色、文字色、按钮色）
/// 3. 调整透明度
/// 4. 实时预览小组件效果
class HabitTimerSelectorScreen extends StatefulWidget {
  /// 小组件ID（Android appWidgetId）
  final int? widgetId;

  const HabitTimerSelectorScreen({
    super.key,
    this.widgetId,
  });

  @override
  State<HabitTimerSelectorScreen> createState() =>
      _HabitTimerSelectorScreenState();
}

class _HabitTimerSelectorScreenState extends State<HabitTimerSelectorScreen> {
  final HabitsPlugin _habitsPlugin = HabitsPlugin.instance;
  String? _selectedHabitId;
  late WidgetConfig _widgetConfig;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 初始化默认配置
    _widgetConfig = WidgetConfig(
      colors: [
        ColorConfig(
          key: 'primary',
          label: '背景色',
          defaultValue: const Color(0xFFF3F4F6), // Light gray
          currentValue: const Color(0xFFF3F4F6),
        ),
        ColorConfig(
          key: 'accent',
          label: '文字色',
          defaultValue: const Color(0xFF1F2937), // Dark gray
          currentValue: const Color(0xFF1F2937),
        ),
        ColorConfig(
          key: 'button',
          label: '按钮色',
          defaultValue: const Color(0xFF10B981), // Emerald green
          currentValue: const Color(0xFF10B981),
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
      // 加载习惯ID
      final savedHabitId = await HomeWidget.getWidgetData<String>(
        'flutter.habit_timer_habit_id_${widget.widgetId}',
      );
      if (savedHabitId != null) {
        _selectedHabitId = savedHabitId;
      }

      // 加载背景色
      final primaryColorStr = await HomeWidget.getWidgetData<String>(
        'flutter.habit_timer_primary_color_${widget.widgetId}',
      );
      if (primaryColorStr != null) {
        final colorValue = int.tryParse(primaryColorStr);
        if (colorValue != null) {
          _widgetConfig =
              _widgetConfig.updateColor('primary', Color(colorValue));
        }
      }

      // 加载文字色
      final accentColorStr = await HomeWidget.getWidgetData<String>(
        'flutter.habit_timer_accent_color_${widget.widgetId}',
      );
      if (accentColorStr != null) {
        final colorValue = int.tryParse(accentColorStr);
        if (colorValue != null) {
          _widgetConfig =
              _widgetConfig.updateColor('accent', Color(colorValue));
        }
      }

      // 加载按钮色
      final buttonColorStr = await HomeWidget.getWidgetData<String>(
        'flutter.habit_timer_button_color_${widget.widgetId}',
      );
      if (buttonColorStr != null) {
        final colorValue = int.tryParse(buttonColorStr);
        if (colorValue != null) {
          _widgetConfig =
              _widgetConfig.updateColor('button', Color(colorValue));
        }
      }

      // 加载透明度
      final opacityStr = await HomeWidget.getWidgetData<String>(
        'flutter.habit_timer_opacity_${widget.widgetId}',
      );
      if (opacityStr != null) {
        final opacity = double.tryParse(opacityStr);
        if (opacity != null) {
          _widgetConfig = _widgetConfig.copyWith(opacity: opacity);
        }
      }
    } catch (e) {
      debugPrint('加载配置失败: $e');
    }

    setState(() => _isLoading = false);
  }

  /// 获取选中的习惯
  Habit? _getSelectedHabit() {
    if (_selectedHabitId == null) return null;
    try {
      return _habitsPlugin
          .getHabitController()
          .getHabits()
          .firstWhere((habit) => habit.id == _selectedHabitId);
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

    final habits = _habitsPlugin.getHabitController().getHabits();

    return Scaffold(
      appBar: AppBar(
        title: const Text('配置习惯计时器小组件'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: habits.isEmpty
          ? _buildEmptyState()
          : WidgetConfigEditor(
              widgetSize: WidgetSize.medium,
              initialConfig: _widgetConfig,
              previewTitle: '计时器预览',
              onConfigChanged: (config) {
                setState(() => _widgetConfig = config);
              },
              previewBuilder: _buildPreview,
              customConfigWidgets: [
                _buildHabitSelector(),
              ],
            ),
      bottomNavigationBar: _selectedHabitId != null
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
            Icons.auto_awesome,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无习惯',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请先在习惯插件中创建习惯',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建习惯选择器
  Widget _buildHabitSelector() {
    final habits = _habitsPlugin.getHabitController().getHabits();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '选择习惯',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              final isSelected = _selectedHabitId == habit.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedHabitId = habit.id;
                  });
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 习惯图标
                      if (habit.icon != null)
                        Icon(
                          IconData(
                            int.parse(habit.icon!),
                            fontFamily: 'MaterialIcons',
                          ),
                          size: 32,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[600],
                        )
                      else
                        Icon(
                          Icons.auto_awesome,
                          size: 32,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[600],
                        ),
                      const SizedBox(height: 8),
                      // 习惯名称
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          habit.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// 构建实时预览
  Widget _buildPreview(BuildContext context, WidgetConfig config) {
    final primaryColor = config.getColor('primary') ?? const Color(0xFFF3F4F6);
    final accentColor = config.getColor('accent') ?? const Color(0xFF1F2937);
    final buttonColor = config.getColor('button') ?? const Color(0xFF10B981);
    final opacity = config.opacity;

    final selectedHabit = _getSelectedHabit();

    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(40),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：图标 + 名称
          Row(
            children: [
              // 图标容器
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: selectedHabit?.icon != null
                      ? Icon(
                          IconData(
                            int.parse(selectedHabit!.icon!),
                            fontFamily: 'MaterialIcons',
                          ),
                          size: 16,
                          color: accentColor,
                        )
                      : Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: accentColor,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              // 名称
              Expanded(
                child: Text(
                  selectedHabit?.title ?? '背单词',
                  style: TextStyle(
                    fontSize: 12,
                    color: accentColor.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // 中央：时间显示
          Expanded(
            child: Center(
              child: Text(
                _formatTime(selectedHabit?.durationMinutes ?? 25),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: accentColor,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          // 底部：播放按钮
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: buttonColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时间显示
  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '$hours:${mins.toString().padLeft(2, '0')}:00';
    } else {
      return '${mins.toString().padLeft(2, '0')}:00';
    }
  }

  /// 保存配置并完成
  Future<void> _saveAndFinish() async {
    if (_selectedHabitId == null || widget.widgetId == null) return;

    try {
      final selectedHabit = _getSelectedHabit();
      if (selectedHabit == null) return;

      // 1. 获取配置值
      final primaryColor = _widgetConfig.getColor('primary') ?? const Color(0xFFF3F4F6);
      final accentColor = _widgetConfig.getColor('accent') ?? const Color(0xFF1F2937);
      final buttonColor = _widgetConfig.getColor('button') ?? const Color(0xFF10B981);
      final opacity = _widgetConfig.opacity;

      // 2. 保存习惯信息
      await HomeWidget.saveWidgetData<String>(
        'flutter.habit_timer_habit_id_${widget.widgetId}',
        _selectedHabitId!,
      );

      await HomeWidget.saveWidgetData<String>(
        'flutter.habit_timer_habit_name_${widget.widgetId}',
        selectedHabit.title,
      );

      await HomeWidget.saveWidgetData<String>(
        'flutter.habit_timer_habit_icon_${widget.widgetId}',
        selectedHabit.icon ?? '',
      );

      await HomeWidget.saveWidgetData<String>(
        'flutter.habit_timer_duration_minutes_${widget.widgetId}',
        selectedHabit.durationMinutes.toString(),
      );

      // 3. 保存颜色配置
      await HomeWidget.saveWidgetData<String>(
        'flutter.habit_timer_primary_color_${widget.widgetId}',
        primaryColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'flutter.habit_timer_accent_color_${widget.widgetId}',
        accentColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'flutter.habit_timer_button_color_${widget.widgetId}',
        buttonColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'flutter.habit_timer_opacity_${widget.widgetId}',
        opacity.toString(),
      );

      // 4. 同步习惯数据到小组件（供Android端查找）
      await _syncHabitToWidget();

      // 等待 SharedPreferences 数据写入完成
      // HomeWidget.saveWidgetData 使用 apply() 是异步的，需要等待
      await Future.delayed(const Duration(milliseconds: 200));

      // 5. 更新小组件
      debugPrint('正在更新习惯计时器小组件...');
      await HomeWidget.updateWidget(
        name: 'HabitTimerWidgetProvider',
        iOSName: 'HabitTimerWidgetProvider',
        qualifiedAndroidName:
            'github.hunmer.memento.widgets.providers.HabitTimerWidgetProvider',
      );
      debugPrint('HabitTimerWidgetProvider 更新完成');

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('保存配置失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  /// 同步习惯数据到小组件
  Future<void> _syncHabitToWidget() async {
    try {
      final habits = _habitsPlugin.getHabitController().getHabits();

      // 构建习惯数据（包含所有习惯，供Android端查找）
      final habitsData = habits.map((habit) {
        // 获取计时器状态
        final timerData =
            _habitsPlugin.timerController.getTimerData(habit.id);
        final isRunning =
            _habitsPlugin.timerController.isHabitTiming(habit.id);

        return {
          'id': habit.id,
          'title': habit.title,
          'durationMinutes': habit.durationMinutes,
          'icon': habit.icon,
          'isRunning': isRunning,
          'elapsedSeconds': timerData?['elapsedSeconds'] ?? 0,
          'isCountdown': timerData?['isCountdown'] ?? true,
        };
      }).toList();

      // 保存为 JSON 字符串
      await HomeWidget.saveWidgetData<String>(
        'flutter.habit_timer_widget_data',
        jsonEncode({'habits': habitsData}),
      );
    } catch (e) {
      debugPrint('同步习惯数据失败: $e');
    }
  }
}
