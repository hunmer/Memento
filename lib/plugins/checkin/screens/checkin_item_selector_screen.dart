import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../checkin_plugin.dart';
import '../models/checkin_item.dart';
import '../../../core/services/plugin_widget_sync_helper.dart';

/// 打卡项目选择器界面（用于小组件配置）
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

  @override
  Widget build(BuildContext context) {
    final items = _checkinPlugin.checkinItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择打卡项目'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: items.isEmpty
          ? Center(
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
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = _selectedItemId == item.id;

                return Card(
                  elevation: isSelected ? 4 : 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? item.color
                          : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _onItemSelected(item),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // 图标
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: item.color.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.icon,
                              color: item.color,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // 项目信息
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.group,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 打卡状态
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: item.isCheckedToday()
                                      ? Colors.green.withAlpha(30)
                                      : Colors.grey.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.isCheckedToday() ? '已打卡' : '未打卡',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: item.isCheckedToday()
                                        ? Colors.green[700]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '连续 ${item.getConsecutiveDays()} 天',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),

                          // 选中标记
                          const SizedBox(width: 12),
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
              },
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
                    '确认选择',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  /// 选中打卡项目
  void _onItemSelected(CheckinItem item) {
    setState(() {
      _selectedItemId = item.id;
    });
  }

  /// 保存配置并关闭界面
  Future<void> _saveAndFinish() async {
    if (_selectedItemId == null || widget.widgetId == null) {
      Navigator.of(context).pop();
      return;
    }

    try {
      // 保存配置到 SharedPreferences (通过 home_widget 插件)
      await HomeWidget.saveWidgetData<String>(
        'checkin_item_id_${widget.widgetId}',
        _selectedItemId!,
      );

      // 获取选中的打卡项目
      final selectedItem = _checkinPlugin.checkinItems
          .firstWhere((item) => item.id == _selectedItemId);

      // 同步打卡项目数据到小组件
      await _syncCheckinItemToWidget(selectedItem);

      // 更新小组件（同时更新打卡项和打卡月份视图）
      await HomeWidget.updateWidget(
        name: 'CheckinItemWidgetProvider',
        iOSName: 'CheckinItemWidgetProvider',
        qualifiedAndroidName: 'github.hunmer.memento.widgets.providers.CheckinItemWidgetProvider',
      );

      // 更新打卡月份视图小组件
      await HomeWidget.updateWidget(
        name: 'CheckinMonthWidgetProvider',
        iOSName: 'CheckinMonthWidgetProvider',
        qualifiedAndroidName: 'github.hunmer.memento.widgets.providers.CheckinMonthWidgetProvider',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已选择 "${selectedItem.name}"'),
            duration: const Duration(seconds: 2),
          ),
        );

        // 延迟关闭，让用户看到成功提示
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('配置失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 同步打卡项目数据到小组件
  Future<void> _syncCheckinItemToWidget(CheckinItem item) async {
    try {
      // 计算七日打卡记录（周一到周日）
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

      // 转换为逗号分隔的字符串
      final weekChecksString = weekChecks.map((e) => e ? '1' : '0').join(',');

      // 获取本月的打卡日期列表（用于月份视图小组件）
      final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);
      final List<int> monthChecks = [];

      for (int day = 1; day <= lastDayOfMonth.day; day++) {
        final date = DateTime(today.year, today.month, day);
        final records = item.getDateRecords(date);
        if (records.isNotEmpty) {
          monthChecks.add(day);
        }
      }

      // 构建符合 Android 端期望的 JSON 数据格式
      final widgetData = jsonEncode({
        'items': [
          {
            'id': item.id,
            'name': item.name,
            'weekChecks': weekChecksString,
            'monthChecks': monthChecks.join(','), // 本月打卡日期列表
          }
        ],
      });

      // 保存到 SharedPreferences
      await HomeWidget.saveWidgetData<String>(
        'checkin_item_widget_data',
        widgetData,
      );

      debugPrint('打卡项目数据已同步: ${item.name}, weekChecks: $weekChecksString, monthChecks: ${monthChecks.join(',')}');
    } catch (e) {
      debugPrint('同步打卡项目数据失败: $e');
    }
  }
}
