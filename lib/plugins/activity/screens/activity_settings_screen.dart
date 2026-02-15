import 'dart:async';
import 'package:get/get.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'package:Memento/plugins/activity/models/activity_record.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/tts/tts_plugin.dart';
import 'package:Memento/plugins/tts/models/tts_service_type.dart';

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

  // TTS 播报设置
  bool _isTTSAnnouncementEnabled = false;
  int _ttsAnnouncementInterval = 5; // 默认5分钟
  final TextEditingController _ttsTextController = TextEditingController(
    text: '已超过 {unrecorded_time} 分钟未记录活动，上次的活动是 {last_activity} ',
  );
  bool _checkOnlyWorkHours = false;
  int _workHoursStart = 9;
  int _workHoursEnd = 18;

  // TTS 服务列表
  List<dynamic> _ttsServices = [];
  bool _isLoadingTTSServices = true;
  String? _selectedTTSServiceId;

  // 震动反馈设置
  bool _enableHapticFeedback = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadLastActivityInfo();
    _loadTTSAnnouncementSettings();
    _loadTTSServices();

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
        setState(() {});
      }
      return;
    }

    final now = DateTime.now();
    final diff = now.difference(_lastActivity!.endTime);

    if (diff.inDays > 0) {
    } else if (diff.inHours > 0) {
    } else {}

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleNotification(bool value) async {
    try {
      final plugin = ActivityPlugin.instance;

      if (value) {
        await plugin.enableActivityNotification();
        if (!mounted) return;
        toastService.showToast('activity_notificationEnabled'.tr);
      } else {
        await plugin.disableActivityNotification();
        if (!mounted) return;
        toastService.showToast('activity_notificationDisabled'.tr);
      }

      setState(() {
        _isNotificationEnabled = value;
      });
    } catch (e) {
      if (mounted) {
        toastService.showToast('${'activity_operationFailed'.tr}: $e');
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

  // ==================== TTS 播报设置 ====================

  Future<void> _loadTTSServices() async {
    try {
      // 获取 TTS 插件
      final plugin = PluginManager.instance.getPlugin('tts');
      if (plugin == null) {
        debugPrint('TTS 插件未安装');
        return;
      }

      final ttsPlugin = plugin as TTSPlugin;
      final services = await ttsPlugin.managerService.getAllServices();
      final defaultService = await ttsPlugin.managerService.getDefaultService();
      final selectedId =
          await ActivityPlugin.instance.getTTSAnnouncementServiceId();

      if (mounted) {
        setState(() {
          _ttsServices = services;
          _isLoadingTTSServices = false;
          _selectedTTSServiceId = selectedId ?? defaultService?.id;
        });
      }
    } catch (e) {
      debugPrint('加载 TTS 服务列表失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingTTSServices = false;
        });
      }
    }
  }

  Future<void> _loadTTSAnnouncementSettings() async {
    try {
      final plugin = ActivityPlugin.instance;
      final isEnabled = plugin.isTTSAnnouncementEnabled();
      final interval = await plugin.getTTSAnnouncementInterval();
      final text = await plugin.getTTSAnnouncementText();
      final workHours = await plugin.getWorkHoursSettings();
      final hapticFeedback = await plugin.getTTSAnnouncementHapticFeedback();

      if (mounted) {
        setState(() {
          _isTTSAnnouncementEnabled = isEnabled;
          _ttsAnnouncementInterval = interval;
          _ttsTextController.text = text;
          _checkOnlyWorkHours = workHours['checkOnlyWorkHours'] as bool;
          _workHoursStart = workHours['workHoursStart'] as int;
          _workHoursEnd = workHours['workHoursEnd'] as int;
          _enableHapticFeedback = hapticFeedback;
        });
      }
    } catch (e) {
      debugPrint('加载播报设置失败: $e');
    }
  }

  Future<void> _toggleTTSAnnouncement(bool value) async {
    try {
      final plugin = ActivityPlugin.instance;

      if (value) {
        await plugin.enableTTSAnnouncement();
        if (!mounted) return;
        toastService.showToast('播报服务已启用');
      } else {
        await plugin.disableTTSAnnouncement();
        if (!mounted) return;
        toastService.showToast('播报服务已禁用');
      }

      setState(() {
        _isTTSAnnouncementEnabled = value;
      });
    } catch (e) {
      if (mounted) {
        toastService.showToast('操作失败: $e');
      }
      // 恢复开关状态
      setState(() {
        _isTTSAnnouncementEnabled = !value;
      });
    }
  }

  Future<void> _updateTTSAnnouncementInterval(int value) async {
    try {
      await ActivityPlugin.instance.setTTSAnnouncementInterval(value);
      setState(() {
        _ttsAnnouncementInterval = value;
      });
    } catch (e) {
      debugPrint('更新播报间隔失败: $e');
    }
  }

  Future<void> _updateTTSText() async {
    try {
      await ActivityPlugin.instance.setTTSAnnouncementText(
        _ttsTextController.text,
      );
      toastService.showToast('播报文本已更新');
    } catch (e) {
      toastService.showToast('更新失败: $e');
    }
  }

  Future<void> _updateWorkHoursSettings() async {
    try {
      await ActivityPlugin.instance.setWorkHoursSettings(
        checkOnlyWorkHours: _checkOnlyWorkHours,
        workHoursStart: _workHoursStart,
        workHoursEnd: _workHoursEnd,
      );
      toastService.showToast('工作时间设置已更新');
    } catch (e) {
      toastService.showToast('更新失败: $e');
    }
  }

  Future<void> _testTTSSpeak() async {
    try {
      await ActivityPlugin.instance.ttsAnnouncementService.testSpeak();
      toastService.showToast('测试播报已发送');
    } catch (e) {
      toastService.showToast('测试播报失败: $e');
    }
  }

  Future<void> _updateTTSServiceId(String? serviceId) async {
    try {
      await ActivityPlugin.instance.setTTSAnnouncementServiceId(serviceId);
      setState(() {
        _selectedTTSServiceId = serviceId;
      });
    } catch (e) {
      toastService.showToast('设置失败: $e');
    }
  }

  @override
  void dispose() {
    _ttsTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('设置')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 通知设置区域 - 仅在移动端平台显示
                  if (UniversalPlatform.isIOS || UniversalPlatform.isAndroid)
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
                          // 通知时间设置
                          if (_isNotificationEnabled &&
                              UniversalPlatform.isAndroid) ...[
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
                                    label: 'activity_minutesUnit'.trParams({
                                      'minutes': '$_minimumReminderInterval',
                                    }),
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
                                    'activity_minutesUnit'.trParams({
                                      'minutes': '$_minimumReminderInterval',
                                    }),
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
                                    label: 'activity_minutesUnit'.trParams({
                                      'minutes': '$_updateInterval',
                                    }),
                                    activeColor: ActivityPlugin.instance.color,
                                    onChanged: (value) {
                                      _updateUpdateInterval(value.round());
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    'activity_minutesUnit'.trParams({
                                      'minutes': '$_updateInterval',
                                    }),
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

                  // TTS 播报设置区域
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.volume_up,
                                color: ActivityPlugin.instance.color,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '语音播报提醒',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _isTTSAnnouncementEnabled,
                                onChanged: _toggleTTSAnnouncement,
                                activeColor: ActivityPlugin.instance.color,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '当超过指定时间未记录活动时，通过语音播报提醒',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),

                          // 播报设置
                          if (_isTTSAnnouncementEnabled) ...[
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),

                            // TTS 服务选择
                            Text('TTS 语音服务', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 8),
                            _isLoadingTTSServices
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : _ttsServices.isEmpty
                                ? const Text('没有可用的 TTS 服务')
                                : DropdownButtonFormField<String>(
                                  value: _selectedTTSServiceId,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: '选择 TTS 服务',
                                  ),
                                  items:
                                      _ttsServices.where((s) => s.isEnabled).map((
                                        service,
                                      ) {
                                        final config = service;
                                        return DropdownMenuItem<String>(
                                          value: config.id,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                config.type ==
                                                        TTSServiceType.system
                                                    ? Icons.record_voice_over
                                                    : Icons.cloud,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(config.name),
                                              if (config.isDefault) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    '默认',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    _updateTTSServiceId(value);
                                  },
                                ),
                            const SizedBox(height: 16),

                            // 播报间隔
                            Text(
                              '未记录时间间隔（分钟）',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _ttsAnnouncementInterval.toDouble(),
                                    min: 1,
                                    max: 60,
                                    divisions: 59,
                                    label: '$_ttsAnnouncementInterval 分钟',
                                    activeColor: ActivityPlugin.instance.color,
                                    onChanged: (value) {
                                      _updateTTSAnnouncementInterval(
                                        value.round(),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    '$_ttsAnnouncementInterval 分钟',
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

                            // 播报文本
                            Text('播报文本模板', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(
                              '支持的变量：{date} {last_activity} {unrecorded_time} {time} {weekday}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _ttsTextController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: '输入播报文本模板',
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _updateTTSText,
                              icon: const Icon(Icons.save),
                              label: const Text('保存文本'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(36),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _testTTSSpeak,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('测试播报一次'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(36),
                              ),
                            ),

                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),

                            // 工作时间限制
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '仅在工作时间检查',
                                  style: theme.textTheme.titleSmall,
                                ),
                                Switch(
                                  value: _checkOnlyWorkHours,
                                  onChanged: (value) {
                                    setState(() {
                                      _checkOnlyWorkHours = value;
                                    });
                                    _updateWorkHoursSettings();
                                  },
                                  activeColor: ActivityPlugin.instance.color,
                                ),
                              ],
                            ),

                            if (_checkOnlyWorkHours) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '开始时间',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        DropdownButton<int>(
                                          value: _workHoursStart,
                                          isExpanded: true,
                                          items:
                                              List.generate(24, (i) => i).map((
                                                hour,
                                              ) {
                                                return DropdownMenuItem<int>(
                                                  value: hour,
                                                  child: Text('$hour:00'),
                                                );
                                              }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                _workHoursStart = value;
                                              });
                                              _updateWorkHoursSettings();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '结束时间',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        DropdownButton<int>(
                                          value: _workHoursEnd,
                                          isExpanded: true,
                                          items:
                                              List.generate(24, (i) => i).map((
                                                hour,
                                              ) {
                                                return DropdownMenuItem<int>(
                                                  value: hour,
                                                  child: Text('$hour:00'),
                                                );
                                              }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                _workHoursEnd = value;
                                              });
                                              _updateWorkHoursSettings();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 16),

                            // 震动反馈开关
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.vibration,
                                      size: 20,
                                      color: ActivityPlugin.instance.color,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '震动反馈',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _enableHapticFeedback,
                                  onChanged: (value) {
                                    setState(() {
                                      _enableHapticFeedback = value;
                                    });
                                    ActivityPlugin.instance
                                        .setTTSAnnouncementHapticFeedback(
                                          value,
                                        );
                                  },
                                  activeColor: ActivityPlugin.instance.color,
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
