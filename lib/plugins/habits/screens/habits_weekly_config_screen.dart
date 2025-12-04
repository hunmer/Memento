import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../habits_plugin.dart';
import '../models/habit.dart';
import '../models/habits_weekly_widget_config.dart';
import '../models/habits_weekly_widget_data.dart';
import '../services/habits_widget_service.dart';
import '../../../widgets/widget_config_editor/index.dart';

/// 习惯周视图小组件配置界面
///
/// 功能:
/// 1. 按技能分组选择要展示的习惯(多选)
/// 2. 配置小组件颜色主题(背景色、强调色)
/// 3. 调整透明度
/// 4. 实时预览周视图效果
class HabitsWeeklyConfigScreen extends StatefulWidget {
  /// 小组件ID(Android appWidgetId)
  final int widgetId;

  const HabitsWeeklyConfigScreen({
    required this.widgetId,
    super.key,
  });

  @override
  State<HabitsWeeklyConfigScreen> createState() =>
      _HabitsWeeklyConfigScreenState();
}

class _HabitsWeeklyConfigScreenState extends State<HabitsWeeklyConfigScreen> {
  final HabitsPlugin _habitsPlugin = HabitsPlugin.instance;
  final Set<String> _selectedHabitIds = {};
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
          key: 'background',
          label: '背景色',
          defaultValue: Color(0xFFF5F5F5),
          currentValue: Color(0xFFF5F5F5),
        ),
        const ColorConfig(
          key: 'accent',
          label: '强调色',
          defaultValue: Color(0xFF607AFB),
          currentValue: Color(0xFF607AFB),
        ),
      ],
      opacity: 0.95,
    );
  }

  /// 加载已保存的配置
  Future<void> _loadSavedConfig() async {
    try {
      // 加载已选择的习惯ID列表
      final savedHabitIdsStr = await HomeWidget.getWidgetData<String>(
        'habits_weekly_selected_ids_${widget.widgetId}',
      );
      if (savedHabitIdsStr != null && savedHabitIdsStr.isNotEmpty) {
        final List<dynamic> habitIdsList = jsonDecode(savedHabitIdsStr);
        _selectedHabitIds.addAll(habitIdsList.cast<String>());
      }

      // 加载背景色
      final backgroundColorStr = await HomeWidget.getWidgetData<String>(
        'habits_weekly_background_color_${widget.widgetId}',
      );
      if (backgroundColorStr != null) {
        final colorValue = int.tryParse(backgroundColorStr);
        if (colorValue != null) {
          _widgetConfig =
              _widgetConfig.updateColor('background', Color(colorValue));
        }
      }

      // 加载强调色
      final accentColorStr = await HomeWidget.getWidgetData<String>(
        'habits_weekly_accent_color_${widget.widgetId}',
      );
      if (accentColorStr != null) {
        final colorValue = int.tryParse(accentColorStr);
        if (colorValue != null) {
          _widgetConfig =
              _widgetConfig.updateColor('accent', Color(colorValue));
        }
      }

      // 加载透明度
      final opacityStr = await HomeWidget.getWidgetData<String>(
        'habits_weekly_opacity_${widget.widgetId}',
      );
      if (opacityStr != null) {
        final opacity = double.tryParse(opacityStr);
        if (opacity != null) {
          _widgetConfig = _widgetConfig.copyWith(opacity: opacity);
        }
      }
    } catch (e) {
      debugPrint('加载配置失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 按技能分组习惯
  Map<String, List<Habit>> _groupHabitsBySkill() {
    final habits = _habitsPlugin.getHabitController().getHabits();
    final skillController = _habitsPlugin.getSkillController();
    final Map<String, List<Habit>> grouped = {};

    for (final habit in habits) {
      String groupName = '未分类';
      if (habit.skillId != null) {
        try {
          final skill = skillController.getSkillById(habit.skillId!);
          groupName = skill.title;
        } catch (_) {
          // 技能不存在,使用未分类
        }
      }
      grouped.putIfAbsent(groupName, () => []).add(habit);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('配置习惯周视图小组件')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final groupedHabits = _groupHabitsBySkill();

    return Scaffold(
      appBar: AppBar(
        title: const Text('配置习惯周视图小组件'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
      body: groupedHabits.isEmpty
          ? _buildEmptyState()
          : WidgetConfigEditor(
              widgetSize: WidgetSize.extraLarge,
              initialConfig: _widgetConfig,
              previewTitle: '周视图预览',
              onConfigChanged: (config) {
                setState(() => _widgetConfig = config);
              },
              previewBuilder: _buildPreview,
              customConfigWidgets: [
                _buildHabitSelector(groupedHabits),
              ],
            ),
      bottomNavigationBar: _selectedHabitIds.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAndFinish,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isSaving ? '保存中...' : '保存配置',
                    style: const TextStyle(fontSize: 16),
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

  /// 构建习惯选择器(按技能分组)
  Widget _buildHabitSelector(Map<String, List<Habit>> groupedHabits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和已选择数量
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '选择习惯',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '已选择 ${_selectedHabitIds.length} 个',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 按技能分组展示习惯
        ...groupedHabits.entries.map((entry) {
          return _buildSkillGroup(entry.key, entry.value);
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 构建单个技能分组
  Widget _buildSkillGroup(String skillName, List<Habit> habits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            skillName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        // 习惯列表(横向滚动)
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              final isSelected = _selectedHabitIds.contains(habit.id);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedHabitIds.remove(habit.id);
                    } else {
                      _selectedHabitIds.add(habit.id);
                    }
                  });
                },
                child: Container(
                  width: 80,
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
                      // 选择指示器
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        )
                      else
                        const SizedBox(height: 20),
                      const SizedBox(height: 4),
                      // 习惯图标
                      if (habit.icon != null)
                        Icon(
                          IconData(
                            int.parse(habit.icon!),
                            fontFamily: 'MaterialIcons',
                          ),
                          size: 24,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[600],
                        )
                      else
                        Icon(
                          Icons.auto_awesome,
                          size: 24,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[600],
                        ),
                      const SizedBox(height: 4),
                      // 习惯名称
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          habit.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
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

  /// 构建预览组件
  Widget _buildPreview(BuildContext context, WidgetConfig config) {
    final backgroundColor =
        config.getColor('background') ?? const Color(0xFFF5F5F5);
    final accentColor =
        config.getColor('accent') ?? const Color(0xFF607AFB);

    return Container(
      width: 250,
      height: 240,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(config.opacity),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 周标题
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chevron_left, size: 16, color: accentColor),
              const SizedBox(width: 4),
              Text(
                '第1周 01.06-01.12',
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

          // 星期头部
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['一', '二', '三', '四', '五', '六', '日']
                .map((day) => SizedBox(
                      width: 28,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: accentColor.withOpacity(0.6),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),

          // 习惯列表(模拟)
          Expanded(
            child: ListView(
              children: [
                _buildPreviewHabitItem('阅读', accentColor, [30, 0, 45, 60, 0, 90, 30]),
                const SizedBox(height: 4),
                _buildPreviewHabitItem('运动', accentColor, [60, 45, 0, 60, 45, 0, 60]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建预览习惯项
  Widget _buildPreviewHabitItem(
    String title,
    Color accentColor,
    List<int> dailyMinutes,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Checkbox(装饰性)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              border: Border.all(color: accentColor, width: 1.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          // 习惯标题
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: accentColor.withOpacity(0.8),
              ),
            ),
          ),
          // 每日时长
          ...dailyMinutes.map((minutes) {
            return Container(
              width: 26,
              height: 20,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: minutes > 0
                    ? accentColor.withOpacity(0.7)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  minutes > 0 ? '$minutes' : '',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 保存配置并完成
  Future<void> _saveAndFinish() async {
    if (_selectedHabitIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个习惯')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final backgroundColor =
          _widgetConfig.getColor('background') ?? const Color(0xFFF5F5F5);
      final accentColor =
          _widgetConfig.getColor('accent') ?? const Color(0xFF607AFB);
      final opacity = _widgetConfig.opacity;

      debugPrint('习惯周小组件配置保存开始: widgetId=${widget.widgetId}');
      debugPrint('选中的习惯IDs: $_selectedHabitIds');

      // 保存选中的习惯ID列表
      await HomeWidget.saveWidgetData<String>(
        'habits_weekly_selected_ids_${widget.widgetId}',
        jsonEncode(_selectedHabitIds.toList()),
      );

      // 保存颜色配置(使用String类型)
      await HomeWidget.saveWidgetData<String>(
        'habits_weekly_background_color_${widget.widgetId}',
        backgroundColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'habits_weekly_accent_color_${widget.widgetId}',
        accentColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'habits_weekly_opacity_${widget.widgetId}',
        opacity.toString(),
      );

      // 将当前 widgetId 添加到全局列表中
      final existingWidgetIdsStr = await HomeWidget.getWidgetData<String>(
        'habits_weekly_widget_ids',
      ) ?? '[]';
      final existingWidgetIds = List<int>.from(
        jsonDecode(existingWidgetIdsStr) as List,
      );
      if (!existingWidgetIds.contains(widget.widgetId)) {
        existingWidgetIds.add(widget.widgetId);
        await HomeWidget.saveWidgetData<String>(
          'habits_weekly_widget_ids',
          jsonEncode(existingWidgetIds),
        );
        debugPrint('已添加小组件ID到列表: ${widget.widgetId}, 当前列表: $existingWidgetIds');
      }

      // 生成初始周数据
      final widgetService = HabitsWidgetService(_habitsPlugin);
      final weekData = await widgetService.calculateWeekData(
        _selectedHabitIds.toList(),
        0, // 本周
      );

      debugPrint('计算周数据完成: year=${weekData.year}, week=${weekData.week}, habitItems=${weekData.habitItems.length}');

      // 保存完整配置和数据
      final config = HabitsWeeklyWidgetConfig(
        widgetId: widget.widgetId,
        selectedHabitIds: _selectedHabitIds.toList(),
        backgroundColor: backgroundColor.value.toString(),
        accentColor: accentColor.value.toString(),
        opacity: opacity,
        weekOffset: 0,
      );

      await _syncDataToWidget(config, weekData);

      debugPrint('数据同步到小组件完成，开始更新小组件...');

      // 添加短暂延迟确保数据已写入 SharedPreferences
      await Future.delayed(const Duration(milliseconds: 100));

      // 更新小组件
      await HomeWidget.updateWidget(
        name: 'HabitsWeeklyWidgetProvider',
        iOSName: 'HabitsWeeklyWidget',
        qualifiedAndroidName:
            'github.hunmer.memento.widgets.providers.HabitsWeeklyWidgetProvider',
      );

      debugPrint('小组件更新请求已发送');

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      debugPrint('保存配置失败: $e');
      debugPrint('堆栈: $stackTrace');
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
    HabitsWeeklyWidgetConfig config,
    HabitsWeeklyData data,
  ) async {
    final widgetData = {
      'widgetId': widget.widgetId,
      'config': config.toMap(),
      'data': data.toMap(),
    };

    final jsonStr = jsonEncode(widgetData);
    debugPrint('保存小组件数据到 habits_weekly_data_${widget.widgetId}');
    debugPrint('数据长度: ${jsonStr.length} 字节');
    debugPrint('数据内容: $jsonStr');

    await HomeWidget.saveWidgetData<String>(
      'habits_weekly_data_${widget.widgetId}',
      jsonStr,
    );

    debugPrint('HomeWidget.saveWidgetData 调用完成');
  }
}
