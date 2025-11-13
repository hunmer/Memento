import 'package:flutter/material.dart';
import '../controllers/timeline_controller.dart';
import '../../../l10n/chat_localizations.dart';
import '../../../chat_plugin.dart';
import './filter_dialog.dart';
import '../models/timeline_filter.dart';

/// Timeline 顶部的搜索栏
class TimelineSearchBar extends StatelessWidget {
  final TimelineController controller;
  final ChatPlugin chatPlugin;

  const TimelineSearchBar({
    super.key,
    required this.controller,
    required this.chatPlugin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = ChatLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 搜索输入框
          Expanded(
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clearSearch(); // 使用公开方法清空搜索
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          
          // 高级过滤器按钮
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.filter_list),
                  if (controller.isFilterActive)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: l10n.advancedFilter,
              onPressed: () => _showFilterDialog(context),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 显示高级过滤器对话框
  Future<void> _showFilterDialog(BuildContext context) async {
    final result = await showDialog<TimelineFilter>(
      context: context,
      builder: (context) => FilterDialog(
        filter: controller.filter,
        chatPlugin: chatPlugin,
      ),
    );
    
    if (result != null) {
      controller.applyFilter(result);
    }
  }
}