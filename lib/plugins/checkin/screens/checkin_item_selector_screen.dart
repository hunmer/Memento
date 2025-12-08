import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';
import 'package:Memento/widgets/widget_config_editor/index.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 打卡项目选择器界面（用于小组件配置）
///
/// 提供实时预览、颜色配置和透明度调节功能。
class CheckinItemSelectorScreen extends StatefulWidget {
  /// 小组件ID（Android appWidgetId）
  final int? widgetId;

  const CheckinItemSelectorScreen({
    super.key,
    this.widgetId,
  });

  @override
  State<CheckinItemSelectorScreen> createState() =>
      _CheckinItemSelectorScreenState();
}

class _CheckinItemSelectorScreenState extends State<CheckinItemSelectorScreen> {
  final CheckinPlugin _checkinPlugin = CheckinPlugin.instance;
  String? _selectedItemId;
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
          defaultValue: Colors.purple,
          currentValue: Colors.purple,
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
    _loadSavedConfig();
  }

  /// 加载已保存的配置
  Future<void> _loadSavedConfig() async {
    if (widget.widgetId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 加载打卡项目ID
      final savedItemId = await HomeWidget.getWidgetData<String>(
        'checkin_item_id_${widget.widgetId}',
      );
      if (savedItemId != null) {
        _selectedItemId = savedItemId;
      }

      // 加载背景色（以 String 类型存储）
      final savedColorStr = await HomeWidget.getWidgetData<String>(
        'checkin_widget_primary_color_${widget.widgetId}',
      );
      if (savedColorStr != null) {
        final colorValue = int.tryParse(savedColorStr);
        if (colorValue != null) {
          _widgetConfig = _widgetConfig.updateColor('primary', Color(colorValue));
        }
      }

      // 加载标题色（以 String 类型存储）
      final savedAccentColorStr = await HomeWidget.getWidgetData<String>(
        'checkin_widget_accent_color_${widget.widgetId}',
      );
      if (savedAccentColorStr != null) {
        final colorValue = int.tryParse(savedAccentColorStr);
        if (colorValue != null) {
          _widgetConfig = _widgetConfig.updateColor('accent', Color(colorValue));
        }
      }

      // 加载透明度（以 String 类型存储）
      final savedOpacityStr = await HomeWidget.getWidgetData<String>(
        'checkin_widget_opacity_${widget.widgetId}',
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

  /// 获取选中的打卡项目
  CheckinItem? _getSelectedItem() {
    if (_selectedItemId == null) return null;
    try {
      return _checkinPlugin.checkinItems
          .firstWhere((item) => item.id == _selectedItemId);
    } catch (_) {
      return null;
    }
  }

  /// 获取本月打卡日期列表
  List<int> _getMonthChecks(CheckinItem item) {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final List<int> monthChecks = [];

    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(now.year, now.month, day);
      final records = item.getDateRecords(date);
      if (records.isNotEmpty) {
        monthChecks.add(day);
      }
    }

    return monthChecks;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final items = _checkinPlugin.checkinItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('配置打卡小组件'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : WidgetConfigEditor(
              widgetSize: WidgetSize.large,
              initialConfig: _widgetConfig,
              previewTitle: '月度打卡预览',
              onConfigChanged: (config) {
                setState(() => _widgetConfig = config);
              },
              previewBuilder: _buildPreview,
              customConfigWidgets: [
                _buildItemSelector(),
              ],
            ),
      bottomNavigationBar: _selectedItemId != null
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
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无打卡项目',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请先在打卡插件中创建打卡项目',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建预览
  Widget _buildPreview(BuildContext context, WidgetConfig config) {
    final primaryColor = config.getColor('primary') ?? Colors.purple;
    final selectedItem = _getSelectedItem();

    if (selectedItem == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200.withOpacity(config.opacity),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_note, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                '请选择打卡项目',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // 渲染月度打卡日历
    final now = DateTime.now();
    final monthChecks = _getMonthChecks(selectedItem);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(config.opacity),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  selectedItem.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${now.month}月',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 日历网格
          Expanded(
            child: _buildCalendarGrid(now, monthChecks, primaryColor),
          ),
        ],
      ),
    );
  }

  /// 构建日历网格
  Widget _buildCalendarGrid(DateTime now, List<int> monthChecks, Color primaryColor) {
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday; // 1-7, 周一为1

    // 计算需要的行数
    final totalDays = lastDayOfMonth.day;
    final leadingEmptyDays = firstWeekday - 1; // 前面的空白天数
    final totalCells = leadingEmptyDays + totalDays;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        // 星期标题行
        Row(
          children: ['一', '二', '三', '四', '五', '六', '日']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),

        // 日期网格
        Expanded(
          child: Column(
            children: List.generate(rows, (row) {
              return Expanded(
                child: Row(
                  children: List.generate(7, (col) {
                    final cellIndex = row * 7 + col;
                    final day = cellIndex - leadingEmptyDays + 1;

                    if (day < 1 || day > totalDays) {
                      return const Expanded(child: SizedBox());
                    }

                    final isChecked = monthChecks.contains(day);
                    final isToday = day == now.day;

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isChecked
                              ? primaryColor.withOpacity(0.8)
                              : (isToday
                                  ? primaryColor.withOpacity(0.1)
                                  : Colors.transparent),
                          borderRadius: BorderRadius.circular(4),
                          border: isToday && !isChecked
                              ? Border.all(color: primaryColor, width: 1)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 10,
                              color: isChecked
                                  ? Colors.white
                                  : (isToday ? primaryColor : Colors.black87),
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// 构建打卡项目选择器
  Widget _buildItemSelector() {
    final theme = Theme.of(context);
    final items = _checkinPlugin.checkinItems;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '选择打卡项目',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              final isSelected = _selectedItemId == item.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _onItemSelected(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? item.color
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? item.color.withOpacity(0.05)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        // 图标
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: item.color.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.icon,
                            color: item.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 项目信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '连续 ${item.getConsecutiveDays()} 天',
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
                          color: isSelected ? item.color : Colors.grey[400],
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

  /// 选中打卡项目
  void _onItemSelected(CheckinItem item) {
    setState(() {
      _selectedItemId = item.id;
      // 更新主色调为打卡项目的颜色
      _widgetConfig = _widgetConfig.updateColor('primary', item.color);
    });
  }

  /// 保存配置并关闭界面
  Future<void> _saveAndFinish() async {
    if (_selectedItemId == null || widget.widgetId == null) {
      Navigator.of(context).pop();
      return;
    }

    try {
      // 保存打卡项目ID
      await HomeWidget.saveWidgetData<String>(
        'checkin_item_id_${widget.widgetId}',
        _selectedItemId!,
      );

      // 保存背景色（使用 String 存储，因为 HomeWidget 不支持 int）
      final primaryColor = _widgetConfig.getColor('primary');
      if (primaryColor != null) {
        await HomeWidget.saveWidgetData<String>(
          'checkin_widget_primary_color_${widget.widgetId}',
          primaryColor.value.toString(),
        );
      }

      // 保存标题色（使用 String 存储）
      final accentColor = _widgetConfig.getColor('accent');
      if (accentColor != null) {
        await HomeWidget.saveWidgetData<String>(
          'checkin_widget_accent_color_${widget.widgetId}',
          accentColor.value.toString(),
        );
      }

      // 保存透明度（使用 String 存储）
      await HomeWidget.saveWidgetData<String>(
        'checkin_widget_opacity_${widget.widgetId}',
        _widgetConfig.opacity.toString(),
      );

      // 获取选中的打卡项目
      final selectedItem = _getSelectedItem()!;

      // 同步打卡项目数据到小组件
      await _syncCheckinItemToWidget(selectedItem);

      // 等待 SharedPreferences 数据写入完成
      // HomeWidget.saveWidgetData 使用 apply() 是异步的，需要等待
      await Future.delayed(const Duration(milliseconds: 200));

      // 更新小组件
      debugPrint('正在更新小组件...');
      await HomeWidget.updateWidget(
        name: 'CheckinItemWidgetProvider',
        iOSName: 'CheckinItemWidgetProvider',
        qualifiedAndroidName:
            'github.hunmer.memento.widgets.providers.CheckinItemWidgetProvider',
      );
      debugPrint('CheckinItemWidgetProvider 更新完成');

      await HomeWidget.updateWidget(
        name: 'CheckinMonthWidgetProvider',
        iOSName: 'CheckinMonthWidgetProvider',
        qualifiedAndroidName:
            'github.hunmer.memento.widgets.providers.CheckinMonthWidgetProvider',
      );
      debugPrint('CheckinMonthWidgetProvider 更新完成');

      if (mounted) {
        toastService.showToast('已配置 "${selectedItem.name}"');

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        toastService.showToast('配置失败: $e');
      }
    }
  }

  /// 同步打卡项目数据到小组件
  Future<void> _syncCheckinItemToWidget(CheckinItem item) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekChecks = List<bool>.filled(7, false);

      // 从周一开始算起（周一=0, 周日=6）
      final mondayOffset = (now.weekday - 1);

      for (int i = 0; i < 7; i++) {
        final targetDate = now.subtract(Duration(days: mondayOffset - i));
        final records = item.getDateRecords(targetDate);
        weekChecks[i] = records.isNotEmpty;
      }

      final weekChecksString = weekChecks.map((e) => e ? '1' : '0').join(',');

      // 获取本月的打卡日期列表
      final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);
      final List<int> monthChecks = [];

      for (int day = 1; day <= lastDayOfMonth.day; day++) {
        final date = DateTime(today.year, today.month, day);
        final records = item.getDateRecords(date);
        if (records.isNotEmpty) {
          monthChecks.add(day);
        }
      }

      final widgetData = jsonEncode({
        'items': [
          {
            'id': item.id,
            'name': item.name,
            'weekChecks': weekChecksString,
            'monthChecks': monthChecks.join(','),
          }
        ],
      });

      await HomeWidget.saveWidgetData<String>(
        'checkin_item_widget_data',
        widgetData,
      );

      debugPrint(
          '打卡项目数据已同步: ${item.name}, weekChecks: $weekChecksString, monthChecks: ${monthChecks.join(',')}');
    } catch (e) {
      debugPrint('同步打卡项目数据失败: $e');
    }
  }
}
