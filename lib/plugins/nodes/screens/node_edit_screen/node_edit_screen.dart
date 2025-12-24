import 'package:get/get.dart' hide Node;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'package:Memento/plugins/nodes/controllers/nodes_controller.dart';
import 'package:Memento/plugins/nodes/models/node.dart';
import 'components/breadcrumbs.dart';
import 'components/custom_fields_section.dart';
import 'package:Memento/widgets/form_fields/index.dart';

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

class NodeEditScreenState extends State<NodeEditScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late List<String> _tags;
  late NodeStatus _status;
  late Color _color;
  DateTime? _startDate;
  DateTime? _endDate;
  late List<CustomField> _customFields;
  late quill.QuillController _quillController;
  late TabController _tabController;

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

    // 初始化 Quill 编辑器
    _quillController = _initializeQuillController();

    // 初始化 TabController
    _tabController = TabController(length: 3, vsync: this);
  }

  quill.QuillController _initializeQuillController() {
    if (widget.node.notes.isNotEmpty) {
      try {
        // 尝试解析 JSON 格式的 Delta
        final doc = quill.Document.fromJson(jsonDecode(widget.node.notes));
        return quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // 如果不是 JSON 格式,作为纯文本处理
        final doc = quill.Document()..insert(0, widget.node.notes);
        return quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      return quill.QuillController.basic();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final controller = Provider.of<NodesController>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isNew ? 'nodes_addNode'.tr : 'nodes_editNode'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _saveNode(context, controller),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'nodes_basicInfo'.tr),
            Tab(text: 'nodes_dateAndFields'.tr),
            Tab(text: 'nodes_notes'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: 基本信息
          _buildBasicInfoTab(context, controller),
          // Tab 2: 时间与字段
          _buildDateAndFieldsTab(context),
          // Tab 3: 笔记内容
          _buildNotesTab(context),
        ],
      ),
    );
  }

  // Tab 1: 基本信息
  Widget _buildBasicInfoTab(BuildContext context, NodesController controller) {
    return SingleChildScrollView(
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
          TextInputField(
            controller: _titleController,
            labelText: 'nodes_nodeTitle'.tr,
            hintText: '请输入节点标题',
          ),
          const SizedBox(height: 16),

          // 标签部分
          TagsField(
            tags: _tags,
            onAddTag: () => _showAddTagDialog(context),
            onRemoveTag: (tag) {
              setState(() => _tags.remove(tag));
            },
            addButtonText: '添加标签',
          ),
          const SizedBox(height: 16),

          // 颜色选择器
          ColorSelectorField(
            selectedColor: _color,
            onColorChanged: (color) {
              setState(() => _color = color);
            },
            labelText: 'nodes_nodeColor'.tr,
          ),
          const SizedBox(height: 16),

          // 状态下拉框
          SelectField<NodeStatus>(
            value: _status,
            onChanged: (value) {
              if (value != null) {
                setState(() => _status = value);
              }
            },
            labelText: 'nodes_status'.tr,
            hintText: '请选择状态',
            items: NodeStatus.values.map((status) {
              String label;
              switch (status) {
                case NodeStatus.none:
                  label = 'nodes_none'.tr;
                  break;
                case NodeStatus.todo:
                  label = 'nodes_todo'.tr;
                  break;
                case NodeStatus.doing:
                  label = 'nodes_doing'.tr;
                  break;
                case NodeStatus.done:
                  label = 'nodes_done'.tr;
                  break;
              }
              return DropdownMenuItem(
                value: status,
                child: Text(label),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Tab 2: 时间与字段
  Widget _buildDateAndFieldsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期部分
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'nodes_dateRange'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DatePickerField(
                      date: _startDate,
                      onTap: () => _selectDate(context, true),
                      formattedDate: _startDate != null
                          ? '${_startDate!.year}/${_startDate!.month}/${_startDate!.day}'
                          : '',
                      placeholder: 'nodes_startDate'.tr,
                      icon: Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DatePickerField(
                      date: _endDate,
                      onTap: () => _selectDate(context, false),
                      formattedDate: _endDate != null
                          ? '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}'
                          : '',
                      placeholder: 'nodes_endDate'.tr,
                      icon: Icons.calendar_today,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 自定义字段部分
          CustomFieldsSection(
            initialFields: _customFields,
            onFieldsChanged: (fields) {
              setState(() {
                _customFields = fields;
              });
            },
          ),
        ],
      ),
    );
  }

  // Tab 3: 笔记内容
  Widget _buildNotesTab(BuildContext context) {
    return Column(
      children: [
        // Quill 工具栏
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // 历史操作
                quill.QuillToolbarHistoryButton(
                  isUndo: true,
                  controller: _quillController,
                ),
                quill.QuillToolbarHistoryButton(
                  isUndo: false,
                  controller: _quillController,
                ),
                const VerticalDivider(),

                // 文本样式
                quill.QuillToolbarToggleStyleButton(
                  controller: _quillController,
                  attribute: quill.Attribute.bold,
                ),
                quill.QuillToolbarToggleStyleButton(
                  controller: _quillController,
                  attribute: quill.Attribute.italic,
                ),
                quill.QuillToolbarToggleStyleButton(
                  controller: _quillController,
                  attribute: quill.Attribute.underline,
                ),
                quill.QuillToolbarToggleStyleButton(
                  controller: _quillController,
                  attribute: quill.Attribute.strikeThrough,
                ),
                quill.QuillToolbarClearFormatButton(
                  controller: _quillController,
                ),
                const VerticalDivider(),

                // 标题样式
                quill.QuillToolbarSelectHeaderStyleDropdownButton(
                  controller: _quillController,
                ),
                const VerticalDivider(),

                // 颜色
                quill.QuillToolbarColorButton(
                  controller: _quillController,
                  isBackground: false,
                ),
                quill.QuillToolbarColorButton(
                  controller: _quillController,
                  isBackground: true,
                ),
                const VerticalDivider(),

                // 对齐方式
                quill.QuillToolbarSelectAlignmentButton(
                  controller: _quillController,
                ),
                const VerticalDivider(),

                // 列表
                quill.QuillToolbarToggleCheckListButton(
                  controller: _quillController,
                ),
                quill.QuillToolbarToggleStyleButton(
                  controller: _quillController,
                  attribute: quill.Attribute.ul,
                ),
                quill.QuillToolbarToggleStyleButton(
                  controller: _quillController,
                  attribute: quill.Attribute.ol,
                ),
                const VerticalDivider(),

                // 代码和引用
                quill.QuillToolbarToggleStyleButton(
                  controller: _quillController,
                  attribute: quill.Attribute.inlineCode,
                ),
                quill.QuillToolbarToggleStyleButton(
                  controller: _quillController,
                  attribute: quill.Attribute.codeBlock,
                ),
                quill.QuillToolbarToggleStyleButton(
                  controller: _quillController,
                  attribute: quill.Attribute.blockQuote,
                ),
                const VerticalDivider(),

                // 缩进
                quill.QuillToolbarIndentButton(
                  controller: _quillController,
                  isIncrease: true,
                ),
                quill.QuillToolbarIndentButton(
                  controller: _quillController,
                  isIncrease: false,
                ),
                const VerticalDivider(),

                // 链接
                quill.QuillToolbarLinkStyleButton(
                  controller: _quillController,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // Quill 编辑器
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: quill.QuillEditor.basic(
              controller: _quillController,
              config: const quill.QuillEditorConfig(
                padding: EdgeInsets.zero,
                placeholder: '请输入笔记内容...',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStart ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showAddTagDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加标签'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '标签名称',
            hintText: '请输入标签名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (!_tags.contains(result)) {
          _tags.add(result);
        }
      });
    }
  }

  void _saveNode(BuildContext context, NodesController controller) {
    // 计算节点的完整路径值
    String pathValue = _titleController.text;
    if (widget.node.parentId.isNotEmpty) {
      final parentNode = controller.findNodeById(
        widget.notebookId,
        widget.node.parentId,
      );
      if (parentNode != null) {
        pathValue = '${parentNode.pathValue}/$pathValue';
      }
    }

    // 将 Quill 文档转换为 JSON 字符串
    final notesJson = jsonEncode(_quillController.document.toDelta().toJson());

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
      notes: notesJson,
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
