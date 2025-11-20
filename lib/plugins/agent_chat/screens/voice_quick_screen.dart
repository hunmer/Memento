import 'package:flutter/material.dart';
import 'package:Memento/plugins/agent_chat/agent_chat_plugin.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:Memento/plugins/agent_chat/screens/chat_screen/components/voice_input_dialog.dart';
import 'package:Memento/plugins/agent_chat/services/speech/tencent_asr_service.dart';
import 'package:Memento/plugins/agent_chat/services/speech/speech_recognition_config.dart';

/// AI语音快速输入界面
///
/// 从桌面小组件跳转时使用，自动打开指定对话的语音输入对话框
class VoiceQuickScreen extends StatefulWidget {
  final String? conversationId;

  const VoiceQuickScreen({super.key, this.conversationId});

  @override
  State<VoiceQuickScreen> createState() => _VoiceQuickScreenState();
}

class _VoiceQuickScreenState extends State<VoiceQuickScreen> {
  Conversation? _targetConversation;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    try {
      final plugin = AgentChatPlugin.instance;

      if (widget.conversationId == null || widget.conversationId!.isEmpty) {
        // 如果没有指定对话ID，显示对话列表让用户选择
        setState(() {
          _loading = false;
        });
        return;
      }

      // 查找指定的对话
      final conversation = plugin.conversationController.conversations
          .firstWhere((c) => c.id == widget.conversationId);

      setState(() {
        _targetConversation = conversation;
        _loading = false;
      });

      // 延迟一帧后打开语音输入对话框
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openVoiceInput();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '对话不存在或已被删除';
        _loading = false;
      });
    }
  }

  Future<void> _openVoiceInput() async {
    if (_targetConversation == null) return;

    try {
      // 获取插件实例
      final plugin = AgentChatPlugin.instance;

      // 读取配置
      final settings = plugin.settings;
      final speechConfig = settings['speech'] as Map<String, dynamic>? ?? {};

      // 检查是否配置了腾讯云 ASR
      final appId = speechConfig['appId'] as String?;
      final secretId = speechConfig['secretId'] as String?;
      final secretKey = speechConfig['secretKey'] as String?;

      if (appId == null ||
          secretId == null ||
          secretKey == null ||
          appId.isEmpty ||
          secretId.isEmpty ||
          secretKey.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('请先在设置中配置语音识别服务'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // 创建识别配置
      final config = TencentASRConfig(
        appId: appId,
        secretId: secretId,
        secretKey: secretKey,
        sampleRate: (speechConfig['sampleRate'] as num?)?.toInt() ?? 16000,
        engineModelType: speechConfig['engineModelType'] as String? ?? '16k_zh',
        needVad: speechConfig['needVad'] as bool? ?? false,
      );

      // 创建识别服务
      final recognitionService = TencentASRService(config: config);

      // 显示语音输入对话框
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => VoiceInputDialog(
                recognitionService: recognitionService,
                onRecognitionComplete: (text) {
                  // 这里只是接收识别的文本，不做处理
                  // 用户需要在聊天界面手动发送
                },
              ),
        );
      }

      // 对话框关闭后返回
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('语音识别失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('正在加载...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('错误')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    // 如果没有指定对话，显示对话选择界面
    return Scaffold(
      appBar: AppBar(title: const Text('选择对话')),
      body: _buildConversationList(),
    );
  }

  Widget _buildConversationList() {
    final plugin = AgentChatPlugin.instance;
    final conversations = plugin.conversationController.conversations;

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text('暂无对话', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('请先创建对话', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const Icon(Icons.mic),
          ),
          title: Text(conversation.title),
          subtitle:
              conversation.lastMessagePreview != null &&
                      conversation.lastMessagePreview!.isNotEmpty
                  ? Text(
                    conversation.lastMessagePreview!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                  : null,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            setState(() {
              _targetConversation = conversation;
            });
            _openVoiceInput();
          },
        );
      },
    );
  }
}
