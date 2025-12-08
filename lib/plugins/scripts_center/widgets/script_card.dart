import 'package:flutter/material.dart';
import 'package:Memento/plugins/scripts_center/models/script_info.dart';

/// 脚本卡片组件
///
/// 在列表中展示单个脚本的信息
class ScriptCard extends StatelessWidget {
  final ScriptInfo script;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onRun;

  const ScriptCard({
    super.key,
    required this.script,
    this.onTap,
    this.onToggle,
    this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行：图标 + 名称 + 开关
              Row(
                children: [
                  // 状态指示器
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: script.enabled ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 图标
                  Icon(
                    _getIconData(script.icon),
                    size: 28,
                    color: script.enabled
                        ? Colors.deepPurple
                        : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),

                  // 脚本名称
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          script.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: script.enabled ? null : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v${script.version} by ${script.author}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 启用开关
                  Switch(
                    value: script.enabled,
                    onChanged: onToggle,
                    activeThumbColor: Colors.deepPurple,
                  ),
                ],
              ),

              // 描述
              if (script.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  script.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: script.enabled ? null : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // 触发器标签
              if (script.triggers.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: script.triggers.take(3).map((trigger) {
                    return Chip(
                      label: Text(
                        trigger.event,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],

              // 类型、更新时间和运行按钮
              const SizedBox(height: 8),
              Row(
                children: [
                  // 脚本类型
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: script.isModule
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      script.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: script.isModule ? Colors.blue : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 更新时间
                  if (script.updatedAt != null)
                    Expanded(
                      child: Text(
                        _formatDateTime(script.updatedAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ),

                  // 运行按钮（仅当脚本启用时显示）
                  if (script.enabled && onRun != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onRun,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('运行'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 根据图标名称获取IconData
  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'code':
        return Icons.code;
      case 'backup':
        return Icons.backup;
      case 'analytics':
        return Icons.analytics;
      case 'settings':
        return Icons.settings;
      case 'sync':
        return Icons.sync;
      case 'schedule':
        return Icons.schedule;
      case 'notification':
        return Icons.notifications;
      case 'data':
        return Icons.storage;
      case 'auto':
        return Icons.autorenew;
      default:
        return Icons.code;
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}
