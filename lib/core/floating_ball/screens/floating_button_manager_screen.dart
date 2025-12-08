import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:floating_ball_plugin/floating_ball_plugin.dart';
import 'package:Memento/core/floating_ball/floating_widget_controller.dart';
import 'package:Memento/core/floating_ball/widgets/floating_button_edit_dialog.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 悬浮按钮管理界面
class FloatingButtonManagerScreen extends StatefulWidget {
  const FloatingButtonManagerScreen({super.key});

  @override
  State<FloatingButtonManagerScreen> createState() =>
      _FloatingButtonManagerScreenState();
}

class _FloatingButtonManagerScreenState
    extends State<FloatingButtonManagerScreen> {
  final FloatingWidgetController _controller = FloatingWidgetController();
  List<FloatingBallButtonData> _buttons = [];

  @override
  void initState() {
    super.initState();
    _loadButtons();
  }

  /// 加载按钮列表
  void _loadButtons() {
    setState(() {
      _buttons = _controller.buttonData.toList();
    });
  }

  /// 添加按钮
  Future<void> _addButton() async {
    final result = await showDialog<FloatingBallButtonData>(
      context: context,
      builder: (context) => const FloatingButtonEditDialog(),
    );

    if (result != null) {
      setState(() {
        _buttons.add(result);
      });
      await _saveButtons();
    }
  }

  /// 编辑按钮
  Future<void> _editButton(int index) async {
    final result = await showDialog<FloatingBallButtonData>(
      context: context,
      builder: (context) => FloatingButtonEditDialog(
        initialButton: _buttons[index],
        index: index,
      ),
    );

    if (result != null) {
      setState(() {
        _buttons[index] = result;
      });
      await _saveButtons();
    }
  }

  /// 删除按钮
  Future<void> _deleteButton(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除按钮"${_buttons[index].title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _buttons.removeAt(index);
      });
      await _saveButtons();
    }
  }

  /// 保存按钮列表
  Future<void> _saveButtons() async {
    await _controller.updateButtonData(_buttons);

    // 如果悬浮球正在运行，更新配置
    if (_controller.isRunning) {
      await _controller.updateConfig();
    }

    if (mounted) {
      toastService.showToast('保存成功');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('悬浮按钮管理'),
      ),
      body: _buttons.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.touch_app,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无按钮',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addButton,
                    icon: const Icon(Icons.add),
                    label: const Text('添加第一个按钮'),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _buttons.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _buttons.removeAt(oldIndex);
                  _buttons.insert(newIndex, item);
                });
                _saveButtons();
              },
              itemBuilder: (context, index) {
                final button = _buttons[index];
                return Card(
                  key: ValueKey(index),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: button.image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.memory(
                              base64Decode(button.image!),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported);
                              },
                            ),
                          )
                        : const Icon(Icons.radio_button_unchecked, size: 48),
                    title: Text(button.title),
                    subtitle: Text(
                      button.data != null
                          ? jsonEncode(button.data)
                          : '无执行数据',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editButton(index),
                          tooltip: '编辑',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          color: Colors.red,
                          onPressed: () => _deleteButton(index),
                          tooltip: '删除',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _buttons.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addButton,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
