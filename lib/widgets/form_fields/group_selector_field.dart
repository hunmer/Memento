import 'package:flutter/material.dart';
import 'package:Memento/widgets/group_selector_dialog.dart';

/// 分组选择器字段组件
///
/// 集成 GroupSelectorDialog，提供分组选择、新建、重命名、删除功能
class GroupSelectorField extends StatelessWidget {
  /// 可选分组列表
  final List<String> groups;

  /// 当前选中的分组
  final String? selectedGroup;

  /// 分组变更回调
  final ValueChanged<String?>? onGroupChanged;

  /// 分组重命名回调
  final OnGroupRenamed? onGroupRenamed;

  /// 分组删除回调
  final OnGroupDeleted? onGroupDeleted;

  /// 是否启用
  final bool enabled;

  /// 字段标签
  final String? labelText;

  /// 占位提示
  final String? hintText;

  const GroupSelectorField({
    super.key,
    required this.groups,
    this.selectedGroup,
    this.onGroupChanged,
    this.onGroupRenamed,
    this.onGroupDeleted,
    this.enabled = true,
    this.labelText,
    this.hintText = '选择分组',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              labelText!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ),
        InkWell(
          onTap: enabled ? () => _showGroupSelector(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              border: Border.all(
                color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedGroup ?? hintText!,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showGroupSelector(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => GroupSelectorDialog(
          groups: groups,
          initialSelectedGroup: selectedGroup,
          onGroupRenamed: onGroupRenamed ?? (_, __) {},
          onGroupDeleted: onGroupDeleted ?? (_) {},
        ),
      ),
    );

    if (result != null) {
      onGroupChanged?.call(result);
    }
  }
}
