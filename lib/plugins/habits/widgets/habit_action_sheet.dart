import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

/// 习惯操作抽屉
///
/// 显示习惯的操作选项：编辑、删除
class HabitActionSheet extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HabitActionSheet({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  /// 显示习惯操作抽屉
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) async {
    await Navigator.of(context).push(
      ModalSheetRoute(
        swipeDismissible: true,
        builder: (context) => Sheet(
          child: HabitActionSheet(
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示器
            _buildDragHandle(theme),

            // 标题
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                'habits_habitActions'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Divider(height: 1),

            // 编辑选项
            _buildActionItem(
              context,
              icon: Icons.edit,
              label: 'habits_editHabit'.tr,
              color: Colors.blue,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),

            // 删除选项
            _buildActionItem(
              context,
              icon: Icons.delete,
              label: 'habits_delete'.tr,
              color: Colors.red,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),

            // 取消按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('habits_cancel'.tr),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建拖拽指示器
  Widget _buildDragHandle(ThemeData theme) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// 构建操作项
  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // 图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),

              // 标签
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ),

              // 箭头
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
