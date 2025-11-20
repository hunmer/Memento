import 'package:flutter/material.dart';
import '../plugins/tts/tts_plugin.dart';
import '../plugins/tts/models/tts_service_config.dart';
import '../plugins/tts/models/tts_service_type.dart';

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
      title: const Row(
        children: [
          Icon(Icons.record_voice_over, size: 24),
          SizedBox(width: 8),
          Text('语音播报设置'),
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
                      title: const Text('启用自动朗读'),
                      subtitle: const Text('AI回复完成后自动朗读消息内容'),
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
                      const Text(
                        '选择TTS服务',
                        style: TextStyle(
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
                                        child: const Text(
                                          '默认',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                _getServiceTypeText(service),
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
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '暂无可用的TTS服务，请先在TTS插件中配置',
                                style: TextStyle(fontSize: 12),
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
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final result = TTSSettingsResult(
              enabled: _enabled,
              serviceId: _selectedServiceId,
            );
            Navigator.of(context).pop(result);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }

  /// 获取服务类型文本
  String _getServiceTypeText(TTSServiceConfig service) {
    String typeText = service.type.displayName;
    if (!service.isEnabled) {
      typeText += ' (已禁用)';
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
