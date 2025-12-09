import 'package:flutter/material.dart';

/// 选择器搜索栏组件
class SelectorSearchBar extends StatefulWidget {
  /// 搜索提示文本
  final String? hintText;

  /// 主题颜色
  final Color? themeColor;

  /// 搜索回调
  final ValueChanged<String> onSearch;

  /// 初始搜索文本
  final String? initialValue;

  /// 是否自动聚焦
  final bool autofocus;

  /// 搜索延迟（毫秒）
  final int debounceMs;

  const SelectorSearchBar({
    super.key,
    this.hintText,
    this.themeColor,
    required this.onSearch,
    this.initialValue,
    this.autofocus = false,
    this.debounceMs = 300,
  });

  @override
  State<SelectorSearchBar> createState() => _SelectorSearchBarState();
}

class _SelectorSearchBarState extends State<SelectorSearchBar> {
  late final TextEditingController _controller;
  String _lastSearch = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _lastSearch = widget.initialValue ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (value != _lastSearch) {
      _lastSearch = value;
      // 简单的防抖：直接调用，由调用方处理
      widget.onSearch(value);
    }
  }

  void _onClear() {
    _controller.clear();
    _lastSearch = '';
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.themeColor ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        decoration: InputDecoration(
          hintText: widget.hintText ?? '搜索...',
          prefixIcon: Icon(
            Icons.search,
            color: effectiveColor.withOpacity(0.7),
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _onClear,
                  tooltip: '清除',
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: effectiveColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: _onChanged,
        textInputAction: TextInputAction.search,
        onSubmitted: widget.onSearch,
      ),
    );
  }
}
