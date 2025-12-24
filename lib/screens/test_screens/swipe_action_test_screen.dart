import 'package:flutter/material.dart';
import 'package:Memento/widgets/swipe_action/index.dart';

/// SwipeAction 测试示例页面
///
/// 展示各种滑动操作的使用场景
class SwipeActionTestScreen extends StatefulWidget {
  const SwipeActionTestScreen({super.key});

  @override
  State<SwipeActionTestScreen> createState() => _SwipeActionTestScreenState();
}

class _SwipeActionTestScreenState extends State<SwipeActionTestScreen> {
  // 测试数据
  final List<TaskItem> _tasks = [
    TaskItem(id: '1', title: '完成项目文档', isCompleted: false),
    TaskItem(id: '2', title: '准备会议材料', isCompleted: true),
  ];

  final List<MessageItem> _messages = [
    MessageItem(id: '1', sender: '张三', content: '今天下午开会', isRead: false),
    MessageItem(id: '2', sender: '李四', content: '文档已发送', isRead: true),
  ];

  final List<NoteItem> _notes = [
    NoteItem(id: '1', title: '学习笔记', isPinned: false),
    NoteItem(id: '2', title: '工作计划', isPinned: true),
  ];

  final List<EmailItem> _emails = [
    EmailItem(id: '1', subject: '季度报告', sender: '财务部', isImportant: false),
    EmailItem(id: '2', subject: '紧急会议通知', sender: '总经理', isImportant: true),
  ];

