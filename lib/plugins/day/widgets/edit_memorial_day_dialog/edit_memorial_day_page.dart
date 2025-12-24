import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/widgets/form_fields/index.dart';
import 'package:Memento/widgets/image_picker_dialog.dart';
import 'package:Memento/plugins/day/models/memorial_day.dart';
import 'package:Memento/core/route/route_history_manager.dart';

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
  late List<String> _notes;
  late Color _selectedColor;
  String? _backgroundImageUrl;
  final List<String> _predefinedBackgroundImages = [
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memorialDay?.title);
    _noteController = TextEditingController();
    _selectedDate = widget.memorialDay?.targetDate ?? DateTime.now();
    _notes = List.from(widget.memorialDay?.notes ?? []);
    _selectedColor = widget.memorialDay?.backgroundColor ?? Colors.blue[300]!;
    _backgroundImageUrl = widget.memorialDay?.backgroundImageUrl;

    // 设置路由上下文
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
        params: {
          'id': memorial.id,
          'title': memorial.title,
          'date': dateStr,
        },
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
      _notes.add(note);
      _noteController.clear();
    });
  }

  void _removeNote(int index) {
    setState(() {
      _notes.removeAt(index);
    });
  }

  void _updateNote(int index, String newContent) {
    setState(() {
      _notes[index] = newContent;
    });
  }

  void _selectColor(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _selectBackgroundImage(String? imageUrl) {
    setState(() {
      _backgroundImageUrl = imageUrl;
    });
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题')),
      );
      return;
    }

    // 移除空笔记
    final filteredNotes = _notes.where((note) => note.trim().isNotEmpty).toList();

    final memorialDay = MemorialDay(
      id: widget.memorialDay?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      targetDate: _selectedDate,
      notes: filteredNotes,
      backgroundColor: _selectedColor,
      backgroundImageUrl: _backgroundImageUrl,
      creationDate: widget.memorialDay?.creationDate ?? DateTime.now(),
    );

    Navigator.of(context).pop(DialogResult(action: DialogAction.save, memorialDay: memorialDay));
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
          if (widget.memorialDay != null)
            IconButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('day_deleteMemorialDay'.tr),
                    content: Text('day_deleteConfirmation'.tr),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('day_cancel'.tr),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
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
              icon: const Icon(Icons.delete_outline),
              tooltip: 'day_delete'.tr,
            ),
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
            // 信息区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'day_information'.tr,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextInputField(
                      controller: _titleController,
                      labelText: 'day_title'.tr,
                      hintText: 'day_enterTitle'.tr,
                      autofocus: widget.memorialDay == null,
                    ),
                    const SizedBox(height: 16),
                    DatePickerField(
                      date: _selectedDate,
                      onTap: _selectDate,
                      formattedDate: _formatDate(_selectedDate),
                      placeholder: 'day_selectDate'.tr,
                      labelText: 'day_targetDate'.tr,
                      inline: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 笔记区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: EditableListField(
                  items: _notes,
                  controller: _noteController,
                  onAdd: _addNote,
                  onRemove: _removeNote,
                  onUpdate: _updateNote,
                  addButtonText: 'day_addNote'.tr,
                  inputLabel: 'day_note'.tr,
                  inputHint: 'day_enterNote'.tr,
                  titleText: 'day_notes'.tr,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 外观区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'day_appearance'.tr,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ColorSelectorField(
                      selectedColor: _selectedColor,
                      onColorChanged: _selectColor,
                      labelText: 'day_backgroundColor'.tr,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'day_backgroundImage'.tr,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // 清除背景图片选项
                          GestureDetector(
                            onTap: () => _selectBackgroundImage(null),
                            child: Container(
                              width: 120,
                              height: 120,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _backgroundImageUrl == null
                                      ? theme.primaryColor
                                      : Colors.grey,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(child: Icon(Icons.clear)),
                            ),
                          ),
                          ..._predefinedBackgroundImages.map(
                            (imageUrl) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => _selectBackgroundImage(imageUrl),
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _backgroundImageUrl == imageUrl
                                          ? theme.primaryColor
                                          : Colors.grey,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 添加本地图片按钮
                          GestureDetector(
                            onTap: () async {
                              final result = await showDialog(
                                context: context,
                                builder: (context) => ImagePickerDialog(
                                  initialUrl: _backgroundImageUrl,
                                  enableCrop: true,
                                  cropAspectRatio: 1.0,
                                  saveDirectory: 'day/backgrounds',
                                ),
                              );

                              if (result != null && result is Map<String, dynamic>) {
                                final url = result['url'] as String;
                                _selectBackgroundImage(url);
                              }
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_photo_alternate, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    'day_localImage'.tr,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
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
