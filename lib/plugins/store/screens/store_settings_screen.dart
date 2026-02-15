import 'package:Memento/plugins/store/store_plugin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/widgets/form_fields/event_multi_select_field.dart';
import 'package:universal_platform/universal_platform.dart';

/// Store 插件设置界面
class StoreSettingsScreen extends StatefulWidget {
  final PluginBase plugin;

  const StoreSettingsScreen({super.key, required this.plugin});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // 选中的事件列表
  List<String> _selectedEvents = [];

  // 积分奖励设置
  final Map<String, int> _pointAwards = {};
  final Map<String, TextEditingController> _controllers = {};

  // 其他设置
  bool _enablePointsNotification = true; // 积分变动通知
  bool _enableExpiringReminder = true; // 到期提醒

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    // 释放所有控制器
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 文本改变回调 - 实时保存
  void _onTextChanged(String eventKey) {
    _savePointAwards();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = widget.plugin.settings;
      final pointAwards = settings['point_awards'] as Map<String, dynamic>?;

      if (pointAwards != null) {
        // 加载积分奖励设置和选中的事件
        pointAwards.forEach((key, value) {
          // 只加载积分值大于 0 的事件
          if (value is int && value > 0) {
            _pointAwards[key] = value;
            _selectedEvents.add(key);
            final controller = TextEditingController(text: value.toString());
            controller.addListener(() => _onTextChanged(key));
            _controllers[key] = controller;
          }
        });
      }

      // 加载其他设置
      _enablePointsNotification =
          settings['enablePointsNotification'] as bool? ?? true;
      _enableExpiringReminder =
          settings['enableExpiringReminder'] as bool? ?? true;
    } catch (e) {
      _showError('加载设置失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 保存积分奖励设置（实时保存）
  Future<void> _savePointAwards() async {
    try {
      // 只保存选中事件的积分值
      final newPointAwards = <String, dynamic>{};

      // 为每个选中事件保存积分值
      for (final eventKey in _selectedEvents) {
        final controller = _controllers[eventKey];
        final value =
            controller != null
                ? (int.tryParse(controller.text) ??
                    getDefaultPointsForEvent(eventKey))
                : getDefaultPointsForEvent(eventKey);
        newPointAwards[eventKey] = value;
      }

      debugPrint('🔧 [Store设置页面] 实时保存积分奖励配置');
      await widget.plugin.updateSettings({
        'point_awards': newPointAwards,
        'enablePointsNotification': _enablePointsNotification,
        'enableExpiringReminder': _enableExpiringReminder,
      });
    } catch (e) {
      debugPrint('❌ [Store设置页面] 保存失败: $e');
    }
  }

  /// 获取事件的默认积分值
  int getDefaultPointsForEvent(String eventKey) {
    final defaults =
        StorePlugin.defaultPointSettings['point_awards']
            as Map<String, dynamic>?;
    return defaults?[eventKey] as int? ?? 10;
  }

  /// 从 kDefaultAvailableEvents 获取事件显示名称
  String _getEventDisplayName(String eventKey) {
    final eventOption = kDefaultAvailableEvents.firstWhere(
      (e) => e.eventName == eventKey,
      orElse:
          () => EventOption(
            eventName: eventKey,
            category: '未知',
            description: eventKey,
          ),
    );
    return eventOption.description;
  }

  /// 处理事件选择变化 - 实时保存
  void _onSelectedEventsChanged(List<String> events) {
    setState(() {
      // 添加新选择的事件
      for (final eventKey in events) {
        if (!_pointAwards.containsKey(eventKey)) {
          _pointAwards[eventKey] = getDefaultPointsForEvent(eventKey);
          _controllers[eventKey] = TextEditingController(
            text: _pointAwards[eventKey].toString(),
          );
          _controllers[eventKey]?.addListener(() => _onTextChanged(eventKey));
        }
      }

      // 移除未选择的事件（保留控制器以备重新选择）
      for (final eventKey in _pointAwards.keys.toList()) {
        if (!events.contains(eventKey)) {
          _pointAwards.remove(eventKey);
        }
      }

      _selectedEvents = events;
    });

    // 实时保存
    _savePointAwards();
  }

  /// 保存开关设置（不需要表单验证）
  Future<void> _saveSwitchSettings() async {
    try {
      await widget.plugin.updateSettings({
        'enablePointsNotification': _enablePointsNotification,
        'enableExpiringReminder': _enableExpiringReminder,
      });

      debugPrint('🔧 [Store设置页面] 开关设置已自动保存');
    } catch (e) {
      debugPrint('❌ [Store设置页面] 自动保存失败: $e');
      _showError('自动保存失败: $e');
    }
  }

  /// 重置为默认设置
  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('重置设置'),
          content: const Text('确定要重置为默认设置吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await widget.plugin.updateSettings(StorePlugin.defaultPointSettings);
        await _loadSettings();
        if (mounted) {
          toastService.showToast('已重置为默认设置');
        }
      } catch (e) {
        _showError('重置设置失败: $e');
      }
    }
  }

