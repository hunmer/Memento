import 'dart:convert';
import 'dart:typed_data';

import 'package:Memento/widgets/icon_picker_dialog.dart';
import 'package:Memento/widgets/image_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:floating_ball_plugin/floating_ball_plugin.dart';
import 'package:Memento/constants/app_icons.dart';
import 'package:Memento/core/action/action_manager.dart';
import 'package:Memento/core/action/widgets/action_selector_dialog.dart';
import 'package:Memento/core/action/models/action_instance.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/l10n/core_localizations.dart';

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

  // 选中的动作结果
  ActionSelectorResult? _selectedActionResult;

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

      // 尝试从已有数据创建 ActionSelectorResult
      final data = widget.initialButton!.data!;
      final actionId = data['action'] as String?;
      if (actionId != null) {
        _selectedActionResult = ActionSelectorResult(
          singleAction: ActionInstance.create(
            actionId: actionId,
            data: data['args'] as Map<String, dynamic>? ?? {},
          ),
        );
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

  /// 打开动作选择器
  Future<void> _openActionSelector() async {
    // 确保 ActionManager 已初始化
    final actionManager = ActionManager();
    if (!actionManager.isInitialized) {
      await actionManager.initialize();
    }

    if (!mounted) return;

    final result = await showDialog<ActionSelectorResult>(
      context: context,
      builder: (context) => ActionSelectorDialog(
        initialValue: _selectedActionResult,
        showGroupEditor: false,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedActionResult = result;
        // 更新执行数据
        _updateDataFromActionResult(result);
      });
    }
  }

  /// 根据动作结果更新执行数据
  void _updateDataFromActionResult(ActionSelectorResult result) {
    Map<String, dynamic> data = {};

    if (result.singleAction != null) {
      data = {
        'action': result.singleAction!.actionId,
        if (result.singleAction!.data.isNotEmpty)
          'args': result.singleAction!.data,
      };
    } else if (result.actionGroup != null) {
      data = {
        'action': 'executeGroup',
        'args': {'groupId': result.actionGroup!.id},
      };
    }

    _dataController.text = jsonEncode(data);
  }

  /// 获取当前选中动作的显示名称
  String _getSelectedActionLabel() {
    if (_selectedActionResult == null || _selectedActionResult!.isEmpty) {
      return '点击选择动作';
    }

    if (_selectedActionResult!.singleAction != null) {
      final actionId = _selectedActionResult!.singleAction!.actionId;
      // 尝试获取动作定义的标题
      if (_selectedActionResult!.selectedDefinition != null) {
        return _selectedActionResult!.selectedDefinition!.title;
      }
      return actionId;
    }

    if (_selectedActionResult!.actionGroup != null) {
      return '动作组: ${_selectedActionResult!.actionGroup!.title}';
    }

    return '点击选择动作';
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

  /// 选择图标
  Future<void> _pickIcon() async {
    // 将字符串转换为 IconData
    IconData currentIcon = Icons.help_outline;
    for (var entry in AppIcons.predefinedIcons.entries) {
      if (entry.key == _selectedIcon) {
        currentIcon = entry.value;
        break;
      }
    }

    final result = await showIconPickerDialog(
      context,
      currentIcon,
      enableIconToImage: true,
    );

    if (result != null) {
      setState(() {
        if (result is IconData) {
          // 仅选择图标
          _selectedIcon = _getIconString(result);
        } else if (result is Map<String, dynamic>) {
          // 图标转图片
          final bytes = result['bytes'] as Uint8List;
          final icon = result['icon'] as IconData;
          _imageBase64 = base64Encode(bytes);
          _selectedIcon = _getIconString(icon);
        }
      });
    }
  }

  /// 获取图标字符串
  String _getIconString(IconData icon) {
    for (var entry in AppIcons.predefinedIcons.entries) {
      if (entry.value == icon) {
        return entry.key;
      }
    }
    return 'ic_menu_info_details';
  }

  /// 清除图标
  void _clearIcon() {
    setState(() {
      _selectedIcon = 'ic_menu_info_details';
    });
  }

  /// 保存按钮
  void _save() {
    if (_titleController.text.trim().isEmpty) {
      toastService.showToast('请输入按钮标题');
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
      toastService.showToast('执行数据格式错误: $e');
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

  /// 构建图标预览
  Widget _buildIconPreview() {
    // 如果有图片，优先显示图片
    if (_imageBase64 != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          base64Decode(_imageBase64!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.image_not_supported);
          },
        ),
      );
    }

    // 否则显示图标
    IconData iconData = Icons.help_outline;
    for (var entry in AppIcons.predefinedIcons.entries) {
      if (entry.key == _selectedIcon) {
        iconData = entry.value;
        break;
      }
    }

    return Icon(iconData);
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

              // 按钮图标设置
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '按钮图标',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // 图标预览
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: _buildIconPreview(),
                            ),
                            const SizedBox(width: 8),
                            // 显示选择状态
                            Expanded(
                              child: Text(
                                _imageBase64 != null
                                    ? '已设置图片（优先级最高）'
                                    : '已设置图标：$_selectedIcon',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _imageBase64 != null
                                      ? Colors.green
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 清除按钮
                  if (_imageBase64 != null || _selectedIcon != 'ic_menu_info_details')
                    IconButton(
                      icon: const Icon(Icons.clear_all, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(FloatingBallLocalizations.of(context)!.clearIconImage),
                            content: Text(FloatingBallLocalizations.of(context)!.confirmClearIconImage),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(FloatingBallLocalizations.of(context)!.cancel),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _clearImage();
                                  _clearIcon();
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text(FloatingBallLocalizations.of(context)!.clear),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: '清空图标和图片',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 操作按钮组
              Row(
                children: [
                  // 选择图标按钮
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickIcon,
                      icon: const Icon(Icons.tag),
                      label: Text(FloatingBallLocalizations.of(context)!.selectIcon),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 选择图片按钮
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text(_imageBase64 == null ? '选择图片' : '更换图片'),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              // 动作选择器
              InkWell(
                onTap: _openActionSelector,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '选择动作',
                    border: const OutlineInputBorder(),
                    helperText: '点击选择要执行的动作',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedActionResult != null &&
                            !_selectedActionResult!.isEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _selectedActionResult = null;
                                _dataController.text = '{}';
                              });
                            },
                            tooltip: '清除动作',
                          ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                  child: Text(
                    _getSelectedActionLabel(),
                    style: TextStyle(
                      color: _selectedActionResult == null ||
                              _selectedActionResult!.isEmpty
                          ? Colors.grey[600]
                          : null,
                    ),
                  ),
                ),
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
                    child: Text(FloatingBallLocalizations.of(context)!.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(FloatingBallLocalizations.of(context)!.save),
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
