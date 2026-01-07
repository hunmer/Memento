import 'package:flutter/material.dart';
import '../models/models.dart';

/// 底部抽屉菜单
class BottomSheetMenu extends StatelessWidget {
  /// 标签
  final TagItem tag;

  /// 编辑回调
  final VoidCallback onEdit;

  /// 删除回调
  final VoidCallback onDelete;

  /// 配置
  final TagsDialogConfig config;

  const BottomSheetMenu({
    super.key,
    required this.tag,
    required this.onEdit,
    required this.onDelete,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖动指示器
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 标签信息
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    tag.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (tag.comment != null && tag.comment!.isNotEmpty)
                          Text(
                            tag.comment!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1),

            // 操作按钮
            _buildMenuItem(
              context,
              icon: Icons.edit,
              title: config.editButtonText,
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.delete,
              title: config.deleteButtonText,
              iconColor: Theme.of(context).colorScheme.error,
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? Theme.of(context).colorScheme.onSurface,
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: iconColor ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
