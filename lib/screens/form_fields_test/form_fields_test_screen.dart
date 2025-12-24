import 'package:flutter/material.dart';
import 'package:Memento/widgets/form_fields/index.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/goods/models/custom_field.dart';
import 'package:intl/intl.dart';

/// 表单字段组件测试页面
///
/// 按 Tab 分类展示 form_fields 目录下的各种组件
/// 使用 FormBuilderWrapper 进行统一管理
class FormFieldsTestScreen extends StatefulWidget {
  const FormFieldsTestScreen({super.key});

  @override
  State<FormFieldsTestScreen> createState() => _FormFieldsTestScreenState();
}

class _FormFieldsTestScreenState extends State<FormFieldsTestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                Tab(text: 'Picker选择器'),
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
                _buildPickerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 文本输入类组件
  Widget _buildTextInputTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormBuilderWrapper(
        config: FormConfig(
          fields: [
            // 单行文本输入 - 用户名
            FormFieldConfig(
              name: 'username',
              type: FormFieldType.text,
              labelText: '用户名',
              hintText: '请输入用户名',
              initialValue: '示例文本',
              prefixIcon: Icons.person,
            ),

            // 密码输入
            FormFieldConfig(
              name: 'password',
              type: FormFieldType.password,
              labelText: '密码',
              hintText: '请输入密码',
              prefixIcon: Icons.lock,
            ),

            // 邮箱输入
            FormFieldConfig(
              name: 'email',
              type: FormFieldType.email,
              labelText: '邮箱',
              hintText: 'example@mail.com',
              prefixIcon: Icons.email,
              required: true,
              validationMessage: '请输入有效的邮箱地址',
            ),

            // 多行文本输入 - 描述
            FormFieldConfig(
              name: 'description',
              type: FormFieldType.textArea,
              labelText: '描述',
              hintText: '请输入详细描述',
              initialValue: '多行文本示例\n第二行内容',
              extra: {'minLines': 3, 'maxLines': 6},
            ),

            // 无边框模式多行输入
            FormFieldConfig(
              name: 'notes',
              type: FormFieldType.textArea,
              hintText: '无边框模式的多行输入',
              extra: {
                'minLines': 2,
                'maxLines': 4,
                'inline': true,
              },
            ),
          ],
          submitButtonText: '提交文本表单',
          showResetButton: true,
          onSubmit: (values) => _showResult('文本输入表单', values),
        ),
      ),
    );
  }

  /// 选择器类组件
  Widget _buildSelectorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormBuilderWrapper(
        config: FormConfig(
          fields: [
            // 下拉选择
            FormFieldConfig(
              name: 'option',
              type: FormFieldType.select,
              labelText: '选择选项',
              hintText: '请选择',
              initialValue: 'option1',
              required: true,
              items: const [
                DropdownMenuItem(value: 'option1', child: Text('选项一')),
                DropdownMenuItem(value: 'option2', child: Text('选项二')),
                DropdownMenuItem(value: 'option3', child: Text('选项三')),
              ],
            ),

            // 日期选择
            FormFieldConfig(
              name: 'date',
              type: FormFieldType.date,
              labelText: '出生日期',
              hintText: '选择日期',
              initialValue: DateTime.now(),
              extra: {
                'format': 'yyyy-MM-dd',
                'firstDate': DateTime(2000),
                'lastDate': DateTime(2100),
              },
            ),

            // 时间选择
            FormFieldConfig(
              name: 'time',
              type: FormFieldType.time,
              labelText: '选择时间',
              initialValue: TimeOfDay.now(),
            ),

            // 颜色选择
            FormFieldConfig(
              name: 'color',
              type: FormFieldType.color,
              labelText: '选择颜色',
              initialValue: Colors.blue,
            ),
          ],
          submitButtonText: '提交选择器表单',
          showResetButton: true,
          onSubmit: (values) => _showResult('选择器表单', values),
        ),
      ),
    );
  }

  /// 开关和滑块类组件
  Widget _buildSwitchSliderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormBuilderWrapper(
        config: FormConfig(
          fields: [
            // 开关 - 启用通知
            FormFieldConfig(
              name: 'notifications',
              type: FormFieldType.switchField,
              labelText: '启用通知',
              hintText: '接收推送通知消息',
              initialValue: true,
              prefixIcon: Icons.notifications,
            ),

            // 开关 - 自动保存
            FormFieldConfig(
              name: 'autoSave',
              type: FormFieldType.switchField,
              labelText: '自动保存',
              hintText: '编辑时自动保存更改',
              initialValue: false,
              prefixIcon: Icons.save,
            ),

            // 滑块 - 音量
            FormFieldConfig(
              name: 'volume',
              type: FormFieldType.slider,
              labelText: '音量',
              initialValue: 50.0,
              min: 0,
              max: 100,
              divisions: 20,
              quickValues: [0, 25, 50, 75, 100],
              extra: {
                'valueText': '%',
                'quickValueLabel': (v) => '${v.toInt()}%',
              },
            ),

            // 滑块 - 亮度
            FormFieldConfig(
              name: 'brightness',
              type: FormFieldType.slider,
              labelText: '亮度',
              initialValue: 25.0,
              min: 0,
              max: 100,
              extra: {
                'valueText': '%',
              },
            ),
          ],
          submitButtonText: '提交开关滑块表单',
          showResetButton: true,
          onSubmit: (values) => _showResult('开关滑块表单', values),
        ),
      ),
    );
  }

  /// 列表和标签类组件
  Widget _buildListTagsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormBuilderWrapper(
        config: FormConfig(
          fields: [
            // 标签选择
            FormFieldConfig(
              name: 'tags',
              type: FormFieldType.tags,
              labelText: '标签管理',
              hintText: '添加标签',
              initialTags: ['工作', '重要', '紧急'],
            ),

            // 列表添加 - 待办事项
            FormFieldConfig(
              name: 'todos',
              type: FormFieldType.listAdd,
              labelText: '待办事项',
              hintText: '添加待办',
              extra: {
                'initialItems': [
                  TodoItem(title: '完成项目文档', completed: false),
                  TodoItem(title: '代码审查', completed: true),
                  TodoItem(title: '更新依赖', completed: false),
                ],
                'getTitle': (TodoItem item) => item.title,
                'getIsCompleted': (TodoItem item) => item.completed,
                'onToggle': (int index, TodoItem item) {
                  item.completed = !item.completed;
                },
              },
            ),

            // 自定义字段
            FormFieldConfig(
              name: 'customFields',
              type: FormFieldType.customFields,
              labelText: '物品属性',
              hintText: '添加字段',
              initialCustomFields: [
                CustomField(key: '品牌', value: 'Apple'),
                CustomField(key: '型号', value: 'MacBook Pro'),
                CustomField(key: '购买年份', value: '2024'),
              ],
            ),
          ],
          submitButtonText: '提交列表标签表单',
          showResetButton: true,
          onSubmit: (values) => _showResult('列表标签表单', values),
        ),
      ),
    );
  }

  /// 其他组件
  Widget _buildOtherTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormBuilderWrapper(
        config: FormConfig(
          fields: [
            // 图标标题
            FormFieldConfig(
              name: 'iconTitle',
              type: FormFieldType.iconTitle,
              hintText: '输入标题',
              initialValue: '我的文件夹',
              prefixIcon: Icons.folder,
            ),

            // 类别选择
            FormFieldConfig(
              name: 'category',
              type: FormFieldType.categorySelector,
              labelText: '选择类别',
              hintText: '请选择类别',
              initialValue: '工作',
              required: true,
              categories: ['工作', '生活', '学习', '娱乐'],
              categoryIcons: {
                '工作': Icons.work,
                '生活': Icons.home,
                '学习': Icons.school,
                '娱乐': Icons.sports_esports,
              },
            ),
          ],
          submitButtonText: '提交其他表单',
          showResetButton: true,
          onSubmit: (values) => _showResult('其他表单', values),
        ),
      ),
    );
  }

  /// Picker 选择器类组件（新增）
  Widget _buildPickerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormBuilderWrapper(
        config: FormConfig(
          fields: [
            // 图标选择器
            FormFieldConfig(
              name: 'icon',
              type: FormFieldType.iconPicker,
              labelText: '选择图标',
              initialValue: Icons.star,
              extra: {'enableIconToImage': false},
            ),

            // 头像选择器
            FormFieldConfig(
              name: 'avatar',
              type: FormFieldType.avatarPicker,
              extra: {
                'username': 'Memento',
                'size': 80.0,
                'saveDirectory': 'avatars',
              },
            ),

            // 圆形图标选择器
            FormFieldConfig(
              name: 'circleIcon',
              type: FormFieldType.circleIconPicker,
              initialValue: {'icon': Icons.favorite, 'color': Colors.pink},
              extra: {'initialBackgroundColor': Colors.pink},
            ),

            // 日历条日期选择器
            FormFieldConfig(
              name: 'calendarDate',
              type: FormFieldType.calendarStripPicker,
              initialValue: DateTime.now(),
              extra: {
                'allowFutureDates': false,
                'useShortWeekDay': false,
              },
            ),

            // 图片选择器
            FormFieldConfig(
              name: 'image',
              type: FormFieldType.imagePicker,
              labelText: '选择图片',
              hintText: '点击选择图片',
              extra: {
                'saveDirectory': 'test_images',
                'enableCrop': false,
                'multiple': false,
                'enableCompression': false,
              },
            ),

            // 位置选择器
            FormFieldConfig(
              name: 'location',
              type: FormFieldType.locationPicker,
              labelText: '选择位置',
              hintText: '点击选择位置',
            ),
          ],
          submitButtonText: '提交 Picker 表单',
          showResetButton: true,
          onSubmit: (values) => _showResult('Picker 选择器表单', values),
        ),
      ),
    );
  }

  /// 显示提交结果
  void _showResult(String title, Map<String, dynamic> values) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title - 提交结果'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: values.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        _formatValue(entry.value),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // 可以复制到剪贴板或其他操作
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );
  }

  /// 格式化值用于显示
  String _formatValue(dynamic value) {
    if (value == null) return '空';
    if (value is DateTime) {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(value);
    }
    if (value is TimeOfDay) {
      return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    }
    if (value is Color) {
      return '#${value.value.toRadixString(16).substring(2).toUpperCase()}';
    }
    if (value is List || value is Map) {
      return value.toString();
    }
    return value.toString();
  }
}

/// 简单的待办项模型
class TodoItem {
  final String title;
  bool completed;

  TodoItem({required this.title, this.completed = false});

  @override
  String toString() => '$title ${completed ? "✓" : ""}';
}
