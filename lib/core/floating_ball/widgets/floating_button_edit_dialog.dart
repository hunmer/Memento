import 'dart:convert';
import 'dart:typed_data';

import 'package:Memento/widgets/image_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:floating_ball_plugin/floating_ball_plugin.dart';

/// 悬浮按钮编辑对话框
class FloatingButtonEditDialog extends StatefulWidget {
  final FloatingBallButtonData? initialButton;
  final int? index;

  const FloatingButtonEditDialog({
    super.key,
    this.initialButton,
    this.index,
  });

  @override
  State<FloatingButtonEditDialog> createState() =>
      _FloatingButtonEditDialogState();
}

class _FloatingButtonEditDialogState extends State<FloatingButtonEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _dataController;
  String _selectedIcon = 'ic_menu_info_details';
  String? _imageBase64;
  String? _selectedAction;

  // 常用动作列表
  final List<Map<String, dynamic>> _commonActions = [
    {
      'label': '打开聊天插件',
      'value': 'openPlugin',
      'data': {'action': 'openPlugin', 'args': {'plugin': 'chat'}},
    },
    {
      'label': '打开日记插件',
      'value': 'openPlugin_diary',
      'data': {'action': 'openPlugin', 'args': {'plugin': 'diary'}},
    },
    {
      'label': '打开活动插件',
      'value': 'openPlugin_activity',
      'data': {'action': 'openPlugin', 'args': {'plugin': 'activity'}},
    },
    {
      'label': '打开笔记插件',
      'value': 'openPlugin_notes',
      'data': {'action': 'openPlugin', 'args': {'plugin': 'notes'}},
    },
    {
      'label': '打开任务插件',
      'value': 'openPlugin_todo',
      'data': {'action': 'openPlugin', 'args': {'plugin': 'todo'}},
    },
    {
      'label': '打开签到插件',
      'value': 'openPlugin_checkin',
      'data': {'action': 'openPlugin', 'args': {'plugin': 'checkin'}},
    },
    {
      'label': '打开账单插件',
      'value': 'openPlugin_bill',
      'data': {'action': 'openPlugin', 'args': {'plugin': 'bill'}},
    },
    {
      'label': '打开物品插件',
      'value': 'openPlugin_goods',
      'data': {'action': 'openPlugin', 'args': {'plugin': 'goods'}},
    },
    {
      'label': '打开联系人插件',
      'value': 'openPlugin_contact',
      'data': {'action': 'openPlugin', 'args': {'plugin': 'contact'}},
    },
    {
      'label': '打开习惯插件',
      'value': 'openPlugin_habits',
      'data': {'action': 'openPlugin', 'args': {'plugin': 'habits'}},
    },
    {
      'label': '打开AI对话插件',
      'value': 'openPlugin_agent_chat',
      'data': {'action': 'openPlugin', 'args': {'plugin': 'agent_chat'}},
    },
    {
      'label': '打开设置',
      'value': 'openSettings',
      'data': {'action': 'openSettings'},
    },
    {
      'label': '返回首页',
      'value': 'home',
      'data': {'action': 'home'},
    },
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialButton?.title ?? '',
    );
    _selectedIcon = widget.initialButton?.icon ?? 'ic_menu_info_details';
    _imageBase64 = widget.initialButton?.image;

    // 初始化执行数据
    if (widget.initialButton?.data != null) {
      _dataController = TextEditingController(
        text: jsonEncode(widget.initialButton!.data),
      );

      // 尝试匹配常用动作
      final data = widget.initialButton!.data!;
      for (var action in _commonActions) {
        final actionData = action['data'] as Map<String, dynamic>;
        if (_mapsEqual(data, actionData)) {
          _selectedAction = action['value'] as String;
          break;
        }
      }
    } else {
      _dataController = TextEditingController(text: '{}');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  /// 比较两个 Map 是否相等
  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if (!b.containsKey(key)) return false;
      final aValue = a[key];
      final bValue = b[key];
      if (aValue is Map && bValue is Map) {
        if (!_mapsEqual(
          aValue as Map<String, dynamic>,
          bValue as Map<String, dynamic>,
        )) {
          return false;
        }
      } else if (aValue != bValue) {
        return false;
      }
    }
    return true;
  }

  /// 选择图片
  Future<void> _pickImage() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ImagePickerDialog(
        saveDirectory: 'floating_buttons',
        enableCrop: true,
        cropAspectRatio: 1.0,
        enableCompression: true,
        compressionQuality: 80,
      ),
    );

    if (result != null && result['bytes'] != null) {
      final bytes = result['bytes'] as Uint8List;
      setState(() {
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  /// 清除图片
  void _clearImage() {
    setState(() {
      _imageBase64 = null;
    });
  }

  /// 常用动作变更
  void _onActionChanged(String? action) {
    if (action == null) return;

    setState(() {
      _selectedAction = action;
    });

    // 查找对应的动作数据
    final actionData = _commonActions.firstWhere(
      (item) => item['value'] == action,
      orElse: () => {'data': {}},
    );

    // 更新执行数据
    final data = actionData['data'] as Map<String, dynamic>;
    _dataController.text = jsonEncode(data);
  }

  /// 保存按钮
  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入按钮标题')),
      );
      return;
    }

    // 解析执行数据
    Map<String, dynamic>? data;
    try {
      final dataText = _dataController.text.trim();
      if (dataText.isNotEmpty && dataText != '{}') {
        data = jsonDecode(dataText) as Map<String, dynamic>;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('执行数据格式错误: $e')),
      );
      return;
    }

    final button = FloatingBallButtonData(
      title: _titleController.text.trim(),
      icon: _selectedIcon,
      data: data,
      image: _imageBase64,
    );

    Navigator.of(context).pop(button);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              Text(
                widget.index == null ? '添加按钮' : '编辑按钮',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 按钮标题
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '按钮标题',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 按钮图片
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _imageBase64 == null ? '未选择图片' : '已选择图片',
                      style: TextStyle(
                        color: _imageBase64 == null ? Colors.grey : Colors.green,
                      ),
                    ),
                  ),
                  if (_imageBase64 != null) ...[
                    // 预览图片
                    Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.memory(
                          base64Decode(_imageBase64!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: _clearImage,
                      tooltip: '清除图片',
                    ),
                  ],
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(_imageBase64 == null ? '选择图片' : '更换图片'),
                  ),
                ],
              ),
              const Divider(height: 32),

              // 常用动作
              DropdownButtonFormField<String>(
                value: _selectedAction,
                decoration: const InputDecoration(
                  labelText: '常用动作',
                  border: OutlineInputBorder(),
                  helperText: '选择后会自动填充执行数据',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('自定义'),
                  ),
                  ..._commonActions.map(
                    (action) => DropdownMenuItem<String>(
                      value: action['value'] as String,
                      child: Text(action['label'] as String),
                    ),
                  ),
                ],
                onChanged: _onActionChanged,
              ),
              const SizedBox(height: 16),

              // 执行数据
              TextField(
                controller: _dataController,
                decoration: const InputDecoration(
                  labelText: '执行数据',
                  border: OutlineInputBorder(),
                  helperText: 'JSON 格式，例如: {"action": "openPlugin", "args": {"plugin": "chat"}}',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
