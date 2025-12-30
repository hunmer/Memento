import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:Memento/plugins/scripts_center/models/script_info.dart';
import 'package:Memento/plugins/scripts_center/models/script_input.dart';
import 'package:Memento/plugins/scripts_center/models/script_trigger.dart';
import 'package:Memento/plugins/scripts_center/services/script_manager.dart';
import 'package:Memento/plugins/scripts_center/widgets/script_input_edit_dialog.dart';
import 'package:Memento/utils/file_picker_helper.dart';
import 'package:Memento/widgets/form_fields/form_builder_wrapper.dart';
import 'package:Memento/widgets/form_fields/config.dart';
import 'package:Memento/widgets/form_fields/types.dart';
import 'package:Memento/widgets/form_fields/event_multi_select_field.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:get/get.dart';

/// 脚本编辑屏幕
///
/// 完整的脚本编辑界面，包含：
/// - 基本信息编辑
/// - 代码编辑器
/// - 触发条件选择器
/// - 高级设置
class ScriptEditScreen extends StatefulWidget {
  /// 如果为null则为创建模式，否则为编辑模式
  final ScriptInfo? script;

  /// 脚本管理器（用于加载代码）
  final ScriptManager scriptManager;

  /// 初始数据（用于导入模式）
  final Map<String, dynamic>? initialData;

  const ScriptEditScreen({
    super.key,
    this.script,
    required this.scriptManager,
    this.initialData,
  });

  @override
  State<ScriptEditScreen> createState() => _ScriptEditScreenState();
}

/// 事件选项
class _EventOption {
  final String eventName;
  final String category;
  final String description;

  _EventOption(this.eventName, this.category, this.description);
}

