import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/tts/tts_plugin.dart';
import 'package:Memento/plugins/tts/models/tts_service_config.dart';
import 'package:Memento/plugins/tts/models/tts_service_type.dart';


/// TTS设置对话框
///
/// 用于配置TTS语音播报功能，包括：
/// - 是否启用自动朗读
/// - 选择TTS服务
class TTSSettingsDialog extends StatefulWidget {
  /// 初始是否启用自动朗读
  final bool initialEnabled;

  /// 初始选择的服务ID
  final String? initialServiceId;

  const TTSSettingsDialog({
    super.key,
    this.initialEnabled = false,
    this.initialServiceId,
  });

  @override
  State<TTSSettingsDialog> createState() => _TTSSettingsDialogState();
}

class _TTSSettingsDialogState extends State<TTSSettingsDialog> {
  late bool _enabled;
  String? _selectedServiceId;
  List<TTSServiceConfig> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _selectedServiceId = widget.initialServiceId;
    _loadServices();
  }

  /// 加载TTS服务列表
  Future<void> _loadServices() async {
    try {
      final ttsPlugin = TTSPlugin.instance;
      final services = await ttsPlugin.managerService.getAllServices();

      setState(() {
        _services = services;
        _isLoading = false;
      });

      // 如果没有选中的服务,自动选择默认服务
      if (_selectedServiceId == null && services.isNotEmpty) {
        final defaultService = services.firstWhere(
          (s) => s.isDefault,
          orElse: () => services.first,
        );
        setState(() {
          _selectedServiceId = defaultService.id;
        });
      }
    } catch (e) {
      debugPrint('加载TTS服务失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.record_voice_over, size: 24),
          SizedBox(width: 8),
          Text('widget_voiceBroadcastSettings'.tr),
        ],
      ),
      content:
          _isLoading
              ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
              : SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 启用开关
                    SwitchListTile(
                      title: Text(
                        'widget_enableAutoRead'.tr,
                      ),
                      subtitle: Text(
                        'widget_autoReadAIMessage'.tr,
                      ),
                      value: _enabled,
                      onChanged: (value) {
                        setState(() {
                          _enabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 服务选择
                    if (_enabled && _services.isNotEmpty) ...[
                      Text(
                        'widget_selectTTSService'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final service = _services[index];

                            return RadioListTile<String>(
                              title: Row(
                                children: [
                                  Text(service.name),
                                  if (service.isDefault)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'widget_defaultLabel'.tr,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                _getServiceTypeText(context, service),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              value: service.id,
                              groupValue: _selectedServiceId,
                              onChanged:
                                  service.isEnabled
                                      ? (value) {
                                        setState(() {
                                          _selectedServiceId = value;
                                        });
                                      }
                                      : null,
                              controlAffinity: ListTileControlAffinity.trailing,
                            );
                          },
                        ),
                      ),
                    ],

                    // 无可用服务提示
                    if (_enabled && _services.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'widget_noTTSServiceAvailable'.tr,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('widget_cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () {
            final result = TTSSettingsResult(
              enabled: _enabled,
              serviceId: _selectedServiceId,
            );
            Navigator.of(context).pop(result);
          },
          child: Text('widget_confirm'.tr),
        ),
      ],
    );
  }

  /// 获取服务类型文本
  String _getServiceTypeText(BuildContext context, TTSServiceConfig service) {
    String typeText = service.type.displayName;
    if (!service.isEnabled) {
      typeText += 'widget_disabled'.tr;
    }
    if (service.voice != null && service.voice!.isNotEmpty) {
      typeText += ' · ${service.voice}';
    }
    return typeText;
  }
}

/// TTS设置结果
class TTSSettingsResult {
  /// 是否启用自动朗读
  final bool enabled;

  /// 选择的服务ID
  final String? serviceId;

  const TTSSettingsResult({required this.enabled, this.serviceId});
}

/// 显示TTS设置对话框的便捷方法
///
/// 返回 [TTSSettingsResult] 或 null (如果用户取消)
Future<TTSSettingsResult?> showTTSSettingsDialog(
  BuildContext context, {
  bool initialEnabled = false,
  String? initialServiceId,
}) {
  return showDialog<TTSSettingsResult>(
    context: context,
    builder:
        (context) => TTSSettingsDialog(
          initialEnabled: initialEnabled,
          initialServiceId: initialServiceId,
        ),
  );
}
