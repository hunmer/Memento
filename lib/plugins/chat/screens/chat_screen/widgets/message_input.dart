import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSendMessage;
  final Function(String) onSaveDraft;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSendMessage,
    required this.onSaveDraft,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late FocusNode _focusNode;
  late FocusNode _keyboardListenerFocusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _keyboardListenerFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyPress(KeyEvent event) {
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
            selection: TextSelection.collapsed(
              offset: selection.start + 1,
            ),
          );
        } else if (!HardwareKeyboard.instance.isShiftPressed) {
          // Enter (不按Shift): 发送消息
          if (widget.controller.text.trim().isNotEmpty) {
            widget.onSendMessage(widget.controller.text.trim());
            widget.controller.clear();
            // 保持焦点但阻止换行
            _focusNode.requestFocus();
          }
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: KeyboardListener(
                focusNode: _keyboardListenerFocusNode,
                onKeyEvent: Platform.isMacOS || Platform.isWindows || Platform.isLinux
                    ? _handleKeyPress
                    : null,
                child: TextField(
                  controller: widget.controller,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onChanged: widget.onSaveDraft,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.none,
                  focusNode: _focusNode,
                ),
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
              icon: Icon(
                Icons.send,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                if (widget.controller.text.trim().isNotEmpty) {
                  widget.onSendMessage(widget.controller.text.trim());
                  widget.controller.clear();
                  _focusNode.requestFocus(); // 保持焦点
                }
              },
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}