  /// 显示错误
  void _showError(String message) {
    if (!mounted) return;
    toastService.showToast(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('store_storeSettings'.tr),
        actions: [
          // 重置按钮
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetToDefault,
            tooltip: '重置为默认设置',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 通知设置 - 仅在移动端平台显示
            if (UniversalPlatform.isIOS || UniversalPlatform.isAndroid) ...[
              // 通知设置标题
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '通知设置',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),

              // 积分变动通知开关
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  child: SwitchListTile(
                    title: Text('store_enablePointsNotification'.tr),
                    subtitle: Text(
                      'store_enablePointsNotificationDescription'.tr,
                    ),
                    value: _enablePointsNotification,
                    onChanged: (value) {
                      setState(() {
                        _enablePointsNotification = value;
                      });
                      _saveSwitchSettings(); // 自动保存
                    },
                  ),
                ),
              ),

              // 到期提醒开关
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  child: SwitchListTile(
                    title: Text('store_enableExpiringReminder'.tr),
                    subtitle: Text(
                      'store_enableExpiringReminderDescription'.tr,
                    ),
                    value: _enableExpiringReminder,
                    onChanged: (value) {
                      setState(() {
                        _enableExpiringReminder = value;
                      });
                      _saveSwitchSettings(); // 自动保存
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
            ],

            // 积分奖励设置标题
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '积分奖励设置',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            // 说明文本
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '选择要启用积分奖励的事件，并配置各项行为的积分奖励值。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 事件选择器
            EventMultiSelectField(
              name: 'selected_events',
              availableEvents: kDefaultAvailableEvents,
              dialogTitle: '选择启用积分奖励的事件',
              initialValue: _selectedEvents,
              prefixIcon: Icons.event_available,
              onChanged: (events) {
                if (events is List<String>) {
                  _onSelectedEventsChanged(events);
                }
              },
            ),

            const SizedBox(height: 16),

            // 积分奖励表单
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_selectedEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    '未选择任何事件\n请点击上方选择需要启用积分奖励的事件',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children:
                        _selectedEvents.map((eventKey) {
                          final displayName = _getEventDisplayName(eventKey);
                          final controller = _controllers[eventKey];

                          // 如果没有控制器，创建一个默认的
                          if (controller == null) {
                            _controllers[eventKey] = TextEditingController(
                              text:
                                  getDefaultPointsForEvent(eventKey).toString(),
                            );
                            _controllers[eventKey]?.addListener(
                              () => _onTextChanged(eventKey),
                            );
                          }

                          final effectiveController = _controllers[eventKey]!;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    displayName,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: effectiveController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: '积分',
                                      hintText: '0',
                                      suffix: Text('store_points'.tr),
                                      border: const OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '请输入积分值';
                                      }
                                      final points = int.tryParse(value);
                                      if (points == null || points < 0) {
                                        return '必须为非负整数';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
