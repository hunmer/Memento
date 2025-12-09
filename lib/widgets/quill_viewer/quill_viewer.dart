import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Quill 内容查看器（只读模式）
/// 用于显示 Quill Delta 格式的内容
class QuillViewer extends StatelessWidget {
  /// 内容数据，支持 JSON Delta 格式或纯文本
  final String data;

  /// 是否可选择文本
  final bool selectable;

  /// 自定义样式
  final quill.DefaultStyles? customStyles;

  const QuillViewer({
    super.key,
    required this.data,
    this.selectable = true,
    this.customStyles,
  });

  quill.Document _parseDocument() {
    if (data.isEmpty) {
      return quill.Document();
    }

    try {
      // 尝试解析 JSON Delta 格式
      final json = jsonDecode(data);
      return quill.Document.fromJson(json);
    } catch (e) {
      // 如果不是 JSON，作为纯文本处理
      final document = quill.Document();
      document.insert(0, data);
      return document;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final document = _parseDocument();
      final controller = quill.QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );

      return quill.QuillEditor.basic(
        controller: controller,
      );
    } catch (e) {
      // 如果渲染失败，显示纯文本
      if (selectable) {
        return SelectableText(
          data,
          style: const TextStyle(fontSize: 14),
        );
      } else {
        return Text(
          data,
          style: const TextStyle(fontSize: 14),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        );
      }
    }
  }
}
