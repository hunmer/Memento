import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/services/speech_recognition_config_service.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/agent_chat/services/speech/speech_recognition_config.dart';

/// 语音识别设置对话框
class SpeechRecognitionSettingsDialog extends StatefulWidget {
  const SpeechRecognitionSettingsDialog({super.key});

  @override
  State<SpeechRecognitionSettingsDialog> createState() =>
      _SpeechRecognitionSettingsDialogState();
}

class _SpeechRecognitionSettingsDialogState
    extends State<SpeechRecognitionSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _appIdController = TextEditingController();
  final _secretIdController = TextEditingController();
  final _secretKeyController = TextEditingController();

  bool _obscureSecretKey = true;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    // 监听文本变化
    _appIdController.addListener(_onTextChanged);
    _secretIdController.addListener(_onTextChanged);
    _secretKeyController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _appIdController.dispose();
    _secretIdController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  /// 文本改变回调
  void _onTextChanged() {
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
      final config = SpeechRecognitionConfigService.instance.config;

      if (config != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _appIdController.text = config.appId;
          _secretIdController.text = config.secretId;
          _secretKeyController.text = config.secretKey;
        });
      }
    } catch (e) {
      _showError('加载设置失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final config = TencentASRConfig(
        appId: _appIdController.text.trim(),
        secretId: _secretIdController.text.trim(),
        secretKey: _secretKeyController.text.trim(),
        sampleRate: 16000,
        engineModelType: '16k_zh',
        needVad: false,
        filterDirty: 0,
        wordInfo: false,
      );

      await SpeechRecognitionConfigService.instance.saveConfig(config);

      setState(() {
        _hasChanges = false;
      });

      if (mounted) {
        toastService.showToast('设置保存成功');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError('保存设置失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试配置
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final config = TencentASRConfig(
        appId: _appIdController.text.trim(),
        secretId: _secretIdController.text.trim(),
        secretKey: _secretKeyController.text.trim(),
      );

      if (!config.isValid()) {
        _showError('配置无效，请检查输入');
        return;
      }

      if (mounted) {
        toastService.showToast('配置验证通过！');
      }
    } catch (e) {
      _showError('验证失败: $e');
    }
  }

  /// 显示错误
  void _showError(String message) {
    if (!mounted) return;
    toastService.showToast(message);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.mic),
          const SizedBox(width: 8),
          const Text('语音识别设置'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 说明文本
            Text(
              '配置腾讯云实时语音识别服务，用于语音输入功能。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 8),

            // 获取凭证链接提示
            Text(
              '需要在腾讯云控制台开通语音识别服务并获取 API 凭证。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            // 表单
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
                child: Column(
                  children: [
                    // App ID 输入框
                    TextFormField(
                      controller: _appIdController,
                      decoration: const InputDecoration(
                        labelText: 'App ID',
                        hintText: '请输入腾讯云应用 ID',
                        border: OutlineInputBorder(),
                        helperText: '在腾讯云控制台获取',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入 App ID';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Secret ID 输入框
                    TextFormField(
                      controller: _secretIdController,
                      decoration: const InputDecoration(
                        labelText: 'Secret ID',
                        hintText: '请输入密钥 ID',
                        border: OutlineInputBorder(),
                        helperText: '访问密钥 ID',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入 Secret ID';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Secret Key 输入框
                    TextFormField(
                      controller: _secretKeyController,
                      obscureText: _obscureSecretKey,
                      decoration: InputDecoration(
                        labelText: 'Secret Key',
                        hintText: '请输入密钥 Key',
                        border: const OutlineInputBorder(),
                        helperText: '访问密钥 Key（请妥善保管）',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureSecretKey
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureSecretKey = !_obscureSecretKey;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入 Secret Key';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('screens_cancel'.tr),
        ),
        OutlinedButton(
          onPressed: _isLoading ? null : _testConnection,
          child: const Text('验证配置'),
        ),
        FilledButton(
          onPressed: _isLoading || !_hasChanges ? null : _saveSettings,
          child: Text('app_save'.tr),
        ),
      ],
    );
  }
}
