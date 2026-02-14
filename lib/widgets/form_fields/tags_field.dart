import 'package:flutter/material.dart';
import 'package:lpinyin/lpinyin.dart';

/// 标签选择组件
///
/// 功能特性：
/// - 显示已选标签的Chips
/// - 内嵌输入框，回车完成添加
/// - 支持删除标签
/// - 支持快捷选择标签
/// - 支持字母过滤（A-Z 和中文拼音首字母）
class TagsField extends StatefulWidget {
  /// 已选标签列表
  final List<String> tags;

  /// 添加标签的回调
  final Function(String tag) onAddTag;

  /// 删除标签的回调
  final Function(String tag) onRemoveTag;

  /// 添加按钮的文本
  final String addButtonText;

  /// 主题色
  final Color primaryColor;

  /// 快捷选择标签列表（点击可快速添加到已选标签）
  final List<String>? quickSelectTags;

  /// 快捷选择标签的回调
  final Function(String tag)? onQuickSelectTag;

  const TagsField({
    super.key,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.addButtonText,
    this.primaryColor = const Color(0xFF607AFB),
    this.quickSelectTags,
    this.onQuickSelectTag,
  });

  @override
  State<TagsField> createState() => _TagsFieldState();
}

class _TagsFieldState extends State<TagsField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isEditing = false;
  String? _filterLetter; // 当前过滤的字母，null 表示显示所有

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    _focusNode.requestFocus();
  }

  void _submitTag() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onAddTag(text);
      _controller.clear();
    }
    setState(() {
      _isEditing = false;
    });
    _focusNode.unfocus();
  }

  /// 获取标签的拼音首字母（大写）
  String _getPinyinFirstLetter(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return '';

    // 判断是否为英文字母
    if (trimmed[0].contains(RegExp(r'[a-zA-Z]'))) {
      return trimmed[0].toUpperCase();
    }

    // 使用 lpinyin 获取中文拼音首字母
    final pinyin = PinyinHelper.getFirstWordPinyin(trimmed);
    if (pinyin != null && pinyin.isNotEmpty) {
      return pinyin[0].toUpperCase();
    }

    return '';
  }

  /// 获取待选标签的首字母集合（已排序）
  Set<String> _getAvailableLetters() {
    if (widget.quickSelectTags == null) return {};
    return widget.quickSelectTags!
        .where((tag) => !widget.tags.contains(tag)) // 排除已选标签
        .map((tag) => _getPinyinFirstLetter(tag))
        .where((letter) => letter.isNotEmpty)
        .toSet();
  }

  /// 根据当前过滤条件获取显示的待选标签列表
  List<String> _getFilteredQuickSelectTags() {
    if (widget.quickSelectTags == null) return [];
    final unselectedTags = widget.quickSelectTags!
        .where((tag) => !widget.tags.contains(tag))
        .toList();
    if (_filterLetter == null) {
      return unselectedTags;
    }
    return unselectedTags
        .where((tag) => _getPinyinFirstLetter(tag) == _filterLetter)
        .toList();
  }

  /// 过滤标签
  void _filterByLetter(String? letter) {
    setState(() {
      _filterLetter = letter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableLetters = _getAvailableLetters();
    final filteredQuickSelectTags = _getFilteredQuickSelectTags();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 已选标签区域
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 已选标签区域
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _isEditing
                      ? Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Container(
                                  constraints: const BoxConstraints(minWidth: 80),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    autofocus: true,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      hintText: '输入标签',
                                      hintStyle: TextStyle(fontSize: 12),
                                    ),
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _submitTag(),
                                    onEditingComplete: _submitTag,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _controller.clear();
                                  setState(() => _isEditing = false);
                                  _focusNode.unfocus();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : InkWell(
                          onTap: _startEditing,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.addButtonText,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ...widget.tags.map((tag) => _buildTagChip(tag, theme)),
                ],
              ),
              // A-Z 过滤器按钮（仅在有待选标签时显示）
              if (availableLetters.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableLetters.length + 1, // +1 为"全部"按钮
                    separatorBuilder: (context, index) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // 全部按钮
                        final isSelected = _filterLetter == null;
                        return _buildFilterButton(
                          theme,
                          '全部',
                          isSelected,
                          () => _filterByLetter(null),
                        );
                      }
                      // A-Z 按钮按字母排序
                      final letters = availableLetters.toList()..sort();
                      final letter = letters[index - 1];
                      final isSelected = _filterLetter == letter;
                      return _buildFilterButton(
                        theme,
                        letter,
                        isSelected,
                        () => _filterByLetter(letter),
                      );
                    },
                  ),
                ),
              ],
              // 快捷选择标签区域
              if (filteredQuickSelectTags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filteredQuickSelectTags
                      .map((tag) => _buildQuickSelectChip(tag, theme))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 构建已选标签的 Chip
  Widget _buildTagChip(String tag, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => widget.onRemoveTag(tag),
            child: Icon(
              Icons.close,
              size: 14,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建快捷选择标签的 Chip
  Widget _buildQuickSelectChip(String tag, ThemeData theme) {
    return InkWell(
      onTap: () => widget.onQuickSelectTag?.call(tag),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 构建字母过滤器按钮
  Widget _buildFilterButton(
    ThemeData theme,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          border: Border.all(
            color:
                isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
