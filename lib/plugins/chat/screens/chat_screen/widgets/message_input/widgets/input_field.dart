import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode keyboardListenerFocusNode;
  final Function(String) onChanged;
  final Function(KeyEvent) onKeyEvent;

  const InputField({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.keyboardListenerFocusNode,
    required this.onChanged,
    required this.onKeyEvent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: keyboardListenerFocusNode,
      onKeyEvent: Platform.isMacOS || Platform.isWindows || Platform.isLinux
          ? onKeyEvent
          : null,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.none,
        focusNode: focusNode,
      ),
    );
  }
}