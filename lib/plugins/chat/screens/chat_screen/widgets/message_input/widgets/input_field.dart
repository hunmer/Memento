import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode keyboardListenerFocusNode;
  final Function(String) onChanged;
  final Function(KeyEvent) onKeyEvent;

  const InputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.keyboardListenerFocusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    // 获取屏幕高度，用于计算输入框的最大高度
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight / 2; // 最大高度为屏幕高度的一半

    return KeyboardListener(
      focusNode: keyboardListenerFocusNode,
      onKeyEvent:
          Platform.isMacOS || Platform.isWindows || Platform.isLinux
              ? onKeyEvent
              : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight, // 限制最大高度
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: ChatLocalizations.of(context).enterMessage,
            hintStyle: TextStyle(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            // 确保内容不会被裁剪
            isCollapsed: false,
          ),
          maxLines: null, // 允许多行
          minLines: 1, // 最少显示1行
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          focusNode: focusNode,
          scrollPhysics: const ClampingScrollPhysics(), // 添加滚动物理效果
        ),
      ),
    );
  }
}
