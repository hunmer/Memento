import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 文本高亮工具类
class TextHighlight {
  /// 将文本中的搜索关键词高亮显示
  /// 
  /// [text] 原始文本
  /// [query] 搜索关键词
  /// [style] 基础文本样式
  /// [highlightStyle] 高亮文本样式
  /// [caseSensitive] 是否区分大小写
  static List<TextSpan> highlightText({
    required String text,
    required String query,
    required TextStyle style,
    TextStyle? highlightStyle,
    bool caseSensitive = false,
  }) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    final spans = <TextSpan>[];
    final String textToSearch = caseSensitive ? text : text.toLowerCase();
    final String queryToSearch = caseSensitive ? query : query.toLowerCase();
    
    int start = 0;
    int indexOfHighlight;
    
    // 设置默认高亮样式
    final effectiveHighlightStyle = highlightStyle ?? 
        style.copyWith(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        );

    // 查找所有匹配项并创建相应的TextSpan
    while (true) {
      indexOfHighlight = textToSearch.indexOf(queryToSearch, start);
      if (indexOfHighlight < 0) {
        // 没有更多匹配项，添加剩余文本
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: style,
          ));
        }
        break;
      }

      // 添加匹配项之前的普通文本
      if (indexOfHighlight > start) {
        spans.add(TextSpan(
          text: text.substring(start, indexOfHighlight),
          style: style,
        ));
      }

      // 添加高亮文本
      final highlightEnd = indexOfHighlight + queryToSearch.length;
      spans.add(TextSpan(
        text: text.substring(indexOfHighlight, highlightEnd),
        style: effectiveHighlightStyle,
      ));

      start = highlightEnd;
    }

    return spans;
  }
}