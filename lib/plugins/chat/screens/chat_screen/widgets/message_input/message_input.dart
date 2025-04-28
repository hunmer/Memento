import 'package:flutter/material.dart';
import 'message_input_types.dart';
import 'message_input_state.dart';
import 'widgets/agent_list_drawer.dart';
import 'widgets/metadata_display.dart';
import 'widgets/input_field.dart';
import 'widgets/send_button.dart';
import '../message_input_actions/message_input_actions_drawer.dart';
import '../message_input_actions/message_input_actions_builder.dart';
import '../../../../models/message.dart';

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

  late MessageInputState _messageInputState;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _keyboardListenerFocusNode = FocusNode();

    _updateMessageInputState();

    widget.controller.addListener(_onTextChanged);
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

  void _handleAgentSelected(Map<String, String> agent) {
    setState(() {
      if (!selectedAgents.any((a) => a['id'] == agent['id'])) {
        selectedAgents.add(agent);
      }
      showAgentList = false;
      _updateMessageInputState();
    });
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
          ),

          // 输入区域
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 添加文件按钮
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
