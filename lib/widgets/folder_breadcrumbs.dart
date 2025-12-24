import 'package:flutter/material.dart';

/// 通用的文件夹面包屑导航组件
///
/// 用于显示当前所在的文件夹层级结构,并支持点击定位到特定文件夹
///
/// 示例:
/// ```dart
/// FolderBreadcrumbs(
///   folders: [
///     FolderBreadcrumbItem(id: 'root', name: '全部'),
///     FolderBreadcrumbItem(id: '1', name: '工作'),
///     FolderBreadcrumbItem(id: '2', name: '项目A'),
///   ],
///   onFolderTap: (folderId) {
///     // 处理点击事件,例如过滤或导航
///   },
/// )
/// ```
class FolderBreadcrumbs extends StatelessWidget {
  /// 文件夹层级列表,从根文件夹到当前文件夹
  final List<FolderBreadcrumbItem> folders;

  /// 点击文件夹时的回调,传递被点击的文件夹ID
  final void Function(String folderId) onFolderTap;

  /// 分隔符样式
  final IconData separatorIcon;

  /// 分隔符大小
  final double separatorSize;

  /// 文本样式
  final TextStyle? textStyle;

  /// 是否高亮最后一个项(当前文件夹)
  final bool highlightCurrent;

  const FolderBreadcrumbs({
    super.key,
    required this.folders,
    required this.onFolderTap,
    this.separatorIcon = Icons.chevron_right,
    this.separatorSize = 16,
    this.textStyle,
    this.highlightCurrent = true,
  });

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final defaultTextStyle = textStyle ?? theme.textTheme.bodyMedium;

    return Wrap(
      spacing: 4,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < folders.length; i++) ...[
          _buildBreadcrumbItem(
            context,
            folders[i],
            isLast: i == folders.length - 1,
            textStyle: defaultTextStyle,
          ),
          if (i < folders.length - 1)
            Icon(
              separatorIcon,
              size: separatorSize,
              color: theme.iconTheme.color?.withOpacity(0.5),
            ),
        ],
      ],
    );
  }

  Widget _buildBreadcrumbItem(
    BuildContext context,
    FolderBreadcrumbItem item,
    {required bool isLast,
    TextStyle? textStyle,}
  ) {
    final theme = Theme.of(context);
    final isClickable = !isLast || !highlightCurrent;

    final textWidget = Text(
      item.name,
      style: textStyle?.copyWith(
        color: isLast && highlightCurrent
            ? theme.primaryColor
            : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
        fontWeight: isLast && highlightCurrent ? FontWeight.w600 : null,
      ),
    );

    if (!isClickable) {
      return textWidget;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onFolderTap(item.id),
        child: textWidget,
      ),
    );
  }
}

/// 面包屑项数据模型
class FolderBreadcrumbItem {
  final String id;
  final String name;

  const FolderBreadcrumbItem({
    required this.id,
    required this.name,
  });
}