  // 编辑模式状态
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SwipeAction 示例'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('0. 非列表项测试 - 独立组件'),
          _buildStandaloneExample(),
          const Divider(height: 32, thickness: 8),
          _buildSectionHeader('1. 基础用法 - 单个操作'),
          _buildBasicExample(),
          const Divider(height: 32, thickness: 8),
          _buildSectionHeader('2. 多个操作 - 任务列表'),
          _buildTaskList(),
          const Divider(height: 32, thickness: 8),
          _buildSectionHeader('3. 双向滑动 - 消息列表'),
          _buildMessageList(),
          const Divider(height: 32, thickness: 8),
          _buildSectionHeader('4. 自定义样式 - 笔记列表'),
          _buildNoteList(),
          const Divider(height: 32, thickness: 8),
          _buildSectionHeader('5. 预设操作组合'),
          _buildPresetExample(),
          const Divider(height: 32, thickness: 8),
          _buildSectionHeader('6. 全滑动执行操作（类似微信）'),
          _buildFullSwipeExample(),
          const Divider(height: 32, thickness: 8),
          _buildSectionHeader('7. 圆形按钮样式'),
          _buildCircleButtonExample(),
          const Divider(height: 32, thickness: 8),
          _buildSectionHeader('8. 编辑模式切换'),
          _buildEditModeExample(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  /// 0. 非列表项测试 - 独立组件
  Widget _buildStandaloneExample() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: SwipeActionWrapper(
          trailingActions: [
            SwipeActionOption(
              label: '删除',
              icon: Icons.delete,
              backgroundColor: Colors.red,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('删除操作触发')),
                );
              },
            ),
          ],
          child: Container(
            width: 300,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              "滑动我试试",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  /// 1. 基础用法示例
  Widget _buildBasicExample() {
    return SwipeActionWrapper(
      trailingActions: [
        SwipeActionPresets.delete(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('删除操作')),
            );
          },
        ),
      ],
      child: ListTile(
        leading: const Icon(Icons.inbox),
        title: const Text('基础示例'),
        subtitle: const Text('左滑查看删除操作'),
        trailing: const Icon(Icons.arrow_back_ios, size: 16),
      ),
    );
  }

  /// 2. 任务列表示例
  Widget _buildTaskList() {
    return Column(
      children: _tasks.map((task) {
        return SwipeActionWrapper(
          key: ValueKey(task.id),
          trailingActions: [
            SwipeActionOption(
              label: task.isCompleted ? '未完成' : '完成',
              icon: task.isCompleted ? Icons.radio_button_unchecked : Icons.check_circle,
              backgroundColor: task.isCompleted ? Colors.grey : Colors.green,
              onTap: () {
                setState(() {
                  task.isCompleted = !task.isCompleted;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(task.isCompleted ? '已标记为完成' : '已标记为未完成'),
                  ),
                );
              },
            ),
            SwipeActionPresets.delete(
              onTap: () {
                setState(() {
                  _tasks.removeWhere((t) => t.id == task.id);
                });
              },
            ),
          ],
          child: ListTile(
            leading: Icon(
              task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: task.isCompleted ? Colors.green : Colors.grey,
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? Colors.grey : null,
              ),
            ),
            subtitle: Text(task.isCompleted ? '已完成' : '待完成'),
          ),
        );
      }).toList(),
    );
  }

  /// 3. 消息列表示例（双向滑动）
  Widget _buildMessageList() {
    return Column(
      children: _messages.map((message) {
        return SwipeActionWrapper(
          key: ValueKey(message.id),
          // 左滑操作
          trailingActions: [
            SwipeActionPresets.delete(
              onTap: () {
                setState(() {
                  _messages.removeWhere((m) => m.id == message.id);
                });
              },
            ),
          ],
          // 右滑操作
          leadingActions: [
            SwipeActionOption(
              label: message.isRead ? '未读' : '已读',
              icon: message.isRead ? Icons.mark_email_unread : Icons.mark_email_read,
              backgroundColor: message.isRead ? Colors.blue : Colors.green,
              onTap: () {
                setState(() {
                  message.isRead = !message.isRead;
                });
              },
            ),
          ],
          child: ListTile(
            leading: CircleAvatar(
              child: Text(message.sender[0]),
            ),
            title: Text(
              message.sender,
              style: TextStyle(
                fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Text(message.content),
            trailing: Icon(
              message.isRead ? Icons.drafts : Icons.mark_email_unread,
              color: message.isRead ? Colors.grey : Colors.blue,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 4. 笔记列表示例（自定义样式）
  Widget _buildNoteList() {
    return Column(
      children: _notes.map((note) {
        return SwipeActionWrapper(
          key: ValueKey(note.id),
          trailingActions: [
            SwipeActionOption(
              label: note.isPinned ? '取消置顶' : '置顶',
              icon: Icons.push_pin,
              backgroundColor: note.isPinned ? Colors.grey : Colors.purple,
              onTap: () {
                setState(() {
                  note.isPinned = !note.isPinned;
                  // 重新排序，置顶的在前面
                  _notes.sort((a, b) {
                    if (a.isPinned == b.isPinned) return 0;
                    return a.isPinned ? -1 : 1;
                  });
                });
              },
            ),
            SwipeActionPresets.share(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('分享笔记: ${note.title}')),
                );
              },
            ),
            SwipeActionPresets.delete(
              onTap: () {
                setState(() {
                  _notes.removeWhere((n) => n.id == note.id);
                });
              },
            ),
          ],
          child: ListTile(
            leading: Icon(
              note.isPinned ? Icons.push_pin : Icons.note,
              color: note.isPinned ? Colors.purple : Colors.grey,
            ),
            title: Text(note.title),
            subtitle: Text(note.isPinned ? '已置顶' : '普通笔记'),
            trailing: const Icon(Icons.arrow_back_ios, size: 16),
          ),
        );
      }).toList(),
    );
  }

  /// 5. 预设操作组合示例
  Widget _buildPresetExample() {
    return Column(
      children: [
        SwipeActionWrapper(
          trailingActions: [
            SwipeActionPresets.edit(
              onTap: () => _showMessage('编辑'),
            ),
            SwipeActionPresets.archive(
              onTap: () => _showMessage('归档'),
            ),
          ],
          child: const ListTile(
            leading: Icon(Icons.folder),
            title: Text('编辑 + 归档'),
            subtitle: Text('左滑查看操作'),
          ),
        ),
        SwipeActionWrapper(
          leadingActions: [
            SwipeActionPresets.pin(
              onTap: () => _showMessage('置顶'),
            ),
          ],
          trailingActions: [
            SwipeActionPresets.more(
              onTap: () => _showMessage('更多'),
            ),
          ],
          child: const ListTile(
            leading: Icon(Icons.article),
            title: Text('置顶 + 更多'),
            subtitle: Text('支持双向滑动'),
          ),
        ),
        SwipeActionWrapper(
          trailingActions: [
            SwipeActionPresets.markAsRead(
              onTap: () => _showMessage('标记为已读'),
            ),
            SwipeActionPresets.delete(
              onTap: () => _showMessage('删除'),
              showConfirm: false,
            ),
          ],
          child: const ListTile(
            leading: Icon(Icons.email),
            title: Text('已读 + 删除（无确认）'),
            subtitle: Text('删除操作不显示确认对话框'),
          ),
        ),
      ],
    );
  }

  /// 6. 全滑动执行操作示例（类似微信）
  Widget _buildFullSwipeExample() {
    return Column(
      children: _emails.map((email) {
        return SwipeActionWrapper(
          key: ValueKey(email.id),
          performFirstActionWithFullSwipe: true, // 启用全滑动执行
          trailingActions: [
            SwipeActionPresets.delete(
              onTap: () {
                setState(() {
                  _emails.removeWhere((e) => e.id == email.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('邮件已删除')),
                );
              },
            ),
          ],
          child: ListTile(
            leading: Icon(
              email.isImportant ? Icons.star : Icons.mail,
              color: email.isImportant ? Colors.orange : Colors.grey,
            ),
            title: Text(
              email.subject,
              style: TextStyle(
                fontWeight: email.isImportant ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text('来自: ${email.sender}'),
            trailing: const Text(
              '← 完全滑动快速删除',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 7. 圆形按钮样式示例
  Widget _buildCircleButtonExample() {
    return Column(
      children: [
        SwipeActionWrapper(
          trailingActions: [
            SwipeActionOption(
              label: '删除',
              icon: Icons.delete,
              backgroundColor: Colors.red,
              onTap: () => _showMessage('删除'),
              isDestructive: true,
              useCircleButton: true,
              circleButtonSize: 50,
            ),
            SwipeActionOption(
              label: '置顶',
              icon: Icons.vertical_align_top,
              backgroundColor: Colors.blue,
              onTap: () => _showMessage('置顶'),
              useCircleButton: true,
              circleButtonSize: 50,
            ),
          ],
          child: const ListTile(
            leading: Icon(Icons.photo_album),
            title: Text('圆形按钮示例 1'),
            subtitle: Text('50px 圆形按钮，删除带确认效果'),
            trailing: Icon(Icons.arrow_back_ios, size: 16),
          ),
        ),
        SwipeActionWrapper(
          trailingActions: [
            SwipeActionOption(
              label: '喜欢',
              icon: Icons.favorite,
              backgroundColor: Colors.pink,
              onTap: () => _showMessage('喜欢'),
              useCircleButton: true,
              circleButtonSize: 45,
            ),
            SwipeActionOption(
              label: '分享',
              icon: Icons.share,
              backgroundColor: Colors.green,
              onTap: () => _showMessage('分享'),
              useCircleButton: true,
              circleButtonSize: 45,
            ),
            SwipeActionOption(
              label: '更多',
              icon: Icons.more_horiz,
              backgroundColor: Colors.grey,
              onTap: () => _showMessage('更多'),
              useCircleButton: true,
              circleButtonSize: 45,
            ),
          ],
          child: const ListTile(
            leading: Icon(Icons.image),
            title: Text('圆形按钮示例 2'),
            subtitle: Text('45px 圆形按钮，三个操作'),
            trailing: Icon(Icons.arrow_back_ios, size: 16),
          ),
        ),
        SwipeActionWrapper(
          performFirstActionWithFullSwipe: true,
          trailingActions: [
            SwipeActionOption(
              label: '删除',
              icon: Icons.delete,
              backgroundColor: Colors.red,
              onTap: () => _showMessage('删除'),
              useCircleButton: true,
              circleButtonSize: 55,
            ),
          ],
          child: const ListTile(
            leading: Icon(Icons.music_note),
            title: Text('圆形按钮 + 全滑动'),
            subtitle: Text('55px 大圆形按钮，完全滑动快速删除'),
            trailing: Text(
              '← 完全滑动',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  /// 8. 编辑模式示例
  Widget _buildEditModeExample() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '编辑模式下禁用滑动操作',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Switch(
                value: _isEditMode,
                onChanged: (value) {
                  setState(() {
                    _isEditMode = value;
                  });
                },
              ),
            ],
          ),
        ),
        ...List.generate(2, (index) {
          return SwipeActionWrapper(
            isEditMode: _isEditMode, // 根据状态禁用/启用滑动
            trailingActions: [
              SwipeActionPresets.edit(
                onTap: () => _showMessage('编辑项目 ${index + 1}'),
              ),
              SwipeActionPresets.delete(
                onTap: () => _showMessage('删除项目 ${index + 1}'),
              ),
            ],
            child: ListTile(
              leading: _isEditMode
                  ? Checkbox(
                      value: false,
                      onChanged: (value) {},
                    )
                  : const Icon(Icons.article),
              title: Text('项目 ${index + 1}'),
              subtitle: Text(
                _isEditMode ? '编辑模式：滑动已禁用' : '正常模式：可以左滑操作',
              ),
              trailing: _isEditMode
                  ? const Icon(Icons.drag_handle)
                  : const Icon(Icons.arrow_back_ios, size: 16),
            ),
          );
        }),
      ],
    );
  }

  /// 显示提示消息
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// 任务项数据模型
class TaskItem {
  final String id;
  final String title;
  bool isCompleted;

  TaskItem({
    required this.id,
    required this.title,
    required this.isCompleted,
  });
}

/// 消息项数据模型
class MessageItem {
  final String id;
  final String sender;
  final String content;
  bool isRead;

  MessageItem({
    required this.id,
    required this.sender,
    required this.content,
    required this.isRead,
  });
}

/// 笔记项数据模型
class NoteItem {
  final String id;
  final String title;
  bool isPinned;

  NoteItem({
    required this.id,
    required this.title,
    required this.isPinned,
  });
}

/// 邮件项数据模型
class EmailItem {
  final String id;
  final String subject;
  final String sender;
  bool isImportant;

  EmailItem({
    required this.id,
    required this.subject,
    required this.sender,
    required this.isImportant,
  });
}
