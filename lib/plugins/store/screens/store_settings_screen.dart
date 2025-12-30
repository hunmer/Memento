import 'package:Memento/plugins/store/store_plugin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/services/toast_service.dart';

/// Store 插件设置界面
class StoreSettingsScreen extends StatefulWidget {
  final PluginBase plugin;

  const StoreSettingsScreen({super.key, required this.plugin});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // 积分奖励设置
  final Map<String, int> _pointAwards = {};
  final Map<String, TextEditingController> _controllers = {};

  // 其他设置
  bool _enablePointsNotification = true; // 积分变动通知
  bool _enableExpiringReminder = true; // 到期提醒

  bool _isLoading = false;
  bool _hasChanges = false;

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

  /// 文本改变回调
  void _onTextChanged(String eventKey) {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
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
        // 加载积分奖励设置
        pointAwards.forEach((key, value) {
          _pointAwards[key] = value as int;
          final controller = TextEditingController(text: value.toString());
          controller.addListener(() => _onTextChanged(key));
          _controllers[key] = controller;
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
        _hasChanges = false;
      });
    }
  }

  /// 保存设置（包含表单验证）
  Future<void> _saveSettings() async {
    // 验证所有输入
    for (final entry in _pointAwards.entries) {
      final controller = _controllers[entry.key];
      if (controller != null) {
        final value = int.tryParse(controller.text);
        if (value == null || value < 0) {
          _showError('${widget.plugin.getPluginName(context)} 的积分值必须为非负整数');
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newPointAwards = <String, dynamic>{};
      _pointAwards.forEach((key, _) {
        final controller = _controllers[key];
        if (controller != null) {
          final value = int.tryParse(controller.text) ?? 0;
          newPointAwards[key] = value;
        }
      });

      debugPrint('🔧 [Store设置页面] 准备保存积分奖励配置');
      await widget.plugin.updateSettings({
        'point_awards': newPointAwards,
        'enablePointsNotification': _enablePointsNotification,
        'enableExpiringReminder': _enableExpiringReminder,
      });

      // 验证保存后立即读取
      final savedSettings = widget.plugin.settings;
      debugPrint('🔧 [Store设置页面] 保存后验证: ${savedSettings['point_awards']}');

      setState(() {
        _hasChanges = false;
      });

      if (mounted) {
        toastService.showToast('设置保存成功');
      }
    } catch (e) {
      debugPrint('❌ [Store设置页面] 保存失败: $e');
      _showError('保存设置失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          // 保存按钮
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveSettings,
              tooltip: '保存设置',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  subtitle: Text('store_enableExpiringReminderDescription'.tr),
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
                '配置各项行为的积分奖励，当用户执行对应操作时将自动获得积分。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
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
            else
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children:
                        _pointAwards.entries.map((entry) {
                          final eventKey = entry.key;
                          final displayName = (widget.plugin as dynamic)
                              .getEventDisplayName(eventKey);
                          final controller = _controllers[eventKey];

                          if (controller == null) {
                            return const SizedBox.shrink();
                          }

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
                                    controller: controller,
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

            const SizedBox(height: 24),

            // 底部操作按钮
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetToDefault,
                        child: Text('store_resetToDefault'.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _hasChanges ? _saveSettings : null,
                        child: Text('store_saveSettings'.tr),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
