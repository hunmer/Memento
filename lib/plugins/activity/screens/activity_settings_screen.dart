import 'dart:async';
import 'package:get/get.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'package:Memento/plugins/activity/models/activity_record.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 活动插件设置页面
class ActivitySettingsScreen extends StatefulWidget {
  const ActivitySettingsScreen({super.key});

  @override
  State<ActivitySettingsScreen> createState() => _ActivitySettingsScreenState();
}

class _ActivitySettingsScreenState extends State<ActivitySettingsScreen> {
  bool _isNotificationEnabled = false;
  bool _isLoading = true;

  // 最近活动信息
  ActivityRecord? _lastActivity;

  // 通知设置
  int _minimumReminderInterval = 30; // 默认30分钟
  int _updateInterval = 1; // 默认1分钟

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadLastActivityInfo();

    // 定时更新时间差
    Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateTimeSinceLast();
    });
  }

  Future<void> _loadSettings() async {
    try {
      final plugin = ActivityPlugin.instance;
      final isEnabled = plugin.isNotificationEnabled();
      final minInterval = await plugin.getMinimumReminderInterval();
      final updateInt = await plugin.getUpdateInterval();

      if (mounted) {
        setState(() {
          _isNotificationEnabled = isEnabled;
          _minimumReminderInterval = minInterval;
          _updateInterval = updateInt;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载设置失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLastActivityInfo() async {
    try {
      final plugin = ActivityPlugin.instance;
      final service = plugin.activityService;

      // 获取今天的活动
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final activities = await service.getActivitiesForDate(today);

      ActivityRecord? lastActivity;
      if (activities.isNotEmpty) {
        // 按结束时间排序，取最新的
        activities.sort((a, b) => b.endTime.compareTo(a.endTime));
        lastActivity = activities.first;
      } else {
        // 如果今天没有活动，检查昨天
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayActivities = await service.getActivitiesForDate(
          yesterday,
        );
        if (yesterdayActivities.isNotEmpty) {
          yesterdayActivities.sort((a, b) => b.endTime.compareTo(a.endTime));
          lastActivity = yesterdayActivities.first;
        }
      }

      if (mounted) {
        setState(() {
          _lastActivity = lastActivity;
        });
        _updateTimeSinceLast();
      }
    } catch (e) {
      debugPrint('加载最近活动信息失败: $e');
    }
  }

  void _updateTimeSinceLast() {
    if (_lastActivity == null) {
      if (mounted) {
        setState(() {
        });
      }
      return;
    }

    final now = DateTime.now();
    final diff = now.difference(_lastActivity!.endTime);

    if (diff.inDays > 0) {
    } else if (diff.inHours > 0) {
    } else {
    }

    if (mounted) {
      setState(() {
      });
    }
  }

  Future<void> _toggleNotification(bool value) async {
    try {
      final plugin = ActivityPlugin.instance;

      if (value) {
        await plugin.enableActivityNotification();
        if (!mounted) return;
        toastService.showToast(
          'activity_notificationEnabled'.tr,
        );
      } else {
        await plugin.disableActivityNotification();
        if (!mounted) return;
        toastService.showToast(
          'activity_notificationDisabled'.tr,
        );
      }

      setState(() {
        _isNotificationEnabled = value;
      });
    } catch (e) {
      if (mounted) {
        toastService.showToast(
          '${'activity_operationFailed'.tr}: $e',
        );
      }
      // 恢复开关状态
      setState(() {
        _isNotificationEnabled = !value;
      });
    }
  }

  Future<void> _updateMinimumReminderInterval(int value) async {
    try {
      await ActivityPlugin.instance.setMinimumReminderInterval(value);
      setState(() {
        _minimumReminderInterval = value;
      });
    } catch (e) {
      debugPrint('更新最小提醒间隔失败: $e');
    }
  }

  Future<void> _updateUpdateInterval(int value) async {
    try {
      await ActivityPlugin.instance.setUpdateInterval(value);
      setState(() {
        _updateInterval = value;
      });
    } catch (e) {
      debugPrint('更新通知更新频率失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 通知设置区域
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_active,
                                color: ActivityPlugin.instance.color,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'activity_notificationSettings'.tr,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '在通知栏常驻显示最后记录的活动、时间和快捷添加按钮',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'activity_enableNotificationBar'.tr,
                                style: theme.textTheme.titleSmall,
                              ),
                              Switch(
                                value: _isNotificationEnabled,
                                onChanged: _toggleNotification,
                                activeColor: ActivityPlugin.instance.color,
                              ),
                            ],
                          ),
                          if (!Platform.isAndroid) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'activity_onlySupportsAndroid'.tr,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // 通知时间设置
                          if (_isNotificationEnabled && Platform.isAndroid) ...[
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),

                            // 最小提醒间隔
                            Text(
                              'activity_minimumReminderInterval'.tr,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'activity_minimumReminderIntervalDesc'.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _minimumReminderInterval.toDouble(),
                                    min: 5,
                                    max: 120,
                                    divisions: 23,
                                    label: 'activity_minutesUnit'.trParams(
                                      {'minutes': '$_minimumReminderInterval'},
                                    ),
                                    activeColor: ActivityPlugin.instance.color,
                                    onChanged: (value) {
                                      _updateMinimumReminderInterval(
                                        value.round(),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    'activity_minutesUnit'.trParams(
                                      {'minutes': '$_minimumReminderInterval'},
                                    ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: ActivityPlugin.instance.color,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // 通知更新频率
                            Text(
                              'activity_updateInterval'.tr,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'activity_updateIntervalDesc'.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _updateInterval.toDouble(),
                                    min: 1,
                                    max: 10,
                                    divisions: 9,
                                    label: 'activity_minutesUnit'.trParams(
                                      {'minutes': '$_updateInterval'},
                                    ),
                                    activeColor: ActivityPlugin.instance.color,
                                    onChanged: (value) {
                                      _updateUpdateInterval(value.round());
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    'activity_minutesUnit'.trParams(
                                      {'minutes': '$_updateInterval'},
                                    ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: ActivityPlugin.instance.color,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
