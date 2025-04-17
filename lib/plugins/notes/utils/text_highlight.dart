import 'package:flutter/material.dart';

class TextHighlight {
  static TextSpan highlightText(
    String text,
    String query, {
    TextStyle? baseStyle,
    TextStyle? highlightStyle,
    int maxLength = 100,
  }) {
    if (query.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    final matches = lowercaseQuery.allMatches(lowercaseText);

    if (matches.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    // Find the first match
    final firstMatch = matches.first;
    
    // Calculate the start and end indices for the excerpt
    int start = firstMatch.start - 20;
    start = start < 0 ? 0 : start;
    int end = firstMatch.end + 20;
    end = end > text.length ? text.length : end;

    // Add ellipsis if needed
    final prefix = start > 0 ? '...' : '';
    final suffix = end < text.length ? '...' : '';

    // Extract the excerpt
    final excerpt = text.substring(start, end);
    final excerptLowercase = excerpt.toLowerCase();
    final excerptMatches = lowercaseQuery.allMatches(excerptLowercase);

    final List<TextSpan> children = [];
    int lastIndex = 0;

    if (prefix.isNotEmpty) {
      children.add(TextSpan(text: prefix, style: baseStyle));
    }

    for (final match in excerptMatches) {
      if (match.start > lastIndex) {
        children.add(TextSpan(
          text: excerpt.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }
      children.add(TextSpan(
        text: excerpt.substring(match.start, match.end),
        style: highlightStyle ??
            TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < excerpt.length) {
      children.add(TextSpan(
        text: excerpt.substring(lastIndex),
        style: baseStyle,
      ));
    }

    if (suffix.isNotEmpty) {
      children.add(TextSpan(text: suffix, style: baseStyle));
    }

    return TextSpan(children: children);
  }
}