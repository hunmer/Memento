import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/agent_chat/services/voice_call/voice_call_manager.dart';
import 'package:Memento/plugins/tts/tts_plugin.dart';
import 'package:Memento/plugins/tts/models/tts_service_config.dart';
import 'package:Memento/plugins/tts/models/tts_service_type.dart';

/// 语音通话配置对话框
class VoiceCallConfigDialog extends StatefulWidget {
  final VoiceCallConfig initialConfig;

  const VoiceCallConfigDialog({
    super.key,
    required this.initialConfig,
  });

  @override
  State<VoiceCallConfigDialog> createState() => _VoiceCallConfigDialogState();
}

class _VoiceCallConfigDialogState extends State<VoiceCallConfigDialog> {
  late VoiceCallConfig _config;
  late bool _autoContinue;
  late bool _autoRecordAfterSpeaking;
  late bool _enableWelcomeMessage;
  late int _maxTurns;
  late int _recordingTimeout;
  late String _welcomeMessage;

  List<TTSServiceConfig> _ttsServices = [];
  bool _isLoadingServices = true;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _autoContinue = _config.autoContinue;
    _autoRecordAfterSpeaking = _config.autoRecordAfterSpeaking;
    _enableWelcomeMessage = _config.enableWelcomeMessage;
    _maxTurns = _config.maxTurns;
    _recordingTimeout = _config.recordingTimeout;
    _welcomeMessage = _config.welcomeMessage;
    _loadTTSServices();
  }

  /// 加载TTS服务列表
  Future<void> _loadTTSServices() async {
    try {
      final ttsPlugin = TTSPlugin.instance;
      final services = await ttsPlugin.managerService.getAllServices();

      setState(() {
        _ttsServices = services;
        _isLoadingServices = false;
      });
    } catch (e) {
      debugPrint('加载TTS服务失败: $e');
      setState(() {
        _isLoadingServices = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings_voice),
          SizedBox(width: 8),
          Text('语音通话设置'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            // TTS服务选择
            _buildTTSServiceSelector(),
            const Divider(height: 32),

            // 自动继续
            SwitchListTile(
              title: const Text('自动继续对话'),
              subtitle: const Text('AI回复完成后自动开始下一轮录音'),
              value: _autoContinue,
              onChanged: (value) {
                setState(() {
                  _autoContinue = value;
                });
              },
            ),

            // 自动录音
            if (_autoContinue)
              SwitchListTile(
                title: const Text('播报后自动录音'),
                subtitle: const Text('TTS播报完成后自动开始录音'),
                value: _autoRecordAfterSpeaking,
                onChanged: (value) {
                  setState(() {
                    _autoRecordAfterSpeaking = value;
                  });
                },
              ),

            // 最大对话轮数
            if (_autoContinue)
              ListTile(
                title: const Text('最大对话轮数'),
                subtitle: Text(_maxTurns == 0 ? '无限制' : '$_maxTurns 轮'),
                trailing: SizedBox(
                  width: 120,
                  child: Slider(
                    value: _maxTurns.toDouble(),
                    min: 0,
                    max: 20,
                    divisions: 20,
                    label: _maxTurns == 0 ? '无限制' : '$_maxTurns',
                    onChanged: (value) {
                      setState(() {
                        _maxTurns = value.round();
                      });
                    },
                  ),
                ),
              ),

            // 录音超时
            ListTile(
              title: const Text('录音超时时间'),
              subtitle: Text('$_recordingTimeout 秒'),
              trailing: SizedBox(
                width: 120,
                child: Slider(
                  value: _recordingTimeout.toDouble(),
                  min: 10,
                  max: 60,
                  divisions: 10,
                  label: '$_recordingTimeout 秒',
                  onChanged: (value) {
                    setState(() {
                      _recordingTimeout = value.round();
                    });
                  },
                ),
              ),
            ),

            const Divider(height: 32),

            // 欢迎语
            SwitchListTile(
              title: const Text('启用欢迎语'),
              subtitle: const Text('通话开始时播报欢迎消息'),
              value: _enableWelcomeMessage,
              onChanged: (value) {
                setState(() {
                  _enableWelcomeMessage = value;
                });
              },
            ),

            // 欢迎语内容
            if (_enableWelcomeMessage)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '欢迎语',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  controller: TextEditingController(text: _welcomeMessage),
                  onChanged: (value) {
                    _welcomeMessage = value;
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final config = VoiceCallConfig(
              ttsServiceId: _config.ttsServiceId,
              autoContinue: _autoContinue,
              autoRecordAfterSpeaking: _autoRecordAfterSpeaking,
              maxTurns: _maxTurns,
              recordingTimeout: _recordingTimeout,
              enableWelcomeMessage: _enableWelcomeMessage,
              welcomeMessage: _welcomeMessage,
            );
            Navigator.pop(context, config);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  /// 构建TTS服务选择器
  Widget _buildTTSServiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TTS 服务',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingServices)
          const Center(child: CircularProgressIndicator())
        else if (_ttsServices.isEmpty)
          const Text('暂无可用的TTS服务')
        else
          DropdownButtonFormField<String>(
            value: _config.ttsServiceId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '选择TTS服务',
            ),
            items: _ttsServices
                .where((s) => s.isEnabled)
                .map((service) {
              return DropdownMenuItem<String>(
                value: service.id,
                child: Row(
                  children: [
                    Icon(
                      service.type == TTSServiceType.system
                          ? Icons.record_voice_over
                          : Icons.cloud,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(service.name),
                    if (service.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
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
              setState(() {
                _config = _config.copyWith(ttsServiceId: value);
              });
            },
          ),
      ],
    );
  }
}
