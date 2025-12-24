import 'package:flutter/material.dart';
import 'package:Memento/widgets/form_fields/index.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/goods/models/custom_field.dart';
import 'package:intl/intl.dart';

/// 表单字段组件测试页面
///
/// 按 Tab 分类展示 form_fields 目录下的各种组件
class FormFieldsTestScreen extends StatefulWidget {
  const FormFieldsTestScreen({super.key});

  @override
  State<FormFieldsTestScreen> createState() => _FormFieldsTestScreenState();
}

class _FormFieldsTestScreenState extends State<FormFieldsTestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 文本输入类状态
  final _textController = TextEditingController(text: '示例文本');
  final _textAreaController = TextEditingController(text: '多行文本示例\n第二行内容');
  bool _obscureText = false;

  // 选择器类状态
  String? _selectedValue = 'option1';
  DateTime? _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  Color _selectedColor = Colors.blue;

  // 开关和滑块类状态
  bool _switchValue = true;
  double _sliderValue = 50.0;

  // 列表和标签类状态
  final List<String> _tags = ['工作', '重要', '紧急'];
  final List<TodoItem> _todoItems = [
    TodoItem(title: '完成项目文档', completed: false),
    TodoItem(title: '代码审查', completed: true),
    TodoItem(title: '更新依赖', completed: false),
  ];
  final _todoController = TextEditingController();
  final List<CustomField> _customFields = [
    CustomField(key: '品牌', value: 'Apple'),
    CustomField(key: '型号', value: 'MacBook Pro'),
    CustomField(key: '购买年份', value: '2024'),
  ];

  // 其他组件状态
  final _iconTitleController = TextEditingController(text: '我的文件夹');
  IconData? _selectedIcon = Icons.folder;
  String? _selectedCategory = '工作';
  final List<String> _categories = ['工作', '生活', '学习', '娱乐'];
  final Map<String, IconData> _categoryIcons = {
    '工作': Icons.work,
    '生活': Icons.home,
    '学习': Icons.school,
    '娱乐': Icons.sports_esports,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _textAreaController.dispose();
    _todoController.dispose();
    _iconTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: const Text('表单字段组件测试'),
      largeTitle: '表单字段',
      body: Column(
        children: [
          // Tab 栏
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: '文本输入'),
                Tab(text: '选择器'),
                Tab(text: '开关滑块'),
                Tab(text: '列表标签'),
                Tab(text: '其他'),
              ],
            ),
          ),
          // Tab 内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextInputTab(),
                _buildSelectorTab(),
                _buildSwitchSliderTab(),
                _buildListTagsTab(),
                _buildOtherTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 文本输入类组件
  Widget _buildTextInputTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('TextInputField - 单行文本输入'),
        const SizedBox(height: 8),
        TextInputField(
          controller: _textController,
          labelText: '用户名',
          hintText: '请输入用户名',
          prefixIcon: const Icon(Icons.person),
        ),
        const SizedBox(height: 16),

        TextInputField(
          controller: TextEditingController(),
          labelText: '密码',
          hintText: '请输入密码',
          obscureText: _obscureText,
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() => _obscureText = !_obscureText);
            },
          ),
        ),
        const SizedBox(height: 16),

        TextInputField(
          controller: TextEditingController(),
          labelText: '邮箱',
          hintText: 'example@mail.com',
          prefixIcon: const Icon(Icons.email),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('TextAreaField - 多行文本输入'),
        const SizedBox(height: 8),
        TextAreaField(
          controller: _textAreaController,
          labelText: '描述',
          hintText: '请输入详细描述',
          minLines: 3,
          maxLines: 6,
        ),
        const SizedBox(height: 16),

        // inline 模式示例
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextAreaField(
            controller: TextEditingController(),
            hintText: '无边框模式的多行输入',
            minLines: 2,
            maxLines: 4,
            inline: true,
          ),
        ),
      ],
    );
  }

  /// 选择器类组件
  Widget _buildSelectorTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('SelectField - 下拉选择'),
        const SizedBox(height: 8),
        SelectField<String>(
          value: _selectedValue,
          labelText: '选择选项',
          hintText: '请选择',
          items: const [
            DropdownMenuItem(value: 'option1', child: Text('选项一')),
            DropdownMenuItem(value: 'option2', child: Text('选项二')),
            DropdownMenuItem(value: 'option3', child: Text('选项三')),
          ],
          onChanged: (value) {
            setState(() => _selectedValue = value);
          },
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('DatePickerField - 日期选择'),
        const SizedBox(height: 8),
        DatePickerField(
          date: _selectedDate,
          formattedDate:
              _selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                  : '',
          placeholder: '选择日期',
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('TimePickerField - 时间选择'),
        const SizedBox(height: 8),
        TimePickerField(
          label: '选择时间',
          time: _selectedTime,
          onTimeChanged: (time) {
            setState(() => _selectedTime = time);
          },
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('ColorSelectorField - 颜色选择'),
        const SizedBox(height: 8),
        ColorSelectorField(
          labelText: '选择颜色',
          selectedColor: _selectedColor,
          onColorChanged: (color) {
            setState(() => _selectedColor = color);
          },
        ),
      ],
    );
  }

  /// 开关和滑块类组件
  Widget _buildSwitchSliderTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('SwitchField - 开关选择'),
        const SizedBox(height: 8),
        SwitchField(
          value: _switchValue,
          title: '启用通知',
          subtitle: '接收推送通知消息',
          icon: Icons.notifications,
          onChanged: (value) {
            setState(() => _switchValue = value);
          },
        ),
        const SizedBox(height: 16),

        SwitchField(
          value: false,
          title: '自动保存',
          subtitle: '编辑时自动保存更改',
          icon: Icons.save,
          onChanged: (value) {},
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('SliderField - 滑块选择'),
        const SizedBox(height: 8),
        SliderField(
          label: '音量',
          valueText: '${_sliderValue.toInt()}%',
          min: 0,
          max: 100,
          value: _sliderValue,
          divisions: 20,
          onChanged: (value) {
            setState(() => _sliderValue = value);
          },
          quickValues: [0, 25, 50, 75, 100],
          quickValueLabel: (v) => '${v.toInt()}%',
          onQuickValueTap: (value) {
            setState(() => _sliderValue = value);
          },
        ),
        const SizedBox(height: 16),

        SliderField(
          label: '亮度',
          valueText: '${(_sliderValue / 100 * 50).toInt()}%',
          min: 0,
          max: 100,
          value: _sliderValue / 2,
          onChanged: (value) {
            setState(() => _sliderValue = value * 2);
          },
        ),
      ],
    );
  }

  /// 列表和标签类组件
  Widget _buildListTagsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('TagsField - 标签选择'),
        const SizedBox(height: 8),
        TagsField(
          tags: _tags,
          addButtonText: '添加标签',
          onAddTag: () {
            // 显示添加标签对话框
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('添加标签'),
                    content: TextField(
                      decoration: const InputDecoration(hintText: '标签名称'),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          setState(() => _tags.add(value));
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
            );
          },
          onRemoveTag: (tag) {
            setState(() => _tags.remove(tag));
          },
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('ListAddField - 列表添加'),
        const SizedBox(height: 8),
        ListAddField<TodoItem>(
          items: _todoItems,
          controller: _todoController,
          addButtonText: '添加待办',
          onAdd: () {
            if (_todoController.text.isNotEmpty) {
              setState(() {
                _todoItems.add(
                  TodoItem(title: _todoController.text, completed: false),
                );
                _todoController.clear();
              });
            }
          },
          onToggle: (index) {
            setState(() {
              _todoItems[index].completed = !_todoItems[index].completed;
            });
          },
          onRemove: (index) {
            setState(() => _todoItems.removeAt(index));
          },
          getTitle: (item) => item.title,
          getIsCompleted: (item) => item.completed,
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('CustomFieldsField - 自定义字段'),
        const SizedBox(height: 8),
        CustomFieldsField(
          fields: _customFields,
          labelText: '物品属性',
          addButtonText: '添加字段',
          onFieldsChanged: (fields) {
            setState(() {
              _customFields.clear();
              _customFields.addAll(fields);
            });
          },
        ),
      ],
    );
  }

  /// 其他组件
  Widget _buildOtherTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('IconTitleField - 图标标题'),
        const SizedBox(height: 8),
        IconTitleField(
          controller: _iconTitleController,
          icon: _selectedIcon,
          hintText: '输入标题',
          onIconTap: () {
            // 简单演示图标切换
            setState(() {
              _selectedIcon =
                  _selectedIcon == Icons.folder
                      ? Icons.folder_open
                      : Icons.folder;
            });
          },
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('CategorySelectorField - 类别选择'),
        const SizedBox(height: 8),
        CategorySelectorField(
          categories: _categories,
          selectedCategory: _selectedCategory,
          categoryIcons: _categoryIcons,
          onCategoryChanged: (category) {
            setState(() => _selectedCategory = category);
          },
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('FormFieldGroup - 表单字段组'),
        const SizedBox(height: 8),
        FormFieldGroup(
          children: [
            TextInputField(
              controller: TextEditingController(),
              labelText: '姓名',
              hintText: '请输入姓名',
              inline: true,
            ),
            DatePickerField(
              date: _selectedDate,
              formattedDate:
                  _selectedDate != null
                      ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                      : '',
              placeholder: '选择生日',
              labelText: '生日',
              inline: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            SwitchField(
              value: true,
              title: '公开资料',
              inline: true,
              onChanged: (value) {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// 简单的待办项模型
class TodoItem {
  final String title;
  bool completed;

  TodoItem({required this.title, this.completed = false});
}
