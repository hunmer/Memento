import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform, Process;
import '../../../../../core/event/event.dart';
import 'message_input_actions/message_input_actions_drawer.dart';
import 'message_input_actions/message_input_actions_builder.dart';
import '../../../models/message.dart';
import '../../../models/user.dart';
import '../../../../openai/controllers/agent_controller.dart';
import '../../../../openai/models/ai_agent.dart';

// 定义发送消息的回调函数类型
typedef OnSendMessage =
    void Function(
      String content, {
      Map<String, dynamic>? metadata,
      String type,
      Message? replyTo,
    });

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final OnSendMessage onSendMessage;
  final Function(String) onSaveDraft;
  final Message? replyTo; // 添加回复消息引用
  final FocusNode? focusNode; // 添加焦点节点

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
  Map<String, dynamic>? selectedFile; // 存储选中的文件信息

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _keyboardListenerFocusNode = FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _keyboardListenerFocusNode.dispose();
    super.dispose();
  }

  // 统一的发送消息方法
  void _sendMessage() async {
    final messageText = widget.controller.text.trim();
    final hasFile = selectedFile != null;
    final hasMessage = messageText.isNotEmpty;

    if (hasFile || hasMessage) {
      // 如果有文件，先发送文件
      if (hasFile && selectedFile != null) {
        final fileInfo = selectedFile!['fileInfo'] as Map<String, dynamic>?;
        if (fileInfo != null) {
          widget.onSendMessage(
            fileInfo['path'] as String,
            type: fileInfo['type'] as String,
            metadata: selectedFile,
          );
          setState(() {
            selectedFile = null;
          });
        } else {
          debugPrint('文件路径或类型为空，无法发送文件');
        }
      }

      // 如果有消息文本，再发送消息
      if (hasMessage) {
        // 准备消息元数据，包含选中的智能体信息
        Map<String, dynamic>? metadata;
        if (selectedAgents.isNotEmpty) {
          metadata = {
            'agents':
                selectedAgents
                    .map((agent) => {'id': agent['id'], 'name': agent['name']})
                    .toList(),
          };
        }

        // 创建用户对象
        final user = User(id: 'user', username: 'User');

        // 创建消息对象
        final message = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: widget.controller.text.trim(),
          user: user,
          type: MessageType.sent,
          replyTo: widget.replyTo,
          metadata: metadata,
        );

        // 发送消息
        widget.onSendMessage(
          message.content,
          type: 'sent',
          replyTo: message.replyTo,
          metadata: message.metadata,
        );

        // 广播消息事件
        EventManager.instance.broadcast(
          'onMessageSent',
          Value<Message>(message),
        );

        widget.controller.clear();
        _focusNode.requestFocus(); // 保持焦点
      }
    }
  }

  KeyEventResult handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (HardwareKeyboard.instance.isControlPressed) {
          // Ctrl+Enter: 插入换行符
          final currentText = widget.controller.text;
          final selection = widget.controller.selection;
          final newText = currentText.replaceRange(
            selection.start,
            selection.end,
            '\n',
          );
          widget.controller.value = widget.controller.value.copyWith(
            text: newText,
            selection: TextSelection.collapsed(offset: selection.start + 1),
          );
        } else if (!HardwareKeyboard.instance.isShiftPressed) {
          _sendMessage();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void showAgentListDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy),
                    const SizedBox(width: 8),
                    Text(
                      '选择智能体',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const Divider(),
              FutureBuilder<List<AIAgent>>(
                future: AgentController().loadAgents(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final agents = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: agents.length,
                      itemBuilder: (context, index) {
                        final agent = agents[index];
                        return ListTile(
                          leading: const Icon(Icons.smart_toy),
                          title: Text(agent.name),
                          subtitle: Text(agent.description),
                          onTap: () {
                            setState(() {
                              // 检查是否已经选中
                              final isAlreadySelected = selectedAgents.any(
                                (a) => a['id'] == agent.id,
                              );
                              if (!isAlreadySelected) {
                                selectedAgents.add({
                                  'id': agent.id,
                                  'name': agent.name,
                                });
                              }
                            });
                            Navigator.pop(context);
                            // 删除输入框中的@符号
                            if (widget.controller.text.endsWith('@')) {
                              widget.controller.text = widget.controller.text
                                  .substring(
                                    0,
                                    widget.controller.text.length - 1,
                                  );
                            }
                          },
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('加载智能体列表失败'),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ).then((_) {
      setState(() {
        showAgentList = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder:
                            (context) => MessageInputActionsDrawer(
                              actions:
                                  MessageInputActionsBuilder.getDefaultActions(
                                    context,
                                    onFileSelected: (fileMessage) {
                                      setState(() {
                                        selectedFile = fileMessage;
                                      });
                                    },
                                  ),
                            ),
                      );
                    },
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                  ),
                  Expanded(
                    child: KeyboardListener(
                      focusNode: _keyboardListenerFocusNode,
                      onKeyEvent:
                          Platform.isMacOS ||
                                  Platform.isWindows ||
                                  Platform.isLinux
                              ? handleKeyPress
                              : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // metadata展示区域，展示选中的文件和智能体
                          if (selectedFile != null || selectedAgents.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  // 文件状态展示
                                  if (selectedFile != null)
                                    Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                        onTap: () async {
                                          // 预览文件
                                          if (selectedFile != null) {
                                            final fileInfo =
                                                selectedFile!['fileInfo']
                                                    as Map<String, dynamic>?;
                                            if (fileInfo != null &&
                                                fileInfo['path'] != null) {
                                              final filePath =
                                                  fileInfo['path'] as String;
                                              if (Platform.isWindows) {
                                                Process.run('explorer', [
                                                  filePath,
                                                ]);
                                              } else if (Platform.isMacOS) {
                                                Process.run('open', [filePath]);
                                              } else if (Platform.isLinux) {
                                                Process.run('xdg-open', [
                                                  filePath,
                                                ]);
                                              }
                                            }
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                (selectedFile!['fileInfo']?['type']
                                                            as String?) ==
                                                        'image'
                                                    ? Icons.image
                                                    : Icons.insert_drive_file,
                                                size: 20,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '1个文件',
                                                style: TextStyle(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                  // 文件关闭按钮
                                  if (selectedFile != null)
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          selectedFile = null;
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),

                                  // 如果两者都存在，添加一个间隔
                                  if (selectedFile != null &&
                                      selectedAgents.isNotEmpty)
                                    const SizedBox(width: 8),

                                  // 智能体状态展示
                                  if (selectedAgents.isNotEmpty)
                                    Expanded(
                                      flex: 2,
                                      child: GestureDetector(
                                        onTap: showAgentListDrawer,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Wrap(
                                            spacing: 8,
                                            children:
                                                selectedAgents.map((agent) {
                                                  return Chip(
                                                    avatar: const Icon(
                                                      Icons.smart_toy,
                                                      size: 18,
                                                    ),
                                                    label: Text(
                                                      agent['name'] ?? '',
                                                    ),
                                                    onDeleted: () {
                                                      setState(() {
                                                        selectedAgents
                                                            .removeWhere(
                                                              (a) =>
                                                                  a['id'] ==
                                                                  agent['id'],
                                                            );
                                                      });
                                                    },
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primaryContainer,
                                                    labelStyle: TextStyle(
                                                      color:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .onPrimaryContainer,
                                                    ),
                                                  );
                                                }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          TextField(
                            controller: widget.controller,
                            onChanged: (value) {
                              widget.onSaveDraft(value);
                              if (value.endsWith('@')) {
                                setState(() {
                                  showAgentList = true;
                                });
                                showAgentListDrawer();
                              }
                            },
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: '输入消息...',
                              hintStyle: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.none,
                            focusNode: _focusNode,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Container(
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.send,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20, // 适当调整图标大小
                        ),
                      ),
                      onPressed: _sendMessage,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
