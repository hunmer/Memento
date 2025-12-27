import 'package:get/get.dart' hide Node;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'dart:convert';
import 'package:Memento/plugins/nodes/controllers/nodes_controller.dart';
import 'package:Memento/plugins/nodes/models/node.dart';
import 'components/breadcrumbs.dart';
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
  // FormBuilderWrapper 的 key，用于访问表单状态
  final GlobalKey<FormBuilderState> _basicInfoFormKey = GlobalKey<FormBuilderState>();

  // 自定义字段列表
  late List<NodeCustomField> _customFields;

  // 日期范围状态
  DateTime? _startDate;
  DateTime? _endDate;

  // Quill 编辑器控制器（保留）
  late quill.QuillController _quillController;

  // TabController（保留）
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 初始化自定义字段列表
    _customFields = List.from(widget.node.customFields);
    // 初始化日期范围
    _startDate = widget.node.startDate;
    _endDate = widget.node.endDate;
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

          // 使用 FormBuilderWrapper
          FormBuilderWrapper(
            formKey: _basicInfoFormKey,
            config: FormConfig(
              showSubmitButton: false,
              showResetButton: false,
              fieldSpacing: 16,
              fields: [
                // 标题输入框
                FormFieldConfig(
                  name: 'title',
                  type: FormFieldType.text,
                  labelText: 'nodes_nodeTitle'.tr,
                  hintText: '请输入节点标题',
                  initialValue: widget.node.title,
                  required: true,
                  validationMessage: '${'nodes_nodeTitle'.tr}不能为空',
                ),

                // 标签字段
                FormFieldConfig(
                  name: 'tags',
                  type: FormFieldType.tags,
                  labelText: 'nodes_tags'.tr,
                  hintText: '添加标签',
                  initialTags: widget.node.tags,
                ),

                // 颜色选择器（单行 inline 模式 + 水平滚动）
                FormFieldConfig(
                  name: 'color',
                  type: FormFieldType.color,
                  labelText: 'nodes_nodeColor'.tr,
                  initialValue: widget.node.color,
                  extra: {'inline': true, 'scrollable': true, 'labelWidth': 80},
                ),

                // 状态下拉框
                FormFieldConfig(
                  name: 'status',
                  type: FormFieldType.select,
                  labelText: 'nodes_status'.tr,
                  hintText: '请选择状态',
                  initialValue: widget.node.status,
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
              onSubmit: (values) {
                // 提交处理在外部统一处理
              },
            ),
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
          // 日期范围选择器
          DateRangeField(
            startDate: _startDate,
            endDate: _endDate,
            rangeLabelText: 'nodes_dateRange'.tr,
            onDateRangeChanged: (range) {
              setState(() {
                _startDate = range?.start;
                _endDate = range?.end;
              });
            },
          ),
          const SizedBox(height: 16),
          CustomFieldsField(
            fields: _customFields,
            onFieldsChanged: (fields) {
              setState(() => _customFields = fields);
            },
            labelText: 'nodes_customFields'.tr,
            addDialogTitle: 'nodes_addCustomField'.tr,
            editDialogTitle: 'nodes_editCustomField'.tr,
            deleteConfirmTitle: 'nodes_deleteCustomField'.tr,
            deleteConfirmContent: 'nodes_deleteCustomFieldConfirm'.tr,
            addButtonText: 'nodes_addCustomField'.tr,
            fieldNameLabel: 'nodes_fieldName'.tr,
            fieldNameHint: 'nodes_fieldNameHint'.tr,
            fieldValueLabel: 'nodes_fieldValue'.tr,
            fieldValueHint: 'nodes_fieldValueHint'.tr,
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
    // 获取基本信息表单的值
    final basicInfoState = _basicInfoFormKey.currentState;
    if (basicInfoState == null || !basicInfoState.saveAndValidate()) {
      // 验证失败
      return;
    }
    final basicInfoValues = basicInfoState.value;

    // 从表单值中提取数据
    final title = basicInfoValues['title'] as String? ?? '';
    final tags = (basicInfoValues['tags'] as List<dynamic>?)
            ?.cast<String>() ??
        [];
    final status = basicInfoValues['status'] as NodeStatus? ??
        widget.node.status;
    final color = basicInfoValues['color'] as Color? ?? Colors.grey;

    // 使用状态变量中的日期和自定义字段
    final startDate = _startDate;
    final endDate = _endDate;
    final customFields = _customFields;

    // 计算节点的完整路径值
    String pathValue = title;
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
      title: title,
      tags: tags,
      status: status,
      startDate: startDate,
      endDate: endDate,
      customFields: customFields,
      notes: notesJson,
      createdAt: widget.node.createdAt,
      pathValue: pathValue,
      children: widget.isNew ? [] : widget.node.children,
      color: color,
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
