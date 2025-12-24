---
skill_name: add-swipe-action
description: 为 Flutter ListView 项目快速添加 SwipeAction 滑动操作功能，支持删除、编辑、置顶等常用操作，可选圆形按钮样式
details: |
  此 skill 将自动为现有的 ListView/ListTile 组件添加滑动操作功能。

  功能特性：
  - 自动包装 ListTile/Card 等组件
  - 支持左滑/右滑操作配置
  - 提供预设操作（删除、编辑、分享、置顶等）
  - 支持圆形按钮样式
  - 支持全滑动快速执行
  - 支持破坏性操作确认
  - 自动添加必要的 import

  使用场景：
  - 为现有列表添加删除功能
  - 为聊天列表添加已读/未读切换
  - 为笔记列表添加置顶/归档操作
  - 为邮件列表添加快速删除
---

# SwipeAction 快速添加 Skill

## 工作流程

1. **分析现有代码**
   - 定位 ListView.builder 或类似列表组件
   - 识别列表项的构建方法
   - 检查是否已导入 SwipeActionWrapper

2. **询问用户需求**
   - 需要什么操作？（删除、编辑、分享等）
   - 是左滑还是右滑？
   - 是否需要圆形按钮样式？
   - 是否需要全滑动快速执行？
   - 破坏性操作是否需要确认？

3. **添加 import**
   ```dart
   import 'package:Memento/widgets/swipe_action/index.dart';
   ```

4. **包装列表项**
   将原有的 ListTile/Card 等组件用 SwipeActionWrapper 包装

5. **添加操作回调**
   根据用户需求添加相应的操作逻辑

## 常用模板

### 模板 1: 基础删除操作
```dart
SwipeActionWrapper(
  key: ValueKey(item.id),
  trailingActions: [
    SwipeActionPresets.delete(
      onTap: () {
        setState(() {
          items.removeWhere((i) => i.id == item.id);
        });
      },
    ),
  ],
  child: ListTile(
    title: Text(item.title),
  ),
)
```

### 模板 2: 圆形按钮样式
```dart
SwipeActionWrapper(
  key: ValueKey(item.id),
  trailingActions: [
    SwipeActionOption(
      label: '删除',
      icon: Icons.delete,
      backgroundColor: Colors.red,
      onTap: () => _deleteItem(item.id),
      isDestructive: true,
      useCircleButton: true,
      circleButtonSize: 50,
    ),
  ],
  child: ListTile(
    title: Text(item.title),
  ),
)
```

### 模板 3: 多个操作
```dart
SwipeActionWrapper(
  key: ValueKey(item.id),
  trailingActions: [
    SwipeActionPresets.edit(
      onTap: () => _editItem(item.id),
    ),
    SwipeActionPresets.delete(
      onTap: () => _deleteItem(item.id),
    ),
  ],
  child: ListTile(
    title: Text(item.title),
  ),
)
```

### 模板 4: 双向滑动（已读/未读）
```dart
SwipeActionWrapper(
  key: ValueKey(message.id),
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
  trailingActions: [
    SwipeActionPresets.delete(
      onTap: () => _deleteMessage(message.id),
    ),
  ],
  child: ListTile(
    title: Text(message.subject),
  ),
)
```

### 模板 5: 全滑动快速删除（类似微信）
```dart
SwipeActionWrapper(
  key: ValueKey(item.id),
  performFirstActionWithFullSwipe: true,
  trailingActions: [
    SwipeActionPresets.delete(
      onTap: () => _deleteItem(item.id),
    ),
  ],
  child: ListTile(
    title: Text(item.title),
  ),
)
```

## 预设操作快速参考

- `SwipeActionPresets.delete()` - 删除（红色）
- `SwipeActionPresets.edit()` - 编辑（蓝色）
- `SwipeActionPresets.share()` - 分享（绿色）
- `SwipeActionPresets.archive()` - 归档（橙色）
- `SwipeActionPresets.pin()` - 置顶（紫色）
- `SwipeActionPresets.markAsRead()` - 已读（灰色）
- `SwipeActionPresets.more()` - 更多（深灰）

## 自定义操作

```dart
SwipeActionOption(
  label: '自定义',
  icon: Icons.custom_icon,
  backgroundColor: Colors.customColor,
  textColor: Colors.white,
  onTap: () {
    // 自定义逻辑
  },
  isDestructive: false,        // 是否需要确认
  useCircleButton: false,      // 是否使用圆形按钮
  circleButtonSize: 50,        // 圆形按钮大小
)
```

## 注意事项

1. **Key 的重要性**
   - 必须为 SwipeActionWrapper 设置 `key: ValueKey(item.id)`
   - 这样在删除项目时动画才能正确工作

2. **setState 调用**
   - 删除、修改数据后需要调用 `setState(() {})`
   - 确保 UI 能够正确更新

3. **删除操作最佳实践**
   - 使用 `removeWhere` 而不是 `removeAt`
   - 这样可以避免索引问题

4. **圆形按钮使用场景**
   - 适合操作较少的场景（1-3个）
   - 视觉上更现代、更清爽
   - 建议按钮大小 45-55px

5. **全滑动功能**
   - 适合单一高频操作
   - 通常与删除操作配合使用
   - 提升操作效率

## 示例：完整的应用场景

### 场景 1: 待办事项列表
```dart
ListView.builder(
  itemCount: tasks.length,
  itemBuilder: (context, index) {
    final task = tasks[index];
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
          },
        ),
        SwipeActionPresets.delete(
          onTap: () {
            setState(() {
              tasks.removeWhere((t) => t.id == task.id);
            });
          },
        ),
      ],
      child: ListTile(
        leading: Icon(
          task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
        ),
        title: Text(task.title),
      ),
    );
  },
)
```

### 场景 2: 笔记列表（圆形按钮）
```dart
ListView.builder(
  itemCount: notes.length,
  itemBuilder: (context, index) {
    final note = notes[index];
    return SwipeActionWrapper(
      key: ValueKey(note.id),
      trailingActions: [
        SwipeActionOption(
          label: '分享',
          icon: Icons.share,
          backgroundColor: Colors.green,
          onTap: () => _shareNote(note),
          useCircleButton: true,
          circleButtonSize: 50,
        ),
        SwipeActionOption(
          label: '删除',
          icon: Icons.delete,
          backgroundColor: Colors.red,
          onTap: () => _deleteNote(note.id),
          isDestructive: true,
          useCircleButton: true,
          circleButtonSize: 50,
        ),
      ],
      child: Card(
        child: ListTile(
          title: Text(note.title),
          subtitle: Text(note.preview),
        ),
      ),
    );
  },
)
```

## 执行步骤

当用户请求为列表添加 SwipeAction 时：

1. 读取目标文件
2. 定位 ListView/列表组件
3. 询问用户具体需求（使用 AskUserQuestion）
4. 检查并添加 import
5. 用 SwipeActionWrapper 包装列表项
6. 根据需求选择合适的模板
7. 添加操作回调逻辑
8. 验证代码正确性
