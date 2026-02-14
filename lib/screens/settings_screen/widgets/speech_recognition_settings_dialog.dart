import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/services/speech_recognition_config_service.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/agent_chat/services/speech/speech_recognition_config.dart';
import 'package:Memento/plugins/openai/screens/agent_edit_screen.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/controllers/agent_controller.dart';
import 'package:uuid/uuid.dart';

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

  // AI纠错Agent相关
  String? _correctionAgentId;
  String _correctionAgentName = '';
  bool _isLoadingAgent = false;

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

      // 加载AI纠错Agent信息
      _correctionAgentId = SpeechRecognitionConfigService.instance.correctionAgentId;
      if (_correctionAgentId != null && _correctionAgentId!.isNotEmpty) {
        await _loadAgentInfo(_correctionAgentId!);
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

  /// 加载Agent信息
  Future<void> _loadAgentInfo(String agentId) async {
    try {
      setState(() {
        _isLoadingAgent = true;
      });

      final agentController = AgentController();
      final agent = await agentController.getAgent(agentId);
      if (agent != null && mounted) {
        setState(() {
          _correctionAgentName = agent.name;
        });
      }
    } catch (e) {
      debugPrint('加载Agent信息失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAgent = false;
        });
      }
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

  /// 配置AI纠错Agent
  Future<void> _configureCorrectionAgent() async {
    AIAgent? agentToEdit;

    // 如果已有保存的Agent，先加载它
    if (_correctionAgentId != null && _correctionAgentId!.isNotEmpty) {
      try {
        setState(() {
          _isLoadingAgent = true;
        });
        final agentController = AgentController();
        agentToEdit = await agentController.getAgent(_correctionAgentId!);
        if (agentToEdit == null) {
          _showError('未找到已保存的AI纠错Agent，将创建新的配置');
        }
      } catch (e) {
        _showError('加载Agent失败: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingAgent = false;
          });
        }
      }
    }

    // 如果没有加载到Agent，创建默认的
    agentToEdit ??= AIAgent(
      id: _correctionAgentId ?? const Uuid().v4(),
      name: _correctionAgentName.isNotEmpty ? _correctionAgentName : '语音文本纠错',
      description: '用于自动纠正语音识别错误的AI助手',
      tags: const ['语音纠错'],
      serviceProviderId: 'openai',
      baseUrl: '',
      headers: const {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      model: 'gpt-4o-mini',
      temperature: 0.3,
      maxLength: 2000,
      topP: 1.0,
      frequencyPenalty: 0.0,
      presencePenalty: 0.0,
      messages: [
        Prompt(
          type: 'system',
          content: '你是一个专业的语音文本纠错助手。你的任务是纠正语音识别中的错误。\n\n## 工作流程\n1. 分析用户输入的文本\n2. 识别可能的识别错误（同音字、语法错误、标点错误等）\n3. 纠正错误，保持原意不变\n4. 只输出纠正后的文本，不要添加任何解释或说明\n\n## 注意事项\n- 只处理明显的识别错误\n- 保持口语化表达的自然流畅\n- 适当添加标点符号以提高可读性\n- 不要改变原文的意思\n- 如果文本本身就没有错误，直接返回原文',
        ),
      ],
    );

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AgentEditScreen(agent: agentToEdit),
      ),
    );

    // 如果用户保存了Agent，保存Agent ID
    if (result == true) {
      try {
        final agentController = AgentController();
        // 使用Agent的ID重新加载最新配置
        final savedAgent = await agentController.getAgent(agentToEdit.id);

        if (savedAgent == null) {
          _showError('未找到保存的Agent');
          return;
        }

        if (mounted) {
          await SpeechRecognitionConfigService.instance.saveCorrectionAgentId(savedAgent.id);
          setState(() {
            _correctionAgentId = savedAgent.id;
            _correctionAgentName = savedAgent.name;
          });
          toastService.showToast('AI纠错Agent设置成功');
        }
      } catch (e) {
        _showError('保存AI纠错Agent失败: $e');
      }
    }
  }

  /// 清除AI纠错Agent
  Future<void> _clearCorrectionAgent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除AI纠错Agent设置吗？'),
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
      ),
    );

    if (confirmed == true) {
      try {
        await SpeechRecognitionConfigService.instance.saveCorrectionAgentId(null);
        setState(() {
          _correctionAgentId = null;
          _correctionAgentName = '';
        });
        toastService.showToast('已清除AI纠错Agent设置');
      } catch (e) {
        _showError('清除设置失败: $e');
      }
    }
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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // AI智能纠错设置
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(Icons.auto_fix_high, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'AI智能纠错',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: _isLoadingAgent
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _correctionAgentId != null && _correctionAgentName.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  child: Text(_correctionAgentName.isNotEmpty
                                      ? _correctionAgentName[0]
                                      : 'A'),
                                ),
                                title: Text(_correctionAgentName),
                                subtitle: const Text('已配置AI纠错助手'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: _clearCorrectionAgent,
                                  tooltip: '清除',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        icon: const Icon(Icons.edit),
                                        label: const Text('编辑AI纠错Agent'),
                                        onPressed: _configureCorrectionAgent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '配置AI助手来自动纠正语音识别中的错误',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('配置AI纠错Agent'),
                                  onPressed: _configureCorrectionAgent,
                                ),
                              ],
                            ),
                          ),
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
