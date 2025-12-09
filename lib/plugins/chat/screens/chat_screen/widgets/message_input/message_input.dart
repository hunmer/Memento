import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'message_input_types.dart';
import 'message_input_state.dart';
import 'package:Memento/plugins/openai/widgets/agent_list_drawer.dart';
import 'widgets/metadata_display.dart';
import 'widgets/input_field.dart';
import 'widgets/send_button.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/widgets/message_input_actions/message_input_actions_drawer.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/widgets/message_input_actions/message_input_actions_builder.dart';
import 'package:Memento/plugins/chat/models/message.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final OnSendMessage onSendMessage;
  final Function(String) onSaveDraft;
  final Message? replyTo;
  final FocusNode? focusNode;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSendMessage,
    required this.onSaveDraft,
    this.replyTo,
    this.focusNode,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late FocusNode _focusNode;
  late FocusNode _keyboardListenerFocusNode;
  List<Map<String, String>> selectedAgents = [];
  bool showAgentList = false;
  Map<String, dynamic>? selectedFile;
  int contextRange = 10; // 默认上下文范围为10

  late MessageInputState _messageInputState;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _keyboardListenerFocusNode = FocusNode();

    // 加载频道的元数据
    _loadChannelMetadata();

    _updateMessageInputState();

    widget.controller.addListener(_onTextChanged);
  }

  // 加载频道元数据
  void _loadChannelMetadata() {
    if (ChatPlugin.instance.channelService.currentChannel != null) {
      final currentChannel = ChatPlugin.instance.channelService.currentChannel!;
      final metadata = currentChannel.metadata;

      if (metadata != null) {
        // 加载保存的智能体列表
        final savedAgents = metadata['selectedAgents'] as List<dynamic>?;
        if (savedAgents != null) {
          selectedAgents =
              savedAgents
                  .map((agent) => Map<String, String>.from(agent))
                  .toList();
        }

        // 加载保存的上下文范围
        final savedContextRange = metadata['contextRange'] as int?;
        if (savedContextRange != null) {
          contextRange = savedContextRange;
        }
      }
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _keyboardListenerFocusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    widget.onSaveDraft(widget.controller.text);
    if (widget.controller.text.endsWith('@')) {
      setState(() {
        showAgentList = true;
      });
      _showAgentListDrawer();
    }
  }

  void _showAgentListDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => AgentListDrawer(
            selectedAgents: selectedAgents,
            onAgentSelected: _handleAgentSelected,
            textController: widget.controller,
          ),
    );
  }

  void _handleAgentSelected(List<Map<String, String>> agents) {
    setState(() {
      selectedAgents = agents;
      showAgentList = false;
      _updateMessageInputState();
    });

    // 保存选择的智能体到频道元数据
    if (ChatPlugin.instance.channelService.currentChannel != null) {
      final channelId = ChatPlugin.instance.channelService.currentChannel!.id;
      ChatPlugin.instance.channelService.updateChannelMetadata(channelId, {
        'selectedAgents': agents,
      });
    }
  }

  void _handleContextRangeChange(int newRange) {
    setState(() {
      contextRange = newRange;
      _updateMessageInputState();
    });

    // 保存上下文范围到频道元数据
    if (ChatPlugin.instance.channelService.currentChannel != null) {
      final channelId = ChatPlugin.instance.channelService.currentChannel!.id;
      ChatPlugin.instance.channelService.updateChannelMetadata(channelId, {
        'contextRange': newRange,
      });
    }
  }

  void _handleFileSelected(Map<String, dynamic> file) {
    setState(() {
      selectedFile = file;
      _updateMessageInputState();
    });
  }

  void _updateMessageInputState() {
    _messageInputState = MessageInputState(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardListenerFocusNode: _keyboardListenerFocusNode,
      selectedAgents: selectedAgents,
      selectedFile: selectedFile,
      showAgentList: showAgentList,
      replyTo: widget.replyTo,
      metadata: {
        if (selectedAgents.isNotEmpty) 'contextCount': contextRange,
        if (selectedAgents.isNotEmpty) 'agents': selectedAgents,
        if (selectedFile != null) 'file': selectedFile,
      },
      onSaveDraft: widget.onSaveDraft,
      onSendMessage: widget.onSendMessage,
      onClearFile: _removeFile,
    );
  }

  void _removeAgent(String agentId) {
    setState(() {
      selectedAgents.removeWhere((agent) => agent['id'] == agentId);
      _updateMessageInputState();
    });

    // 更新频道元数据中的智能体列表
    if (ChatPlugin.instance.channelService.currentChannel != null) {
      final channelId = ChatPlugin.instance.channelService.currentChannel!.id;

      // 如果移除后没有选中的智能体，则清空元数据中的智能体列表和上下文范围
      if (selectedAgents.isEmpty) {
        ChatPlugin.instance.channelService.updateChannelMetadata(channelId, {
          'selectedAgents': [],
          'contextRange': null,
        });
      } else {
        // 否则只更新智能体列表
        ChatPlugin.instance.channelService.updateChannelMetadata(channelId, {
          'selectedAgents': selectedAgents,
        });
      }
    }
  }

  void _removeFile() {
    setState(() {
      selectedFile = null;
      _updateMessageInputState();
    });
  }

  void _handleSendMessage() {
    // 使用最新的状态创建一个新的 MessageInputState 实例
    _updateMessageInputState();
    _messageInputState.sendMessage();

    // 发送后更新UI状态
    if (selectedFile != null) {
      setState(() {
        selectedFile = null;
        _updateMessageInputState();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 元数据显示区域
          MetadataDisplay(
            selectedFile: selectedFile,
            selectedAgents: selectedAgents,
            onShowAgentListDrawer: _showAgentListDrawer,
            onFileRemove: _removeFile,
            onAgentRemove: _removeAgent,
            contextRange: contextRange,
            onContextRangeChange: _handleContextRangeChange,
          ),

          // 输入区域
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (context) => MessageInputActionsDrawer(
                          actions: MessageInputActionsBuilder.getDefaultActions(
                            context,
                            onFileSelected: _handleFileSelected,
                            textController: widget.controller,
                          ),
                          onFileSelected: _handleFileSelected,
                        ),
                  );
                },
              ),

              // 文本输入框
              Expanded(
                child: InputField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardListenerFocusNode: _keyboardListenerFocusNode,
                  onChanged: (text) => widget.onSaveDraft(text),
                  onKeyEvent:
                      (event) => _messageInputState.handleKeyPress(event),
                ),
              ),

              // 发送按钮
              Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                child: SendButton(onPressed: _handleSendMessage),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
