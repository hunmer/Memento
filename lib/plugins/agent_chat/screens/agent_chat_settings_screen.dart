import 'package:flutter/material.dart';
import '../../../core/plugin_base.dart';
import '../services/speech/speech_recognition_config.dart';

/// Agent Chat 插件设置界面
class AgentChatSettingsScreen extends StatefulWidget {
  final PluginBase plugin;

  const AgentChatSettingsScreen({super.key, required this.plugin});

  @override
  State<AgentChatSettingsScreen> createState() =>
      _AgentChatSettingsScreenState();
}

class _AgentChatSettingsScreenState extends State<AgentChatSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appIdController = TextEditingController();
  final _secretIdController = TextEditingController();
  final _secretKeyController = TextEditingController();

  bool _obscureSecretKey = true;
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _preferToolTemplates = false; // 优先使用工具模版开关

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
      final settings = widget.plugin.settings;
      final asrConfig = settings['asrConfig'] as Map<String, dynamic>?;

      if (asrConfig != null) {
        _appIdController.text = asrConfig['appId'] as String? ?? '';
        _secretIdController.text = asrConfig['secretId'] as String? ?? '';
        _secretKeyController.text = asrConfig['secretKey'] as String? ?? '';
      }

      // 加载工具模版设置
      _preferToolTemplates = settings['preferToolTemplates'] as bool? ?? false;
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
      final asrConfig = {
        'appId': _appIdController.text.trim(),
        'secretId': _secretIdController.text.trim(),
        'secretKey': _secretKeyController.text.trim(),
        'sampleRate': 16000,
        'engineModelType': '16k_zh',
        'needVad': false,
        'filterDirty': 0,
        'wordInfo': false,
      };

      debugPrint('🔧 [设置页面] 准备保存配置: appId=${asrConfig['appId']}');
      await widget.plugin.updateSettings({
        'asrConfig': asrConfig,
        'preferToolTemplates': _preferToolTemplates,
      });

      // 验证保存后立即读取
      final savedConfig = widget.plugin.settings['asrConfig'];
      debugPrint('🔧 [设置页面] 保存后验证: $savedConfig');
      debugPrint('🔧 [设置页面] 工具模版设置: $_preferToolTemplates');

      setState(() {
        _hasChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('设置保存成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [设置页面] 保存失败: $e');
      _showError('保存设置失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试连接
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

      // 显示成功消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('配置验证通过！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('验证失败: $e');
    }
  }

  /// 显示错误
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 工具调用设置标题
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '工具调用设置',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        // 优先使用工具模版开关
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            child: SwitchListTile(
              title: const Text('优先使用工具模版'),
              subtitle: const Text(
                '开启后，AI 会优先尝试匹配已保存的工具模版，提升响应速度。如无匹配则继续正常的工具调用流程。',
              ),
              value: _preferToolTemplates,
              onChanged: (value) {
                setState(() {
                  _preferToolTemplates = value;
                  _hasChanges = true;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),

        // 语音识别设置标题
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '语音识别设置',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        // 说明文本
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '配置腾讯云实时语音识别服务，用于聊天界面的语音输入功能。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 获取凭证链接
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: InkWell(
            onTap: () {
              // TODO: 打开浏览器到腾讯云控制台
            },
            child: Text(
              '如何获取 API 凭证？',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 表单
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

                        const SizedBox(height: 24),

                        // 引擎配置说明
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '识别引擎配置',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '当前使用默认配置：',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• 采样率：16000 Hz\n'
                                  '• 引擎模型：16k_zh（中文普通话）\n'
                                  '• VAD 人声检测：关闭\n'
                                  '• 脏词过滤：关闭',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 操作按钮
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _testConnection,
                                child: const Text('测试配置'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: _hasChanges ? _saveSettings : null,
                                child: const Text('保存设置'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }
}
