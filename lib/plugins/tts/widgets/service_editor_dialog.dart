import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/tts/models/tts_service_config.dart';
import 'package:Memento/plugins/tts/models/tts_service_type.dart';
import 'package:Memento/plugins/tts/models/tts_voice.dart';
import 'package:Memento/plugins/tts/services/system_tts_service.dart';
import 'package:Memento/plugins/tts/tts_plugin.dart';
import 'package:Memento/plugins/tts/l10n/tts_localizations.dart';
import 'package:Memento/core/services/toast_service.dart';

/// TTS服务编辑对话框（支持新建和编辑）
class ServiceEditorDialog extends StatefulWidget {
  /// 要编辑的服务配置（null表示新建）
  final TTSServiceConfig? service;

  const ServiceEditorDialog({
    super.key,
    this.service,
  });

  @override
  State<ServiceEditorDialog> createState() => _ServiceEditorDialogState();
}

class _ServiceEditorDialogState extends State<ServiceEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  // 基础配置
  late TextEditingController _nameController;
  late TTSServiceType _selectedType;
  late bool _isDefault;
  late bool _isEnabled;

  // 通用配置
  late double _pitch;
  late double _speed;
  late double _volume;
  late TextEditingController _voiceController;

  // HTTP 配置
  late TextEditingController _urlController;
  late TextEditingController _headersController;
  late TextEditingController _requestBodyController;
  late TextEditingController _audioFormatController;
  late String _responseType;
  late TextEditingController _audioFieldPathController;
  late bool _audioIsBase64;

  // 可用语音列表
  List<TTSVoice> _availableVoices = [];
  bool _loadingVoices = false;

  @override
  void initState() {
    super.initState();

    // 初始化控制器和变量
    final service = widget.service;

    _nameController = TextEditingController(text: service?.name ?? '');
    _selectedType = service?.type ?? TTSServiceType.system;
    _isDefault = service?.isDefault ?? false;
    _isEnabled = service?.isEnabled ?? true;

    _pitch = service?.pitch ?? 1.0;
    _speed = service?.speed ?? 1.0;
    _volume = service?.volume ?? 1.0;
    _voiceController = TextEditingController(text: service?.voice ?? 'zh-CN');

    _urlController = TextEditingController(text: service?.url ?? '');
    _headersController = TextEditingController(
      text: service?.headers != null
        ? service!.headers!.entries.map((e) => '${e.key}: ${e.value}').join('\n')
        : ''
    );
    _requestBodyController = TextEditingController(text: service?.requestBody ?? '');
    _audioFormatController = TextEditingController(text: service?.audioFormat ?? 'mp3');
    _responseType = service?.responseType ?? 'audio';
    _audioFieldPathController = TextEditingController(text: service?.audioFieldPath ?? '');
    _audioIsBase64 = service?.audioIsBase64 ?? false;

    // 如果是系统 TTS，加载可用语音列表
    if (_selectedType == TTSServiceType.system) {
      _loadAvailableVoices();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _voiceController.dispose();
    _urlController.dispose();
    _headersController.dispose();
    _requestBodyController.dispose();
    _audioFormatController.dispose();
    _audioFieldPathController.dispose();
    super.dispose();
  }

  /// 加载可用语音列表
  Future<void> _loadAvailableVoices() async {
    if (_loadingVoices) return;

    setState(() => _loadingVoices = true);

    try {
      // 创建临时服务实例来获取语音列表
      final tempConfig = TTSServiceConfig(
        name: 'temp',
        type: TTSServiceType.system,
      );

      final service = SystemTTSService(tempConfig);
      await service.initialize();
      final voices = await service.getAvailableVoices();
      await service.dispose();

      setState(() {
        _availableVoices = voices;
        _loadingVoices = false;

        // 如果当前选择的语音不在列表中，选择第一个
        if (_availableVoices.isNotEmpty &&
            !_availableVoices.any((v) => v.id == _voiceController.text)) {
          _voiceController.text = _availableVoices.first.id;
        }
      });
    } catch (e) {
      setState(() => _loadingVoices = false);
      if (mounted) {
        Toast.error('${loc.loadVoiceListFailed}: $e');
      }
    }
  }

  /// 构建表单
  Widget _buildForm() {
    final loc = TTSLocalizations.of(context);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基础配置
            _buildSectionTitle(loc.basicConfig),
            const SizedBox(height: 8),

            // 服务名称
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: loc.serviceName,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return loc.serviceName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 服务类型
            DropdownButtonFormField<TTSServiceType>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: loc.serviceType,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category),
              ),
              items: [
                DropdownMenuItem(
                  value: TTSServiceType.system,
                  child: Row(
                    children: [
                      const Icon(Icons.record_voice_over, size: 20),
                      const SizedBox(width: 8),
                      Text(loc.systemTts),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: TTSServiceType.http,
                  child: Row(
                    children: [
                      const Icon(Icons.cloud, size: 20),
                      const SizedBox(width: 8),
                      Text(loc.httpService),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    if (value == TTSServiceType.system) {
                      _loadAvailableVoices();
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // 启用状态
            SwitchListTile(
              title: Text(loc.enabled),
              subtitle: Text(_isEnabled ? loc.enableThisService : loc.disableThisService),
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
            ),

            // 默认服务
            SwitchListTile(
              title: Text(loc.defaultService),
              subtitle: Text(loc.setAsDefaultTTSService),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
            ),

            const SizedBox(height: 24),

            // 通用参数
            _buildSectionTitle(loc.readingParameters),
            const SizedBox(height: 8),

            // 音调
            _buildSlider(
              label: loc.pitch,
              value: _pitch,
              min: 0.5,
              max: 2.0,
              divisions: 30,
              onChanged: (value) => setState(() => _pitch = value),
            ),

            // 语速
            _buildSlider(
              label: loc.speed,
              value: _speed,
              min: 0.5,
              max: 2.0,
              divisions: 30,
              onChanged: (value) => setState(() => _speed = value),
            ),

            // 音量
            _buildSlider(
              label: loc.volume,
              value: _volume,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (value) => setState(() => _volume = value),
            ),

            const SizedBox(height: 16),

            // 语音/语言
            if (_selectedType == TTSServiceType.system && _availableVoices.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _availableVoices.any((v) => v.id == _voiceController.text)
                      ? _voiceController.text
                      : _availableVoices.first.id,
                    decoration: InputDecoration(
                      labelText: loc.voice,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.language),
                      helperText: TTSLocalizations.of(context).availableVoiceCount(_availableVoices.length),
                    ),
                    isExpanded: true,
                    items: _availableVoices.map((voice) {
                      return DropdownMenuItem(
                        value: voice.id,
                        child: _buildVoiceItem(voice),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _voiceController.text = value;
                        });
                      }
                    },
                  ),
                  if (_loadingVoices)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(TTSLocalizations.of(context).loadingVoiceList, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              )
            else if (_selectedType == TTSServiceType.system && _loadingVoices)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _voiceController,
                    decoration: InputDecoration(
                      labelText: loc.voice,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.language),
                      hintText: 'zh-CN, en-US, etc.',
                    ),
                    enabled: false,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(TTSLocalizations.of(context).loadingVoiceList, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              )
            else
              TextFormField(
                controller: _voiceController,
                decoration: InputDecoration(
                  labelText: loc.voice,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.language),
                  hintText: _selectedType == TTSServiceType.system
                    ? 'zh-CN, en-US, etc.'
                    : TTSLocalizations.of(context).fillAccordingToApi,
                  suffixIcon: _selectedType == TTSServiceType.system && !_loadingVoices
                    ? IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadAvailableVoices,
                        tooltip: TTSLocalizations.of(context).reloadVoiceList,
                      )
                    : null,
                ),
              ),

            // HTTP 特有配置
            if (_selectedType == TTSServiceType.http) ...[
              const SizedBox(height: 24),
              _buildSectionTitle(loc.httpConfig),
              const SizedBox(height: 8),

              // API URL
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: loc.apiUrl,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link),
                  hintText: 'https://api.example.com/tts',
                  helperText: '支持占位符: {text}, {voice}, {pitch}, {speed}, {volume}',
                ),
                validator: (value) {
                  if (_selectedType == TTSServiceType.http) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.pleaseEnterApiUrl;
                    }
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return loc.urlMustStartWithHttp;
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 请求头
              TextFormField(
                controller: _headersController,
                decoration: InputDecoration(
                  labelText: loc.headers,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.http),
                  hintText: 'Content-Type: application/json\nAuthorization: Bearer token',
                  helperText: '每行一个键值对，格式：Key: Value',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // 请求体
              TextFormField(
                controller: _requestBodyController,
                decoration: InputDecoration(
                  labelText: loc.requestBody,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.code),
                  hintText: '{"text": "{text}", "voice": "{voice}"}',
                  helperText: 'JSON 格式，支持占位符',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),

              // 响应类型
              DropdownButtonFormField<String>(
                value: _responseType,
                decoration: InputDecoration(
                  labelText: TTSLocalizations.of(context).responseType,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.settings_input_composite),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'audio',
                    child: Text(loc.directAudioReturn),
                  ),
                  DropdownMenuItem(
                    value: 'json',
                    child: Text(loc.jsonWrapped),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _responseType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // JSON 音频字段路径
              if (_responseType == 'json') ...[
                TextFormField(
                  controller: _audioFieldPathController,
                  decoration: InputDecoration(
                    labelText: TTSLocalizations.of(context).audioFieldPath,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.account_tree),
                    hintText: 'data.audio 或 result.audioUrl',
                    helperText: '用点号分隔的JSON路径',
                  ),
                  validator: (value) {
                    if (_responseType == 'json' && (value == null || value.trim().isEmpty)) {
                      return loc.pleaseEnterAudioFieldPath;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Base64 编码
                SwitchListTile(
                  title: Text(loc.audioBase64Encoded),
                  subtitle: Text(loc.audioIsBase64Encoded),
                  value: _audioIsBase64,
                  onChanged: (value) => setState(() => _audioIsBase64 = value),
                ),
              ],

              // 音频格式
              TextFormField(
                controller: _audioFormatController,
                decoration: InputDecoration(
                  labelText: TTSLocalizations.of(context).audioFormat,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.audiotrack),
                  hintText: 'mp3, wav, ogg, pcm',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建节标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: TTSPlugin.instance.color,
      ),
    );
  }

  /// 构建滑块
  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// 构建语音��项项
  Widget _buildVoiceItem(TTSVoice voice) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                voice.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    voice.language,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (voice.gender != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getGenderColor(voice.gender!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getGenderLabel(voice.gender!),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getGenderColor(voice.gender!),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 获取性别标签
  String _getGenderLabel(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return '男';
      case 'female':
        return '女';
      case 'neutral':
        return '中性';
      default:
        return gender;
    }
  }

  /// 获取性别��色
  Color _getGenderColor(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Colors.blue;
      case 'female':
        return Colors.pink;
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// 解析请求头
  Map<String, String>? _parseHeaders() {
    final text = _headersController.text.trim();
    if (text.isEmpty) return null;

    final headers = <String, String>{};
    for (final line in text.split('\n')) {
      final parts = line.split(':');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join(':').trim();
        headers[key] = value;
      }
    }

    return headers.isEmpty ? null : headers;
  }

  /// 保存配置
  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final service = TTSServiceConfig(
        id: widget.service?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        type: _selectedType,
        isDefault: _isDefault,
        isEnabled: _isEnabled,
        pitch: _pitch,
        speed: _speed,
        volume: _volume,
        voice: _voiceController.text.trim(),
        // HTTP 配置
        url: _selectedType == TTSServiceType.http ? _urlController.text.trim() : null,
        headers: _selectedType == TTSServiceType.http ? _parseHeaders() : null,
        requestBody: _selectedType == TTSServiceType.http ? _requestBodyController.text.trim() : null,
        audioFormat: _selectedType == TTSServiceType.http ? _audioFormatController.text.trim() : null,
        responseType: _selectedType == TTSServiceType.http ? _responseType : null,
        audioFieldPath: _selectedType == TTSServiceType.http && _responseType == 'json'
          ? _audioFieldPathController.text.trim()
          : null,
        audioIsBase64: _selectedType == TTSServiceType.http ? _audioIsBase64 : null,
        createdAt: widget.service?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 验证配置
      if (!service.validate()) {
        if (mounted) {
          Toast.error(loc.configValidationFailed);
        }
        return;
      }

      // 返回配置
      if (mounted) {
        Navigator.of(context).pop(service);
      }
    } catch (e) {
      if (mounted) {
        Toast.error('${loc.saveFailed}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = TTSLocalizations.of(context);
    final isEditing = widget.service != null;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            AppBar(
              title: Text(isEditing ? loc.editService : loc.addService),
              automaticallyImplyLeading:
                  !(Platform.isAndroid || Platform.isIOS),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            // 表单内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildForm(),
              ),
            ),

            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _saveService,
                    icon: const Icon(Icons.save),
                    label: Text(loc.save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
