import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/widgets/form_fields/index.dart';
import 'package:Memento/plugins/day/models/memorial_day.dart';
import 'package:Memento/core/route/route_history_manager.dart';

/// 笔记项（包装类，用于 ListAddField）
class _NoteItem {
  final String content;

  _NoteItem({required this.content});
}

class EditMemorialDayPage extends StatefulWidget {
  final MemorialDay? memorialDay;

  const EditMemorialDayPage({super.key, this.memorialDay});

  @override
  State<EditMemorialDayPage> createState() => _EditMemorialDayPageState();
}

class _EditMemorialDayPageState extends State<EditMemorialDayPage> {
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late List<_NoteItem> _noteItems;
  late Color _selectedColor;
  String? _backgroundImageUrl;
  IconData? _selectedIcon;
  Color? _selectedIconColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memorialDay?.title);
    _noteController = TextEditingController();
    _selectedDate = widget.memorialDay?.targetDate ?? DateTime.now();
    _noteItems =
        (widget.memorialDay?.notes ?? [])
            .map((note) => _NoteItem(content: note))
            .toList();
    _selectedColor = widget.memorialDay?.backgroundColor ?? Colors.blue[300]!;
    _backgroundImageUrl = widget.memorialDay?.backgroundImageUrl;
    _selectedIcon = widget.memorialDay?.icon;
    _selectedIconColor = widget.memorialDay?.iconColor;
    _updateRouteContext();
  }

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前状态
  void _updateRouteContext() {
    if (widget.memorialDay == null) {
      RouteHistoryManager.updateCurrentContext(
        pageId: "/day_new",
        title: '新建纪念日',
        params: {},
      );
    } else {
      final memorial = widget.memorialDay!;
      final dateStr = _formatDate(memorial.targetDate);
      RouteHistoryManager.updateCurrentContext(
        pageId: "/day_detail",
        title: '纪念日详情 - ${memorial.title}',
        params: {'id': memorial.id, 'title': memorial.title, 'date': dateStr},
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _addNote() {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;

    setState(() {
      _noteItems.add(_NoteItem(content: note));
      _noteController.clear();
    });
  }

  void _removeNote(int index) {
    setState(() {
      _noteItems.removeAt(index);
    });
  }

  /// 获取笔记字符串列表（保存时使用）
  List<String> _getNotes() {
    return _noteItems.map((item) => item.content).toList();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入标题')));
      return;
    }
    final filteredNotes =
        _getNotes().where((note) => note.trim().isNotEmpty).toList();

    final memorialDay = MemorialDay(
      id: widget.memorialDay?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      targetDate: _selectedDate,
      notes: filteredNotes,
      backgroundColor: _selectedColor,
      backgroundImageUrl: _backgroundImageUrl,
      creationDate: widget.memorialDay?.creationDate ?? DateTime.now(),
      icon: _selectedIcon,
      iconColor: _selectedIconColor,
    );

    Navigator.of(
      context,
    ).pop(DialogResult(action: DialogAction.save, memorialDay: memorialDay));
  }

  void _confirmDelete() {
    Navigator.of(context).pop(const DialogResult(action: DialogAction.delete));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.memorialDay == null
              ? 'day_addMemorialDay'.tr
              : 'day_editMemorialDay'.tr,
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'day_save'.tr,
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconAvatarRowField(
              name: 'memorial_icon',
              initialIcon: _selectedIcon,
              initialIconColor: _selectedIconColor,
              initialAvatarUrl: _backgroundImageUrl,
              onChanged: (value) {
                setState(() {
                  _selectedIcon = value['icon'] as IconData?;
                  _selectedIconColor = value['iconColor'] as Color?;
                  _backgroundImageUrl = value['avatarUrl'] as String?;
                });
              },
            ),
            const SizedBox(height: 24),

            TextInputField(
              controller: _titleController,
              labelText: 'day_title'.tr,
              hintText: 'day_enterTitle'.tr,
              autofocus: widget.memorialDay == null,
            ),
            const SizedBox(height: 24),

            // 目标日期
            DatePickerField(
              date: _selectedDate,
              onTap: _selectDate,
              formattedDate: _formatDate(_selectedDate),
              placeholder: 'day_selectDate'.tr,
              labelText: 'day_targetDate'.tr,
            ),
            const SizedBox(height: 24),

            // 笔记区域
            Text('day_notes'.tr, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ListAddField<String>(
              items: _noteItems.map((item) => item.content).toList(),
              controller: _noteController,
              onAdd: _addNote,
              onToggle: (_) {}, // 笔记不需要勾选功能
              onRemove: _removeNote,
              getTitle: (item) => item,
              getIsCompleted: (_) => false,
              addButtonText: 'day_addNote'.tr,
            ),
            const SizedBox(height: 32),

            // 删除按钮（仅编辑模式显示）
            if (widget.memorialDay != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text('day_deleteMemorialDay'.tr),
                            content: Text('day_deleteConfirmation'.tr),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: Text('day_cancel'.tr),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: Text(
                                  'day_delete'.tr,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );

                    if (confirmed == true) {
                      _confirmDelete();
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: Text(
                    'day_delete'.tr,
                    style: const TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// 对话框操作结果
enum DialogAction { save, delete, cancel }

/// 对话框返回结果
class DialogResult {
  final DialogAction action;
  final MemorialDay? memorialDay;

  const DialogResult({required this.action, this.memorialDay});
}