class _ScriptEditScreenState extends State<ScriptEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 基本信息 Tab 的表单状态
  final GlobalKey<FormBuilderState> _basicInfoFormKey =
      GlobalKey<FormBuilderState>();
  FormBuilderWrapperState? _basicInfoWrapperState;

  // 高级设置 Tab 的表单状态
  final GlobalKey<FormBuilderState> _advancedFormKey =
      GlobalKey<FormBuilderState>();
  FormBuilderWrapperState? _advancedWrapperState;

  // 配置 Tab 的状态
  final GlobalKey<FormBuilderState> _configFormKey =
      GlobalKey<FormBuilderState>();
  FormBuilderWrapperState? _configWrapperState;
  Map<String, dynamic>? _currentConfig;

  // 配置表单字段定义（用于动态渲染配置界面）
  List<FormFieldConfig> _configFormFields = [];

  // 代码编辑器控制器
  late final TextEditingController _codeController;

  // 输入参数列表
  List<ScriptInput> _inputs = [];

  // 触发条件列表
  List<ScriptTrigger> _triggers = [];

  // 是否自动运行
  bool _autoRun = false;

  // 本地脚本文件路径
  String? _localScriptPath;

  // 图标名称到 IconData 的映射
  static const Map<String, IconData> _iconMap = {
    'code': Icons.code,
    'backup': Icons.backup,
    'analytics': Icons.analytics,
    'settings': Icons.settings,
    'sync': Icons.sync,
    'schedule': Icons.schedule,
    'notification': Icons.notifications,
    'data': Icons.storage,
    'auto': Icons.autorenew,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'build': Icons.build,
  };

  // IconData 到图标名称的反向映射（不能是 const，因为 IconData 重写了 == 和 hashCode）
  static final Map<IconData, String> _iconNameMap = {
    Icons.code: 'code',
    Icons.backup: 'backup',
    Icons.analytics: 'analytics',
    Icons.settings: 'settings',
    Icons.sync: 'sync',
    Icons.schedule: 'schedule',
    Icons.notifications: 'notification',
    Icons.storage: 'data',
    Icons.autorenew: 'auto',
    Icons.star: 'star',
    Icons.favorite: 'favorite',
    Icons.build: 'build',
  };

  // 可用事件列表（从项目中收集的所有事件）
  final List<_EventOption> _availableEvents = [
    // 核心事件
    _EventOption('plugins_initialized', '插件系统', '所有插件初始化完成'),

    // 日记插件事件
    _EventOption('diary_entry_created', '日记', '创建日记条目'),
    _EventOption('diary_entry_updated', '日记', '更新日记条目'),
    _EventOption('diary_entry_deleted', '日记', '删除日记条目'),

    // 活动插件事件
    _EventOption('activity_added', '活动', '添加活动记录'),
    _EventOption('activity_deleted', '活动', '删除活动记录'),

    // 笔记插件事件
    _EventOption('note_added', '笔记', '添加笔记'),
    _EventOption('note_deleted', '笔记', '删除笔记'),

    // 任务插件事件
    _EventOption('task_added', '任务', '添加任务'),
    _EventOption('task_deleted', '任务', '删除任务'),
    _EventOption('task_completed', '任务', '完成任务'),

    // 签到插件事件
    _EventOption('checkin_completed', '签到', '完成签到'),
    _EventOption('checkin_deleted', '签到', '删除签到记录'),

    // 账单插件事件
    _EventOption('bill_added', '账单', '添加账单'),
    _EventOption('bill_deleted', '账单', '删除账单'),
    _EventOption('account_added', '账单', '添加账户'),
    _EventOption('account_deleted', '账单', '删除账户'),

    // 物品管理事件
    _EventOption('goods_item_added', '物品', '添加物品'),
    _EventOption('goods_item_deleted', '物品', '删除物品'),

    // 聊天插件事件
    _EventOption('chat_message_sent', '聊天', '发送消息'),
    _EventOption('chat_message_updated', '聊天', '更新消息'),
    _EventOption('UserEventNames.userAvatarUpdated', '聊天', '更新用户头像'),

    // 追踪器事件
    _EventOption('onRecordAdded', '追踪器', '添加记录'),

    // 计时器事件
    _EventOption('timer_task_changed', '计时器', '任务变更'),
    _EventOption('timer_item_changed', '计时器', '项目变更'),
    _EventOption('timer_item_progress', '计时器', '项目进度更新'),

    // 商店事件
    _EventOption('store_product_added', '商店', '添加商品'),
    _EventOption('store_product_deleted', '商店', '删除商品'),
    _EventOption('store_purchase', '商店', '购买商品'),

    // 习惯插件事件
    _EventOption('habit_added', '习惯', '添加习惯'),
    _EventOption('habit_deleted', '习惯', '删除习惯'),
    _EventOption('habit_checked', '习惯', '打卡习惯'),

    // 联系人事件
    _EventOption('contact_added', '联系人', '添加联系人'),
    _EventOption('contact_deleted', '联系人', '删除联系人'),

    // 纪念日事件
    _EventOption('memorial_day_added', '纪念日', '添加纪念日'),
    _EventOption('memorial_day_deleted', '纪念日', '删除纪念日'),

    // 日历事件
    _EventOption('calendar_event_added', '日历', '添加事件'),
    _EventOption('calendar_event_deleted', '日历', '删除事件'),
  ];

  bool get isEditMode => widget.script != null;

  /// 根据图标名称获取 IconData
  IconData _getIconData(String iconName) {
    return _iconMap[iconName] ?? Icons.code;
  }

  /// 根据 IconData 获取图标名称
  String _getIconName(IconData icon) {
    return _iconNameMap[icon] ?? 'code';
  }

  @override
  void initState() {
    super.initState();

    // 初始化Tab控制器
    _tabController = TabController(length: 5, vsync: this);

    // 初始化代码控制器
    _codeController = TextEditingController();

    // 处理初始数据（导入模式）或编辑模式
    if (widget.initialData != null) {
      // 导入模式
      _localScriptPath = widget.initialData!['localScriptPath'] as String?;
      _codeController.text = widget.initialData!['code'] as String? ?? '';

      if (widget.initialData!['inputs'] != null) {
        _inputs =
            (widget.initialData!['inputs'] as List<dynamic>)
                .cast<ScriptInput>();
      }

      if (widget.initialData!['triggers'] != null) {
        _triggers =
            (widget.initialData!['triggers'] as List<dynamic>)
                .map((e) => ScriptTrigger.fromJson(e as Map<String, dynamic>))
                .toList();
      }

      if (widget.initialData!['config'] != null) {
        _currentConfig = widget.initialData!['config'] as Map<String, dynamic>;
      }

      // 解析 configFormFields
      if (widget.initialData!['configFormFields'] != null) {
        _configFormFields = _parseConfigFormFieldsFromJson(
          widget.initialData!['configFormFields'],
        );
      }
    } else if (widget.script != null) {
      // 编辑模式
      _inputs = List.from(widget.script!.inputs);
      _triggers = List.from(widget.script!.triggers);
      _autoRun = widget.script!.autoRun;
      _localScriptPath = widget.script!.localScriptPath;
      _configFormFields = widget.script!.configFormFields;

      // 异步加载代码
      _loadScriptCode();
      // 异步加载配置
      _loadScriptConfig();
    }

    // 强制构建所有tabs，确保表单wrapper被初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 遍历所有tabs，触发构建
      for (int i = 0; i < _tabController.length; i++) {
        _tabController.animateTo(i);
      }
      // 最后跳回第一个tab
      _tabController.animateTo(0);
    });
  }

  /// 加载脚本配置
  Future<void> _loadScriptConfig() async {
    if (widget.script == null) return;

    try {
      final configPath =
          'configs/scripts_center/${widget.script!.id}_config.json';
      final storageManager = widget.scriptManager.loader.storage;
      final data = await storageManager.read(configPath);
      if (data != null && mounted) {
        // 正确处理 Map 类型转换
        Map<String, dynamic> config;
        if (data is Map<String, dynamic>) {
          config = data;
        } else if (data is Map<dynamic, dynamic>) {
          // 转换键的类型
          config = data.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          );
        } else {
          // 如果数据格式不正确，返回默认配置
          config = {};
        }
        setState(() {
          _currentConfig = config;
        });
      }
    } catch (e) {
      debugPrint('Failed to load script config: $e');
    }
  }

  /// 加载脚本代码
  Future<void> _loadScriptCode() async {
    if (widget.script == null) return;

    try {
      final code = await widget.scriptManager.getScriptCode(widget.script!.id);
      if (code != null && mounted) {
        _codeController.text = code;
      }
    } catch (e) {
      // 加载失败，保持空代码
      debugPrint('Failed to load script code: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 存储基本信息表单的值（用于提交时合并）
  Map<String, dynamic>? _basicInfoValues;

  /// 验证并保存
  void _saveScript() {
    _basicInfoWrapperState?.submitForm();
  }

  /// 处理基本信息表单提交
  void _handleBasicInfoSubmit(Map<String, dynamic> values) {
    // 检查widget是否仍然mounted
    if (!mounted) return;

    // 保存基本信息表单的值
    _basicInfoValues = values;

    // 继续提交高级设置表单
    _advancedWrapperState?.submitForm();
  }

  /// 处理高级设置表单提交（最终提交）
  void _handleAdvancedSubmit(Map<String, dynamic> advancedValues) {
    // 检查widget是否仍然mounted
    if (!mounted) return;

    // 在保存前，获取配置表单的最新值
    if (_configWrapperState != null) {
      final configValues = _configWrapperState!.currentValues;
      if (configValues.isNotEmpty) {
        setState(() {
          _currentConfig = configValues;
        });
      }
    }

    // 获取保存的基本信息表单的值
    final basicValues = _basicInfoValues ?? {};

    // 验证必填字段
    final name = basicValues['name']?.toString().trim() ?? '';
    if (name.isEmpty && widget.initialData == null) {
      toastService.showToast('请输入脚本名称');
      return;
    }

    // 在新建模式下，id必填；如果没有填写，自动从name生成
    String id = basicValues['id']?.toString().trim() ?? '';
    if (id.isEmpty && !isEditMode) {
      // 使用拼音或简化名称生成id（这里简化为使用小写+下划线）
      id = name
          .toLowerCase()
          .replaceAll(RegExp(r'[\s\u4e00-\u9fa5]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      if (id.isEmpty) {
        id = 'script_${DateTime.now().millisecondsSinceEpoch}';
      }
      toastService.showToast('已自动生成脚本ID: $id');
    }

    // 从 icon 字段中提取图标名称（circleIconPicker 返回 Map）
    String iconValue = 'code';
    if (basicValues['icon'] != null) {
      if (basicValues['icon'] is Map) {
        final iconMap = basicValues['icon'] as Map;
        final iconData = iconMap['icon'] as IconData?;
        iconValue = iconData != null ? _getIconName(iconData) : 'code';
      } else if (basicValues['icon'] is String) {
        iconValue = basicValues['icon'] as String;
      }
    }

    // 合并两个表单的数据
    final scriptData = {
      'name': name,
      'id': id,
      'description': basicValues['description']?.toString().trim() ?? '',
      'author': basicValues['author']?.toString().trim() ?? '',
      'version': basicValues['version']?.toString().trim() ?? '1.0.0',
      'icon': iconValue,
      'type': advancedValues['type']?.toString() ?? 'module',
      'enabled': advancedValues['enabled'] as bool? ?? true,
      'autoRun': _autoRun,
      'code': _codeController.text,
      'inputs': _inputs,
      'triggers': _triggers.map((t) => t.toJson()).toList(),
      'updateUrl':
          advancedValues['updateUrl']?.toString().trim().isEmpty == true
              ? null
              : advancedValues['updateUrl']?.toString().trim(),
      'localScriptPath': _localScriptPath,
    };

    // 保存配置（如果有）
    if (_currentConfig != null && _currentConfig!.isNotEmpty) {
      scriptData['config'] = _currentConfig;
    }

    // 保存配置表单字段定义（如果有）
    if (_configFormFields.isNotEmpty) {
      scriptData['configFormFields'] = _configFormFields;
    }

    // 再次检查mounted，因为这是在异步回调中
    if (mounted) {
      Navigator.of(context).pop(scriptData);
    }
  }

  /// 添加输入参数
  Future<void> _addInput() async {
    final input = await showDialog<ScriptInput>(
      context: context,
      builder: (context) => const ScriptInputEditDialog(),
    );

    if (input != null) {
      setState(() {
        _inputs.add(input);
      });
    }
  }

  /// 编辑输入参数
  Future<void> _editInput(int index) async {
    final input = await showDialog<ScriptInput>(
      context: context,
      builder: (context) => ScriptInputEditDialog(input: _inputs[index]),
    );

    if (input != null) {
      setState(() {
        _inputs[index] = input;
      });
    }
  }

  /// 删除输入参数
  void _deleteInput(int index) {
    setState(() {
      _inputs.removeAt(index);
    });
  }

  /// 根据输入类型获取对应图标
  IconData _getInputTypeIcon(String type) {
    switch (type) {
      case 'string':
        return Icons.text_fields;
      case 'number':
        return Icons.numbers;
      case 'boolean':
        return Icons.toggle_on;
      case 'select':
        return Icons.list;
      default:
        return Icons.input;
    }
  }

  /// 选择本地脚本文件
  Future<void> _pickLocalScriptFile() async {
    final files = await FilePickerHelper.pickFiles(multiple: false);
    if (files.isNotEmpty) {
      final file = files.first;
      setState(() {
        _localScriptPath = file.path;
      });

      // 自动加载文件内容
      try {
        final content = await file.readAsString();
        _codeController.text = content;
        toastService.showToast('已加载文件内容');
      } catch (e) {
        toastService.showToast('加载文件失败: $e');
      }
    }
  }

  /// 清除本地文件路径
  void _clearLocalScriptPath() {
    setState(() {
      _localScriptPath = null;
    });
  }

  /// 获取基本信息表单字段配置
  List<FormFieldConfig> _getBasicInfoFields() {
    final script = widget.script;
    final initialData = widget.initialData;

    // 优先使用initialData中的值，其次使用script中的值
    final iconName = initialData?['icon'] as String? ?? script?.icon ?? 'code';
    final iconData = _getIconData(iconName);

    return [
      // 图标选择 - 使用 circleIconPicker
      FormFieldConfig(
        name: 'icon',
        type: FormFieldType.circleIconPicker,
        labelText: 'scripts_center_icon'.tr,
        initialValue: {'icon': iconData, 'color': Colors.deepPurple},
        extra: {
          'initialBackgroundColor': Colors.deepPurple,
          'showLabel': true,
          'labelText': 'scripts_center_selectIcon'.tr,
        },
      ),

      // 脚本名称
      FormFieldConfig(
        name: 'name',
        type: FormFieldType.text,
        labelText: 'scripts_center_scriptName'.tr,
        hintText: '例如：自动备份助手',
        prefixIcon: Icons.title,
        initialValue: initialData?['name'] as String? ?? script?.name ?? '',
        required: true,
        validationMessage: '请输入脚本名称',
      ),

      // 脚本ID
      FormFieldConfig(
        name: 'id',
        type: FormFieldType.text,
        labelText: 'scripts_center_scriptId'.tr,
        hintText: '例如：auto_backup',
        prefixIcon: Icons.fingerprint,
        initialValue: initialData?['id'] as String? ?? script?.id ?? '',
        required: true,
        enabled: !isEditMode, // 编辑模式下不可修改
        validationMessage: '请输入脚本ID',
        extra: {
          'inputFormatters': [RegExp(r'^[a-z0-9_]+$')],
        },
      ),

      // 描述
      FormFieldConfig(
        name: 'description',
        type: FormFieldType.textArea,
        labelText: 'scripts_center_description'.tr,
        hintText: '简短描述脚本的功能',
        prefixIcon: Icons.description,
        initialValue:
            initialData?['description'] as String? ?? script?.description ?? '',
        extra: {'maxLines': 3},
      ),

      // 作者
      FormFieldConfig(
        name: 'author',
        type: FormFieldType.text,
        labelText: 'scripts_center_author'.tr,
        hintText: '例如：张三',
        prefixIcon: Icons.person,
        initialValue: initialData?['author'] as String? ?? script?.author ?? '',
      ),

      // 版本号
      FormFieldConfig(
        name: 'version',
        type: FormFieldType.text,
        labelText: 'scripts_center_version'.tr,
        hintText: '例如：1.0.0',
        prefixIcon: Icons.tag,
        initialValue:
            initialData?['version'] as String? ?? script?.version ?? '1.0.0',
        required: true,
        validationMessage: '请输入版本号',
      ),
    ];
  }

  /// 获取高级设置表单字段配置
  List<FormFieldConfig> _getAdvancedFields() {
    final script = widget.script;
    return [
      // 脚本类型
      FormFieldConfig(
        name: 'type',
        type: FormFieldType.select,
        labelText: 'scripts_center_scriptType'.tr,
        prefixIcon: Icons.category,
        initialValue: script?.type ?? 'module',
        required: true,
        items: [
          DropdownMenuItem(
            value: 'module',
            child: Text('scripts_center_moduleType'.tr),
          ),
          DropdownMenuItem(
            value: 'standalone',
            child: Text('scripts_center_standaloneType'.tr),
          ),
        ],
      ),

      // 更新地址
      FormFieldConfig(
        name: 'updateUrl',
        type: FormFieldType.text,
        labelText: 'scripts_center_updateUrl'.tr,
        hintText: '例如：https://example.com/script.js',
        prefixIcon: Icons.cloud_download,
        initialValue: script?.updateUrl ?? '',
      ),

      // 启用开关
      FormFieldConfig(
        name: 'enabled',
        type: FormFieldType.switchField,
        labelText: 'scripts_center_enableScript'.tr,
        hintText: script?.enabled == true ? '脚本将在触发条件满足时执行' : '脚本已禁用，不会执行',
        prefixIcon: script?.enabled == true ? Icons.check_circle : Icons.cancel,
        initialValue: script?.enabled ?? true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode
              ? 'scripts_center_editScript'.tr
              : 'scripts_center_createNewScript'.tr,
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saveScript,
            icon: Icon(
              isEditMode ? Icons.save : Icons.add,
              color: Colors.white,
            ),
            label: Text(
              isEditMode
                  ? 'scripts_center_save'.tr
                  : 'scripts_center_create'.tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.info_outline),
              text: 'scripts_center_basicInfo'.tr,
            ),
            Tab(
              icon: const Icon(Icons.code),
              text: 'scripts_center_codeEditor'.tr,
            ),
            Tab(
              icon: const Icon(Icons.bolt),
              text: 'scripts_center_triggers'.tr,
            ),
            Tab(
              icon: const Icon(Icons.settings_outlined),
              text: 'scripts_center_advancedSettings'.tr,
            ),
            Tab(
              icon: const Icon(Icons.tune_outlined),
              text: 'scripts_center_config'.tr,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _KeepAliveTab(child: _buildBasicInfoTab()),
          _KeepAliveTab(child: _buildCodeEditorTab()),
          _KeepAliveTab(child: _buildTriggersTab()),
          _KeepAliveTab(child: _buildAdvancedTab()),
          _KeepAliveTab(child: _buildConfigTab()),
        ],
      ),
    );
  }

  /// 构建基本信息标签页
  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FormBuilderWrapper(
        formKey: _basicInfoFormKey,
        onStateReady: (state) => _basicInfoWrapperState = state,
        config: FormConfig(
          fields: _getBasicInfoFields(),
          showSubmitButton: false,
          showResetButton: false,
          fieldSpacing: 16,
          onSubmit: _handleBasicInfoSubmit,
        ),
      ),
    );
  }

  /// 构建代码编辑器标签页
  Widget _buildCodeEditorTab() {
    return Column(
      children: [
        // 工具栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            children: [
              const Icon(Icons.code, size: 20, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Text(
                'JavaScript 代码',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // TODO: 添加代码格式化功能
                  toastService.showToast('代码格式化功能即将推出');
                },
                icon: const Icon(Icons.format_align_left, size: 18),
                label: Text('scripts_center_format'.tr),
              ),
            ],
          ),
        ),
        // 代码编辑器
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _codeController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              decoration: const InputDecoration(
                hintText:
                    '// 在此输入 JavaScript 代码\n'
                    '// 例如：\n'
                    '// function execute(context, args) {\n'
                    '//   console.log("Hello from script!");\n'
                    '//   return { success: true };\n'
                    '// }',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ),
        // 本地文件路径选择
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.link, size: 18, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text(
                    '本地文件链接',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (_localScriptPath != null)
                    TextButton.icon(
                      onPressed: _clearLocalScriptPath,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('清除'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  TextButton.icon(
                    onPressed: _pickLocalScriptFile,
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: const Text('选择文件'),
                  ),
                ],
              ),
              if (_localScriptPath != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file,
                        size: 16,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _localScriptPath!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '初始化时将从此文件同步最新代码',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
        // 提示信息
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '脚本将在满足触发条件时执行。可以访问 context 对象获取应用上下文。',
                  style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建触发条件标签页
  Widget _buildTriggersTab() {
    return Column(
      children: [
        // 自动运行开关
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              const Icon(Icons.autorenew, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '自动运行',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      '开启后将在插件初始化时自动执行此脚本',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoRun,
                onChanged: (value) {
                  setState(() {
                    _autoRun = value;
                  });
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // 自动运行开启时隐藏触发条件选项
        if (!_autoRun) ...[
          // 添加触发器按钮
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  '触发条件',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddTriggerDialog,
                  icon: const Icon(Icons.add),
                  label: Text('scripts_center_addTrigger'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 触发器列表
          Expanded(
            child:
                _triggers.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无触发条件',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '点击上方按钮添加触发条件',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _triggers.length,
                      itemBuilder: (context, index) {
                        final trigger = _triggers[index];
                        final eventOption = _availableEvents.firstWhere(
                          (e) => e.eventName == trigger.event,
                          orElse:
                              () => _EventOption(
                                trigger.event,
                                '未知',
                                trigger.event,
                              ),
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(eventOption.eventName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'scripts_center_categoryLabel'.trParams({
                                    'category': eventOption.category,
                                  }),
                                ),
                                Text(
                                  'scripts_center_descriptionLabel'.trParams({
                                    'description': eventOption.description,
                                  }),
                                ),
                                if (trigger.delay != null && trigger.delay! > 0)
                                  Text(
                                    'scripts_center_delayLabel'.trParams({
                                      'delay': trigger.delay!.toString(),
                                    }),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _triggers.removeAt(index);
                                });
                              },
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
          ),
        ] else
          // 自动运行开启时的提示信息
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.autorenew, size: 64, color: Colors.blue[400]),
                  const SizedBox(height: 16),
                  Text(
                    '已启用自动运行',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '此脚本将在插件初始化时自动执行',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// 构建高级设置标签页
  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 使用 FormBuilderWrapper 构建高级设置表单
          FormBuilderWrapper(
            formKey: _advancedFormKey,
            onStateReady: (state) => _advancedWrapperState = state,
            config: FormConfig(
              fields: _getAdvancedFields(),
              showSubmitButton: false,
              showResetButton: false,
              fieldSpacing: 24,
              onSubmit: _handleAdvancedSubmit,
            ),
          ),

          const SizedBox(height: 24),

          // 输入参数设置（保留原有逻辑）
          _buildInputsSection(),
        ],
      ),
    );
  }

  /// 构建输入参数部分
  Widget _buildInputsSection() {
    final scriptType =
        _advancedFormKey.currentState?.value['type'] ??
        widget.script?.type ??
        'module';

    if (scriptType != 'module') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.input_outlined,
              size: 20,
              color: Colors.deepPurple,
            ),
            const SizedBox(width: 8),
            const Text(
              '输入参数',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 参数列表
        if (_inputs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  '暂无输入参数',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '为 Module 类型脚本添加输入参数，执行时会显示表单收集用户输入',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._inputs.asMap().entries.map((entry) {
            final index = entry.key;
            final input = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                  child: Icon(
                    _getInputTypeIcon(input.type),
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      input.label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${input.key})',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (input.required) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '必填',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  input.description ?? '类型: ${input.type}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editInput(index),
                      tooltip: '编辑',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.red,
                      onPressed: () => _deleteInput(index),
                      tooltip: '删除',
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 12),

        // 添加参数按钮
        OutlinedButton.icon(
          onPressed: _addInput,
          icon: const Icon(Icons.add),
          label: Text('scripts_center_addInputParameter'.tr),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.deepPurple,
            side: const BorderSide(color: Colors.deepPurple),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// 显示添加触发器对话框
  Future<void> _showAddTriggerDialog() async {
    // 初始化：从当前触发器中提取已有的事件
    List<String> selectedEvents = _triggers.map((t) => t.event).toList();

    // 获取第一个触发器的延迟作为默认值（如果有）
    int delay = _triggers.isNotEmpty && _triggers.first.delay != null
        ? _triggers.first.delay!
        : 0;
    final delayController = TextEditingController(text: delay.toString());

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text('scripts_center_addTriggerCondition'.tr),
                  content: SizedBox(
                    width: 500,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 事件选择
                        const Text(
                          '选择事件 *',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final events = await showDialog<List<String>>(
                              context: context,
                              builder:
                                  (context) => EventSelectorDialog(
                                    availableEvents:
                                        _availableEvents
                                            .map(
                                              (e) => EventOption(
                                                eventName: e.eventName,
                                                category: e.category,
                                                description: e.description,
                                              ),
                                            )
                                            .toList(),
                                    initialSelectedEvents: selectedEvents,
                                    dialogTitle: '选择事件',
                                  ),
                            );
                            if (events != null) {
                              setDialogState(() {
                                selectedEvents = events;
                              });
                            }
                          },
                          icon: const Icon(Icons.event),
                          label: Text(
                            selectedEvents.isEmpty
                                ? '请选择事件（可多选）'
                                : '已选择 ${selectedEvents.length} 个事件',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 延迟设置
                        TextField(
                          controller: delayController,
                          decoration: const InputDecoration(
                            labelText: '延迟（毫秒）',
                            hintText: '0',
                            helperText: '触发后延迟多久执行脚本',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            delay = int.tryParse(value) ?? 0;
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('scripts_center_cancel'.tr),
                    ),
                    ElevatedButton(
                      onPressed:
                          selectedEvents.isEmpty
                              ? null
                              : () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('scripts_center_add'.tr),
                    ),
                  ],
                ),
          ),
    );

    if (result == true && selectedEvents.isNotEmpty) {
      setState(() {
        // 清空原有触发器，替换为新选择的触发器
        _triggers.clear();
        for (final event in selectedEvents) {
          _triggers.add(
            ScriptTrigger(event: event, delay: delay > 0 ? delay : null),
          );
        }
      });
    }

    delayController.dispose();
  }

  /// 构建配置标签页
  Widget _buildConfigTab() {
    // 优先使用导入的configFormFields，其次使用script的configFormFields
    final configFormFields =
        _configFormFields.isNotEmpty
            ? _configFormFields
            : widget.script?.configFormFields ?? [];

    final hasConfigFormFields = configFormFields.isNotEmpty;

    if (hasConfigFormFields) {
      // 使用 FormBuilderWrapper 动态渲染配置表单
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FormBuilderWrapper(
          formKey: _configFormKey,
          onStateReady: (state) => _configWrapperState = state,
          config: FormConfig(
            fields: _getConfigFormFields(),
            showSubmitButton: false,
            showResetButton: false,
            fieldSpacing: 16,
            onSubmit: _handleConfigSubmit,
          ),
        ),
      );
    }

    // 没有配置表单字段定义时显示说明界面
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '该脚本无需配置',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '此脚本没有定义配置选项，可以直接使用',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// 获取配置表单字段
  List<FormFieldConfig> _getConfigFormFields() {
    // 优先使用导入的configFormFields，其次使用script的configFormFields
    final fields =
        _configFormFields.isNotEmpty
            ? _configFormFields
            : widget.script?.configFormFields ?? [];

    // 为需要可用事件列表的字段添加 extra 数据
    return fields.map((field) {
      if (field.type == FormFieldType.eventMultiSelect) {
        // 添加可用事件列表到 extra
        final availableEvents =
            _availableEvents
                .map(
                  (e) => {
                    'eventName': e.eventName,
                    'category': e.category,
                    'description': e.description,
                  },
                )
                .toList();

        return FormFieldConfig(
          name: field.name,
          type: field.type,
          labelText: field.labelText,
          hintText: field.hintText,
          initialValue: _currentConfig?[field.name],
          required: field.required,
          validationMessage: field.validationMessage,
          enabled: field.enabled,
          prefixIcon: field.prefixIcon,
          extra: {'eventMultiSelect': true, 'availableEvents': availableEvents},
        );
      }

      // 设置初始值
      return FormFieldConfig(
        name: field.name,
        type: field.type,
        labelText: field.labelText,
        hintText: field.hintText,
        initialValue: _currentConfig?[field.name] ?? field.initialValue,
        required: field.required,
        validationMessage: field.validationMessage,
        enabled: field.enabled,
        prefixIcon: field.prefixIcon,
        extra: field.extra,
      );
    }).toList();
  }

  /// 处理配置表单提交
  void _handleConfigSubmit(Map<String, dynamic> values) {
    setState(() {
      _currentConfig = values;
    });
  }

  /// 从JSON解析配置表单字段
  List<FormFieldConfig> _parseConfigFormFieldsFromJson(dynamic jsonList) {
    if (jsonList == null) return [];

    if (jsonList is! List) return [];

    return jsonList.map<FormFieldConfig>((item) {
      final json = item as Map<String, dynamic>;
      final typeName = json['type'] as String?;

      // 构建 extra 字段，处理 pluginDataSelector 和 eventMultiSelect
      Map<String, dynamic>? extra;
      if (typeName == 'pluginDataSelector') {
        final pluginDataType = json['pluginDataType'] as String?;
        final fieldMapping = json['fieldMapping'] as Map<String, dynamic>?;
        if (pluginDataType != null || fieldMapping != null) {
          extra = <String, dynamic>{};
          if (pluginDataType != null) {
            extra['pluginDataType'] = pluginDataType;
          }
          if (fieldMapping != null && fieldMapping.isNotEmpty) {
            extra['fieldMapping'] = fieldMapping;
          }
        }
      } else if (typeName == 'eventMultiSelect') {
        extra = {'eventMultiSelect': true};
      } else {
        extra = json['extra'] as Map<String, dynamic>?;
      }

      // 解析基础字段
      return FormFieldConfig(
        name: json['name'] as String,
        type: FormFieldType.values.firstWhere(
          (e) => e.name == typeName,
          orElse: () => FormFieldType.text,
        ),
        labelText: json['labelText'] as String?,
        hintText: json['hintText'] as String?,
        initialValue: json['initialValue'],
        required: json['required'] as bool? ?? false,
        validationMessage: json['validationMessage'] as String?,
        enabled: json['enabled'] as bool? ?? true,
        prefixIcon: _parseIconData(json['prefixIcon'] as String?),
        extra: extra,
      );
    }).toList();
  }

  /// 解析图标名称为IconData
  IconData? _parseIconData(String? iconName) {
    if (iconName == null) return null;
    return _iconMap[iconName];
  }
}

/// 保持Tab存活的Wrapper
class _KeepAliveTab extends StatefulWidget {
  final Widget child;

  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用
    return widget.child;
  }
}
