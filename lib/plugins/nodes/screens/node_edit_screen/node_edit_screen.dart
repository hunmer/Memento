import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import '../../controllers/nodes_controller.dart';
import '../../models/node.dart';
import '../../l10n/nodes_localizations.dart';
import 'components/breadcrumbs.dart';
import '../../../../widgets/color_picker_section.dart';
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.basicInfo),
            Tab(text: l10n.dateAndFields),
            Tab(text: l10n.notes),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: 基本信息
          _buildBasicInfoTab(context, controller, l10n),
          // Tab 2: 时间与字段
          _buildDateAndFieldsTab(context, l10n),
          // Tab 3: 笔记内容
          _buildNotesTab(context, l10n),
        ],
      ),
    );
  }

  // Tab 1: 基本信息
  Widget _buildBasicInfoTab(BuildContext context, NodesController controller, NodesLocalizations l10n) {
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
        ],
      ),
    );
  }

  // Tab 2: 时间与字段
  Widget _buildDateAndFieldsTab(BuildContext context, NodesLocalizations l10n) {
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
  Widget _buildNotesTab(BuildContext context, NodesLocalizations l10n) {
    return Column(
      children: [
        // Quill 工具栏
        quill.QuillToolbar.simple(
          controller: _quillController,
          configurations: const quill.QuillSimpleToolbarConfigurations(
            showAlignmentButtons: true,
            showBackgroundColorButton: true,
            showBoldButton: true,
            showCenterAlignment: true,
            showClearFormat: true,
            showColorButton: true,
            showCodeBlock: true,
            showDirection: false,
            showDividers: true,
            showFontFamily: false,
            showFontSize: true,
            showHeaderStyle: true,
            showIndent: true,
            showInlineCode: true,
            showItalicButton: true,
            showJustifyAlignment: true,
            showLeftAlignment: true,
            showLink: true,
            showListBullets: true,
            showListCheck: true,
            showListNumbers: true,
            showQuote: true,
            showRightAlignment: true,
            showSmallButton: false,
            showStrikeThrough: true,
            showSubscript: false,
            showSuperscript: false,
            showUnderLineButton: true,
          ),
        ),
        const Divider(height: 1),
        // Quill 编辑器
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: quill.QuillEditor.basic(
              controller: _quillController,
              configurations: const quill.QuillEditorConfigurations(
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
