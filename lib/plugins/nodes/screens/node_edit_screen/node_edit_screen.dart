import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/nodes_controller.dart';
import '../../models/node.dart';
import '../../l10n/nodes_localizations.dart';
import 'components/breadcrumbs.dart';
import 'components/color_picker_section.dart';
import 'components/tags_section.dart';
import 'components/status_dropdown.dart';
import 'components/date_section.dart';
import 'components/custom_fields_section.dart';

class NodeEditScreen extends StatefulWidget {
  final String notebookId;
  final Node node;
  final bool isNew;

  const NodeEditScreen({
    super.key,
    required this.notebookId,
    required this.node,
    this.isNew = false,
  });

  @override
  State<NodeEditScreen> createState() => NodeEditScreenState();
}

class NodeEditScreenState extends State<NodeEditScreen> {
  late TextEditingController _titleController;
  late List<String> _tags;
  late NodeStatus _status;
  late Color _color;
  DateTime? _startDate;
  DateTime? _endDate;
  late List<CustomField> _customFields;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.node.title);
    _tags = List.from(widget.node.tags);
    _status = widget.node.status;
    _color = widget.node.color;
    _startDate = widget.node.startDate;
    _endDate = widget.node.endDate;
    _customFields = List.from(widget.node.customFields);
    _notesController = TextEditingController(text: widget.node.notes);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = NodesLocalizations.of(context);
    final controller = Provider.of<NodesController>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isNew ? l10n.addNode : l10n.editNode),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _saveNode(context, controller),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 面包屑导航
            NodeBreadcrumbs(
              notebookId: widget.notebookId,
              node: widget.node,
              isNew: widget.isNew,
              controller: controller,
            ),
            const SizedBox(height: 16),
            
            // 标题输入框
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.nodeTitle,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // 标签部分
            TagsSection(
              tags: _tags,
              onTagRemoved: (tag) {
                setState(() => _tags.remove(tag));
              },
              onTagAdded: (tag) {
                if (!_tags.contains(tag)) {
                  setState(() => _tags.add(tag));
                }
              },
            ),
            const SizedBox(height: 16),
            
            // 颜色选择器
            ColorPickerSection(
              selectedColor: _color,
              onColorChanged: (color) {
                setState(() => _color = color);
              },
            ),
            const SizedBox(height: 16),
            
            // 状态下拉框
            StatusDropdown(
              value: _status,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // 日期部分
            DateSection(
              startDate: _startDate,
              endDate: _endDate,
              onStartDateChanged: (date) {
                setState(() => _startDate = date);
              },
              onEndDateChanged: (date) {
                setState(() => _endDate = date);
              },
            ),
            const SizedBox(height: 16),
            
            // 自定义字段部分
            CustomFieldsSection(
              customFields: _customFields,
              onCustomFieldValueChanged: (index, value) {
                setState(() {
                  _customFields[index] = CustomField(
                    key: _customFields[index].key,
                    value: value,
                  );
                });
              },
              onCustomFieldAdded: (field) {
                setState(() => _customFields.add(field));
              },
              onCustomFieldRemoved: (index) {
                setState(() => _customFields.removeAt(index));
              },
            ),
            const SizedBox(height: 16),
            
            // 笔记输入框
            Text(
              l10n.notes,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  void _saveNode(BuildContext context, NodesController controller) {
    // 计算节点的完整路径值
    String pathValue = _titleController.text;
    if (widget.node.parentId.isNotEmpty) {
      final parentNode = controller.findNodeById(widget.notebookId, widget.node.parentId);
      if (parentNode != null) {
        pathValue = '${parentNode.pathValue}/$pathValue';
      }
    }

    // 创建更新后的节点对象
    final updatedNode = Node(
      id: widget.node.id,
      parentId: widget.node.parentId,
      title: _titleController.text,
      tags: _tags,
      status: _status,
      startDate: _startDate,
      endDate: _endDate,
      customFields: _customFields,
      notes: _notesController.text,
      createdAt: widget.node.createdAt,
      pathValue: pathValue,
      children: widget.isNew ? [] : widget.node.children,
      color: _color,
    );

    if (widget.isNew) {
      // 添加新节点，确保传递父节点ID
      controller.addNode(
        widget.notebookId,
        updatedNode,
        parentId: widget.node.parentId,
      );
    } else {
      // 更新现有节点
      controller.updateNode(widget.notebookId, updatedNode);
    }

    // 返回上一页
    Navigator.pop(context);
  }
}