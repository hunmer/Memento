import 'package:flutter/material.dart';
import '../models/checkin_item.dart';
import '../../../widgets/circle_icon_picker.dart';
import '../checkin_plugin.dart';

class CheckinFormDialog extends StatefulWidget {
  final CheckinItem? initialItem;

  const CheckinFormDialog({super.key, this.initialItem});

  @override
  State<CheckinFormDialog> createState() => _CheckinFormDialogState();
}

class _CheckinFormDialogState extends State<CheckinFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late IconData _icon;
  late String? _group;
  late Color _color;
  final TextEditingController _groupController = TextEditingController();
  Set<String> _existingGroups = <String>{};

  @override
  void initState() {
    super.initState();
    // 使用初始项目的值或默认值
    _name = widget.initialItem?.name ?? '';
    _icon = widget.initialItem?.icon ?? Icons.check_circle;
    _group = widget.initialItem?.group;
    _color = widget.initialItem?.color ?? Colors.blue;

    // 设置分组控制器的文本
    _groupController.text = _group ?? '';

    // 加载现有分组
    _loadExistingGroups();
  }

  // 加载现有分组
  void _loadExistingGroups() {
    final items = CheckinPlugin.shared.checkinItems;
    if (items.isNotEmpty) {
      _existingGroups = items.map((item) => item.group).toSet();
      // 如果集合为空，添加默认分组
      if (_existingGroups.isEmpty) {
        _existingGroups.add('默认分组');
      }
    } else {
      _existingGroups = {'默认分组'};
    }
  }

  // 显示分组选择对话框
  Future<void> _showGroupSelectionDialog(BuildContext context) async {
    final selectedGroup = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择分组'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _existingGroups.length,
              itemBuilder: (context, index) {
                final group = _existingGroups.elementAt(index);
                return ListTile(
                  title: Text(group),
                  onTap: () => Navigator.of(context).pop(group),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );

    if (selectedGroup != null) {
      setState(() {
        _group = selectedGroup;
        _groupController.text = selectedGroup;
      });
    }
  }

  @override
  void dispose() {
    _groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialItem == null ? '添加打卡项目' : '编辑打卡项目'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 圆形图标和颜色选择控件
              CircleIconPicker(
                onIconSelected: (icon) {
                  setState(() => _icon = icon);
                },
                onColorSelected: (color) {
                  setState(() => _color = color);
                },
                currentIcon: _icon,
                backgroundColor: _color,
              ),
              const SizedBox(height: 24),
              // 项目名称输入框
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '项目名称',
                  hintText: '请输入项目名称',
                ),
                initialValue: _name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入项目名称';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),
              // 分组输入框
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '分组 (可选)',
                  hintText: '请输入分组名称',
                ),
                initialValue: _group,
                onSaved:
                    (value) =>
                        _group = value?.trim().isEmpty == true ? null : value,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final item = CheckinItem(
                id: widget.initialItem?.id, // 保留原有ID
                name: _name,
                icon: _icon,
                color: _color,
                group: _group,
                checkInRecords:
                    widget.initialItem?.checkInRecords ?? {}, // 保留打卡记录
              );
              Navigator.of(context).pop(item);
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
