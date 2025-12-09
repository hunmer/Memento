import 'package:get/get.dart' hide Node;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'package:Memento/plugins/nodes/controllers/nodes_controller.dart';
import 'package:Memento/plugins/nodes/models/node.dart';
import 'components/breadcrumbs.dart';
import 'package:Memento/widgets/color_picker_section.dart';
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
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'nodes_nodeTitle'.tr,
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
