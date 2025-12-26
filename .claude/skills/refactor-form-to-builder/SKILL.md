---
name: refactor-form-to-builder
description: 将传统表单页面重构为使用 FormBuilderWrapper 的声明式表单。自动检测表单字段，检查是否有对应的封装 field 组件，如果没有则先创建 field 包装器，然后将表单转换为 FormFieldConfig 列表形式，减少重复代码
---

# Refactor Form to FormBuilderWrapper

将传统表单页面重构为使用 `FormBuilderWrapper` 的声明式表单系统，减少重复代码并提高可维护性。

## ⚠️ 重要：提交按钮的最佳实践

**强烈建议将提交按钮放在 `FormBuilderWrapper` 内部**，使用 `buttonBuilder` 或直接设置 `showSubmitButton: true`。

如果因为 UI 需求必须将按钮放在外部（如 AppBar），**必须**按以下方式操作：

```dart
// ✅ 正确做法
class MyFormScreen extends StatefulWidget {
  @override
  State<MyFormScreen> createState() => _MyFormScreenState();
}

class _MyFormScreenState extends State<MyFormScreen> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  FormBuilderWrapperState? _wrapperState;  // 关键：存储 wrapper 状态

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: _handleSave,  // 使用这个方法
            child: Text('保存'),
          ),
        ],
      ),
      body: FormBuilderWrapper(
        formKey: _formKey,
        onStateReady: (state) => _wrapperState = state,  // 关键：获取状态
        config: FormConfig(
          fields: [...],
          onSubmit: _handleSubmit,  // 表单值在这里处理
        ),
      ),
    );
  }

  void _handleSave() {
    // 验证逻辑...
    // 使用 wrapperState 提交表单
    _wrapperState?.submitForm();  // 关键：调用 submitForm
  }

  void _handleSubmit(Map<String, dynamic> values) {
    // 处理表单数据
  }
}
```

```dart
// ❌ 错误做法：直接使用 _formKey.currentState?.value
void _handleSave() {
  final values = _formKey.currentState?.value ?? {};  // WrappedFormField 值不会被收集！
  _handleSubmit(values);
}
```

## Usage

```bash
# 基础用法 - 自动检测表单并转换
/refactor-form-to-builder <form-file>

# 指定表单所在的 widget 方法
/refactor-form-to-builder <form-file> --method _buildFormSection

# 只检测不修改（预览模式）
/refactor-form-to-builder <form-file> --dry-run
```

**Examples:**

```bash
# 重构用户设置表单
/refactor-form-to-builder lib/screens/settings/settings_screen.dart

# 重构插件配置表单
/refactor-form-to-builder lib/plugins/goods/views/goods_edit_view.dart --method _buildConfigForm

# 预览将要做的修改
/refactor-form-to-builder lib/screens/profile/edit_profile_screen.dart --dry-run
```

## Arguments

- `<form-file>`: 目标表单文件路径
- `--method <name>`: 表单所在的构建方法名（默认：自动检测 `build` 或 `_buildForm` 方法）
- `--dry-run`: 只分析不修改，显示预览

## Workflow

### 1. Analyze Target File

读取目标文件并识别：

- **表单结构**: StatefulWidget/FormBuilder
- **字段类型**: TextField, DropdownButton, Checkbox, Switch 等
- **状态变量**: `_controller`, `_value`, `_selectedXxx`
- **验证逻辑**: validator 函数
- **提交逻辑**: onPressed/onSubmitted 回调

### 2. Detect Form Fields

识别常见表单字段的模式：

#### 文本输入类

```dart
// 检测模式：
TextField(
  controller: _nameController,
  decoration: InputDecoration(labelText: '名称'),
)

TextFormField(
  controller: _emailController,
  validator: (value) => value?.isEmpty ? '必填' : null,
)
```

→ 转换为 `FormFieldType.text`

#### 选择器类

```dart
// 检测模式：
DropdownButton<String>(
  value: _selectedType,
  items: [DropdownMenuItem(...)],
  onChanged: (value) => setState(() => _selectedType = value),
)

showDatePicker(context: context, ...)
```

→ 转换为 `FormFieldType.select` 或 `FormFieldType.date`

#### 开关/滑块类

```dart
// 检测模式：
Switch(
  value: _isEnabled,
  onChanged: (value) => setState(() => _isEnabled = value),
)

Slider(
  value: _sliderValue,
  onChanged: (value) => setState(() => _sliderValue = value),
)
```

→ 转换为 `FormFieldType.switchField` 或 `FormFieldType.slider`

#### Picker 选择器类

```dart
// 检测模式：
showDialog(
  context: context,
  builder: (_) => IconPickerDialog(...),
)

showDialog(
  context: context,
  builder: (_) => ImagePickerDialog(...),
)

LocationPicker(...)
AvatarPicker(...)
```

→ 检测是否有对应的 field 文件，如果没有则创建

### 3. Check/Create Field Wrappers

对于每个检测到的 picker 类型，检查是否已有对应的 field 文件：

```dart
// 检查文件是否存在：
lib/widgets/form_fields/<type>_field.dart
```

**如果不存在**，创建 field 包装器：

```dart
// lib/widgets/form_fields/my_picker_field.dart
import 'package:flutter/material.dart';
import '../picker/my_picker_dialog.dart';

class MyPickerField extends StatelessWidget {
  final dynamic currentValue;
  final String? labelText;
  final bool enabled;
  final ValueChanged<dynamic> onValueChanged;

  const MyPickerField({
    super.key,
    required this.currentValue,
    required this.onValueChanged,
    this.labelText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () async {
        final result = await showDialog<dynamic>(
          context: context,
          builder: (context) => MyPickerDialog(
            initialValue: currentValue,
          ),
        );
        if (result != null) {
          onValueChanged(result);
        }
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.my_icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getDisplayText(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (enabled) const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (currentValue != null) {
      return currentValue.toString();
    }
    return labelText ?? '选择';
  }
}
```

然后：
1. 在 `index.dart` 中添加导出
2. 在 `form_builder_wrapper.dart` 的 `FormFieldType` 枚举中添加类型
3. 在 `form_builder_wrapper.dart` 的 `_buildField` 方法中添加 case
4. 在 `form_builder_wrapper.dart` 中添加 `_buildXxxField` 方法

### 4. Extract Form Configuration

将检测到的字段转换为 `FormFieldConfig` 列表：

```dart
// 原始代码：
TextField(
  controller: _nameController,
  decoration: InputDecoration(labelText: '名称'),
  prefixIcon: Icon(Icons.person),
)

// 转换为：
FormFieldConfig(
  name: 'name',
  type: FormFieldType.text,
  labelText: '名称',
  prefixIcon: Icons.person,
  initialValue: _nameController.text,
)
```

### 5. Create FormBuilderWrapper

用 `FormBuilderWrapper` 替换原表单：

```dart
// 原始表单：
Column(
  children: [
    TextField(controller: _nameController, ...),
    TextField(controller: _emailController, ...),
    DropdownButton(...),
    Switch(...),
    ElevatedButton(
      onPressed: _submit,
      child: Text('提交'),
    ),
  ],
)

// 转换为：
FormBuilderWrapper(
  config: FormConfig(
    fields: [
      FormFieldConfig(name: 'name', type: FormFieldType.text, ...),
      FormFieldConfig(name: 'email', type: FormFieldType.email, ...),
      FormFieldConfig(name: 'type', type: FormFieldType.select, ...),
      FormFieldConfig(name: 'enabled', type: FormFieldType.switchField, ...),
    ],
    submitButtonText: '提交',
    showResetButton: true,
    onSubmit: (values) => _handleSubmit(values),
  ),
)
```

### 6. Update Submit Handler

修改提交处理函数：

```dart
// 原始代码：
void _submit() {
  final name = _nameController.text;
  final email = _emailController.text;
  final type = _selectedType;
  final enabled = _isEnabled;

  _saveData(name: name, email: email, type: type, enabled: enabled);
}

// 转换为：
void _handleSubmit(Map<String, dynamic> values) {
  final name = values['name'] as String;
  final email = values['email'] as String;
  final type = values['type'] as String;
  final enabled = values['enabled'] as bool;

  _saveData(name: name, email: email, type: type, enabled: enabled);
}
```

### 7. Remove Old State Variables

删除不再需要的状态变量和控制器：

```dart
// 删除这些：
TextEditingController _nameController = TextEditingController();
TextEditingController _emailController = TextEditingController();
String? _selectedType;
bool _isEnabled = true;

// 在 dispose 中删除：
_nameController.dispose();
_emailController.dispose();
```

## FormFieldType Mapping

| 原始组件 | FormFieldType | 配置示例 |
|---------|--------------|---------|
| `TextField` | `text` | 基础文本输入 |
| `TextFormField` | `text` | 带验证的文本 |
| `TextField(obscureText: true)` | `password` | 密码输入 |
| `TextField(keyboardType: email)` | `email` | 邮箱输入 |
| `TextField(keyboardType: number)` | `number` | 数字输入 |
| `TextField(maxLines: >1)` | `textArea` | 多行文本 |
| `DropdownButton` | `select` | 下拉选择 |
| `showDatePicker` | `date` | 日期选择 |
| `showTimePicker` | `time` | 时间选择 |
| `Switch` | `switchField` | 开关 |
| `Slider` | `slider` | 滑块 |
| `Checkbox` | 可用 `switchField` 或自定义 | 复选框 |
| `IconPickerDialog` | `iconPicker` | 图标选择器 |
| `AvatarPicker` | `avatarPicker` | 头像选择器 |
| `CircleIconPicker` | `circleIconPicker` | 圆形图标选择器 |
| `CalendarStripDatePicker` | `calendarStripPicker` | 日历条选择器 |
| `ImagePickerDialog` | `imagePicker` | 图片选择器 |
| `LocationPicker` | `locationPicker` | 位置选择器 |
| `ColorPickerSection` | `color` | 颜色选择器 |
| `PromptEditor` | `promptEditor` | 提示词编辑器（复合字段）|
| `IconAvatarRow` | `iconAvatarRow` | 图标头像并排（复合字段）|

## 高级功能

### 1. 条件显示字段

使用 `visible` 参数根据其他字段的值动态显示/隐藏字段：

```dart
// 开场白问题列表只在启用时显示
FormFieldConfig(
  name: 'openingQuestions',
  type: FormFieldType.listAdd,
  initialValue: [],
  visible: (values) => values['enableOpeningQuestions'] == true,
),

// 高级选项只在选中"自定义"时显示
FormFieldConfig(
  name: 'customConfig',
  type: FormFieldType.textArea,
  visible: (values) => values['mode'] == 'custom',
),
```

### 2. 输入框组按钮

使用 `prefixButtons` 和 `suffixButtons` 在文本输入框前后添加操作按钮：

```dart
FormFieldConfig(
  name: 'model',
  type: FormFieldType.text,
  labelText: '模型',
  hintText: '输入或选择模型',
  suffixButtons: [
    InputGroupButton(
      icon: Icons.search,
      tooltip: '搜索模型',
      onPressed: () {
        // 打开模型选择对话框
        _selectModel();
      },
    ),
  ],
),

// 带前后缀按钮的输入框
FormFieldConfig(
  name: 'apiKey',
  type: FormFieldType.text,
  prefixButtons: [
    InputGroupButton(
      icon: Icons.key,
      tooltip: '生成密钥',
      onPressed: () => _generateApiKey(),
    ),
  ],
  suffixButtons: [
    InputGroupButton(
      icon: Icons.visibility,
      tooltip: '显示/隐藏',
      onPressed: () => _toggleVisibility(),
    ),
  ],
),
```

### 3. 字段联动与回调

使用 `onChanged` 回调实现字段间的联动：

```dart
// 服务商选择后自动更新配置
FormFieldConfig(
  name: 'serviceProvider',
  type: FormFieldType.select,
  labelText: '服务商',
  items: _providers.map((p) => DropdownMenuItem(
    value: p.id,
    child: Text(p.label),
  )).toList(),
  onChanged: (value) {
    // 服务商切换时，自动更新相关字段
    if (value != null) {
      final provider = _providers.firstWhere((p) => p.id == value);
      _updateProviderFields(provider);
    }
  },
),

// 数量变化时重新计算价格
FormFieldConfig(
  name: 'quantity',
  type: FormFieldType.number,
  labelText: '数量',
  onChanged: (value) {
    // 数量变化时自动更新价格
    _updatePrice();
  },
),
```

### 4. 完整的联动表单示例

```dart
FormBuilderWrapper(
  config: FormConfig(
    fields: [
      // 启用开场白问题开关
      FormFieldConfig(
        name: 'enableOpeningQuestions',
        type: FormFieldType.switchField,
        labelText: '启用开场白问题',
        initialValue: false,
      ),

      // 开场白问题列表 - 条件显示
      FormFieldConfig(
        name: 'openingQuestions',
        type: FormFieldType.listAdd,
        initialValue: [],
        visible: (values) => values['enableOpeningQuestions'] == true,
      ),

      // 服务商选择 - 联动更新配置
      FormFieldConfig(
        name: 'serviceProvider',
        type: FormFieldType.select,
        labelText: '服务商',
        initialValue: _providers.first.id,
        items: _providers.map((p) => DropdownMenuItem(
          value: p.id,
          child: Text(p.label),
        )).toList(),
        onChanged: (value) {
          if (value != null) {
            final provider = _providers.firstWhere((p) => p.id == value);
            // 自动更新 BaseUrl 和 Headers
            _formKey.currentState?.patchValue({
              'baseUrl': provider.baseUrl,
              'headers': _formatHeaders(provider.headers),
            });
          }
        },
      ),

      // 模型选择 - 带搜索按钮
      FormFieldConfig(
        name: 'model',
        type: FormFieldType.text,
        labelText: '模型',
        suffixButtons: [
          InputGroupButton(
            icon: Icons.search,
            tooltip: '搜索模型',
            onPressed: () => _selectModel(),
          ),
        ],
      ),
    ],
    onSubmit: (values) {
      // values 包含所有字段的最新值
      _saveAgent(values);
    },
  ),
)
```

### 5. InputGroupButton 类型定义

```dart
class InputGroupButton {
  /// 按钮图标
  final IconData icon;

  /// 按钮提示文本
  final String? tooltip;

  /// 点击回调
  final VoidCallback onPressed;

  const InputGroupButton({
    required this.icon,
    this.tooltip,
    required this.onPressed,
  });
}
```

## Extra Parameters Guide

对于 picker 类型字段，使用 `extra` 参数传递配置：

```dart
FormFieldConfig(
  name: 'avatar',
  type: FormFieldType.avatarPicker,
  extra: {
    'username': 'User',           // 用户名
    'size': 80.0,                 // 头像大小
    'saveDirectory': 'avatars',   // 保存目录
  },
),

FormFieldConfig(
  name: 'image',
  type: FormFieldType.imagePicker,
  extra: {
    'enableCrop': true,           // 启用裁剪
    'cropAspectRatio': 1.0,       // 裁剪比例
    'multiple': true,             // 多选
    'enableCompression': false,   // 启用压缩
    'saveDirectory': 'images',    // 保存目录
  },
),

FormFieldConfig(
  name: 'date',
  type: FormFieldType.calendarStripPicker,
  extra: {
    'allowFutureDates': false,    // 是否允许未来日期
    'useShortWeekDay': true,      // 使用短周名
  },
),
```

## Detection Patterns

### TextField

查找模式：
```dart
TextField(
  controller: _xxxController,
  decoration: InputDecoration(
    labelText: 'xxx',
    hintText: 'xxx',
    prefixIcon: Icon(xxx),
  ),
)
```

### DropdownButton

查找模式：
```dart
DropdownButton<T>(
  value: _selectedXxx,
  items: [
    DropdownMenuItem(value: x1, child: Text('x1')),
    DropdownMenuItem(value: x2, child: Text('x2')),
  ],
  onChanged: (value) => setState(() => _selectedXxx = value),
)
```

### Switch

查找模式：
```dart
Switch(
  value: _xxxEnabled,
  onChanged: (value) => setState(() => _xxxEnabled = value),
)
```

### Slider

查找模式：
```dart
Slider(
  value: _xxxValue,
  min: 0,
  max: 100,
  divisions: 10,
  onChanged: (value) => setState(() => _xxxValue = value),
)
```

### Picker Dialogs

查找模式：
```dart
showDialog(
  context: context,
  builder: (_) => XxxPickerDialog(
    currentValue: _currentValue,
    onChanged: (value) => setState(() => _currentValue = value),
  ),
)
```

## Example: Complete Conversion

### Before (Traditional Form)

```dart
class EditUserScreen extends StatefulWidget {
  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedRole;
  bool _isActive = true;
  IconData? _selectedIcon;
  String? _avatarPath;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('姓名不能为空')),
      );
      return;
    }

    final user = User(
      name: _nameController.text,
      email: _emailController.text,
      role: _selectedRole ?? 'user',
      isActive: _isActive,
      icon: _selectedIcon,
      avatar: _avatarPath,
    );

    Navigator.pop(context, user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('编辑用户')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '姓名',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '邮箱',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16),
            DropdownButton<String>(
              value: _selectedRole,
              hint: Text('选择角色'),
              items: [
                DropdownMenuItem(value: 'admin', child: Text('管理员')),
                DropdownMenuItem(value: 'user', child: Text('用户')),
                DropdownMenuItem(value: 'guest', child: Text('访客')),
              ],
              onChanged: (value) => setState(() => _selectedRole = value),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('启用状态'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('图标'),
              trailing: Icon(_selectedIcon ?? Icons.help),
              onTap: () async {
                final result = await showDialog<IconData>(
                  context: context,
                  builder: (_) => IconPickerDialog(currentIcon: _selectedIcon),
                );
                if (result != null) {
                  setState(() => _selectedIcon = result);
                }
              },
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('头像'),
              leading: CircleAvatar(),
              onTap: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (_) => AvatarPickerDialog(
                    username: _nameController.text,
                    currentAvatarPath: _avatarPath,
                  ),
                );
                if (result != null) {
                  setState(() => _avatarPath = result);
                }
              },
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### After (FormBuilderWrapper)

```dart
class EditUserScreen extends StatelessWidget {
  final User? initialUser;

  const EditUserScreen({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('编辑用户')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: FormBuilderWrapper(
          config: FormConfig(
            fields: [
              // 姓名
              FormFieldConfig(
                name: 'name',
                type: FormFieldType.text,
                labelText: '姓名',
                hintText: '请输入姓名',
                initialValue: initialUser?.name ?? '',
                prefixIcon: Icons.person,
                required: true,
                validationMessage: '姓名不能为空',
              ),

              // 邮箱
              FormFieldConfig(
                name: 'email',
                type: FormFieldType.email,
                labelText: '邮箱',
                hintText: '请输入邮箱地址',
                initialValue: initialUser?.email ?? '',
                prefixIcon: Icons.email,
              ),

              // 角色
              FormFieldConfig(
                name: 'role',
                type: FormFieldType.select,
                labelText: '角色',
                hintText: '请选择角色',
                initialValue: initialUser?.role ?? 'user',
                required: true,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('管理员')),
                  DropdownMenuItem(value: 'user', child: Text('用户')),
                  DropdownMenuItem(value: 'guest', child: Text('访客')),
                ],
              ),

              // 启用状态
              FormFieldConfig(
                name: 'isActive',
                type: FormFieldType.switchField,
                labelText: '启用状态',
                hintText: '是否启用此用户',
                initialValue: initialUser?.isActive ?? true,
                prefixIcon: Icons.power_settings_new,
              ),

              // 图标
              FormFieldConfig(
                name: 'icon',
                type: FormFieldType.iconPicker,
                labelText: '选择图标',
                initialValue: initialUser?.icon ?? Icons.person,
              ),

              // 头像
              FormFieldConfig(
                name: 'avatar',
                type: FormFieldType.avatarPicker,
                extra: {
                  'username': initialUser?.name ?? 'User',
                  'size': 60.0,
                  'saveDirectory': 'avatars',
                },
              ),
            ],
            submitButtonText: '保存',
            showResetButton: true,
            fieldSpacing: 16,
            onSubmit: (values) {
              final user = User(
                name: values['name'] as String,
                email: values['email'] as String,
                role: values['role'] as String,
                isActive: values['isActive'] as bool,
                icon: values['icon'] as IconData?,
                avatar: values['avatar'] as String?,
              );
              Navigator.pop(context, user);
            },
            onReset: () {
              // 重置为初始值
            },
            onValidationFailed: (errors) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('请检查输入：${errors.values.join(", ")}'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
```

## 表单联动与回调机制

FormBuilderWrapper 通过 `onChanged` 回调和 `visible` 条件函数支持复杂的表单联动场景。

### 联动场景类型

1. **字段值联动**: 一个字段变化时自动更新其他字段
2. **条件显示**: 根据某些字段的值显示/隐藏其他字段
3. **动态按钮**: 输入框前后按钮触发额外操作
4. **级联选择**: 选择器级联更新选项

### 技术实现

```dart
// 使用 onChanged 回调
FormFieldConfig(
  name: 'country',
  type: FormFieldType.select,
  onChanged: (value) {
    // 联动更新城市选项
    _updateCities(value);
  },
),

// 使用 visible 条件函数
FormFieldConfig(
  name: 'city',
  type: FormFieldType.select,
  visible: (values) => values['country'] != null,
),

// 使用 patchValue 更新其他字段
void _updateProviderFields(ServiceProvider provider) {
  _formKey.currentState?.patchValue({
    'baseUrl': provider.baseUrl,
    'headers': _formatHeaders(provider.headers),
  });
}
```

## Benefits

### 代码减少

- **状态管理**: 减少 50-70% 的状态变量
- **UI 代码**: 减少 60-80% 的 UI 样板代码
- **验证逻辑**: 统一的验证机制

### 可维护性提升

- **一致性**: 所有表单使用统一的 API
- **可测试性**: 配置化的表单更容易测试
- **可扩展性**: 添加新字段类型只需添加对应的 field 组件

### 功能增强

- **自动验证**: 内置必填字段验证
- **数据收集**: 自动收集所有字段值
- **重置功能**: 免费获得表单重置功能

## Best Practices

### 1. 字段命名

使用描述性的字段名称：

```dart
FormFieldConfig(
  name: 'userEmail',        // ✅ 清晰
  // name: 'email',         // ⚠️ 可能在上下文中模糊
)
```

### 2. 初始值处理

确保初始值类型正确：

```dart
FormFieldConfig(
  name: 'age',
  type: FormFieldType.number,
  initialValue: int.tryParse(user.age) ?? 0,  // ✅ 安全转换
  // initialValue: user.age,  // ❌ 可能是 String
)
```

### 3. 条件渲染

对于条件字段，使用单独的表单或动态配置：

```dart
final fields = <FormFieldConfig>[
  FormFieldConfig(name: 'type', type: FormFieldType.select, ...),
  // 根据类型添加额外字段
  if (selectedType == 'premium') ...[
    FormFieldConfig(name: 'premiumFeatures', ...),
  ],
];
```

### 4. 自定义验证

对于复杂验证，使用 `onValidationFailed` 回调：

```dart
onValidationFailed: (errors) {
  // 自定义错误处理
  if (errors.containsKey('email')) {
    _showEmailError();
  }
},
```

## Testing Checklist

转换完成后验证：

- [ ] `flutter analyze` 无错误
- [ ] 所有字段都能正确显示
- [ ] 值变化能正确触发 `onChanged`
- [ ] 必填字段验证正常工作
- [ ] 提交按钮能收集所有字段值（包括 WrappedFormField）
- [ ] **如果使用外部提交按钮**：验证 `onStateReady` 被调用且 `submitForm()` 正确触发
- [ ] 重置按钮能恢复初始值
- [ ] 国际化文本正确显示
- [ ] Picker 字段对话框能正常打开

## 最佳实践总结

### 1. 提交按钮位置选择

| 场景 | 推荐做法 |
|-----|---------|
| 表单在页面主体 | 使用 `FormBuilderWrapper` 的 `buttonBuilder` 或 `showSubmitButton: true` |
| 表单在弹窗/底部抽屉 | 同上 |
| 表单在复杂页面（按钮在 AppBar） | 使用 `onStateReady` + `_wrapperState.submitForm()` |
| 按钮在多个位置 | 使用 `FormBuilderWrapperState` 的 `submitForm()` 方法 |

### 2. 为什么不能直接用 `formKey.value`？

- `FormBuilder.value` 只包含通过 `FormBuilderField` 注册的字段
- `WrappedFormField` 使用自己的状态管理，不注册到 `FormBuilder`
- `FormBuilderWrapperState.submitForm()` 会正确保存并合并所有字段值

### 3. 必须记住的三件事

```
1. 声明状态变量：FormBuilderWrapperState? _wrapperState;
2. 获取状态：onStateReady: (state) => _wrapperState = state,
3. 触发提交：_wrapperState?.submitForm();
```

## Troubleshooting

### AppBar 按钮无法收集表单值

**症状**: 点击 AppBar 保存按钮后，`onSubmit` 接收到的 `values` 为空或只有部分字段

**原因**: 使用外部按钮直接调用 `_formKey.currentState?.value`，但 `WrappedFormField` 不会自动注册到 `FormBuilder`

```dart
// ❌ 错误：直接在外部按钮中使用 formKey.value
TextButton(
  onPressed: () {
    final values = _formKey.currentState?.value ?? {};
    _handleSubmit(values);  // values 可能是空的！
  },
  child: Text('保存'),
)

// ✅ 正确：使用 onStateReady + submitForm
class _MyFormScreenState extends State<MyFormScreen> {
  FormBuilderWrapperState? _wrapperState;

  FormBuilderWrapper(
    onStateReady: (state) => _wrapperState = state,
    ...
  );

  TextButton(
    onPressed: () => _wrapperState?.submitForm(),
    child: Text('保存'),
  )
}
```

### formKey 参数错误

**症状**: `_formKey.currentState` 始终为 null

```dart
// ❌ 错误：使用 key 参数
FormBuilderWrapper(
  key: _formKey,  // 这是 Flutter widget key，不是 FormBuilder key
)

// ✅ 正确：使用 formKey 参数
FormBuilderWrapper(
  formKey: _formKey,
)
```

### 字段值未被收集

**症状**: 保存时 `values` 只包含部分字段或为空

**原因**: `WrappedFormField` 不会将值注册到 `FormBuilder`，必须使用 `FormBuilderField` 或 `flutter_form_builder` 内置字段

```dart
// ❌ 错误：使用 WrappedFormField
return WrappedFormField(
  name: config.name,
  builder: (context, value, setValue) => MyField(...),
);

// ✅ 正确：使用 FormBuilderField
return FormBuilderField<String>(
  name: config.name,
  initialValue: config.initialValue?.toString() ?? '',
  builder: (fieldState) => MyField(
    value: fieldState.value,
    onChanged: (v) => fieldState.didChange(v),  // 关键：通知 FormBuilder
  ),
);

// ✅ 或使用内置字段：FormBuilderTextField
return FormBuilderTextField(
  name: config.name,
  initialValue: config.initialValue?.toString() ?? '',
);
```

### buttonBuilder 参数位置错误

**症状**: `buttonBuilder` 参数未定义错误

```dart
// ❌ 错误：放在 config 中
FormBuilderWrapper(
  config: FormConfig(
    buttonBuilder: ...,  // FormConfig 没有这个参数
  ),
)

// ✅ 正确：作为 FormBuilderWrapper 的直接参数
FormBuilderWrapper(
  buttonBuilder: (context, onSubmit, onReset) => ElevatedButton(...),
  config: FormConfig(...),
)
```

### 类型转换错误

确保 `initialValue` 类型与字段类型匹配：

```dart
// ❌ 错误
FormFieldConfig(
  name: 'count',
  type: FormFieldType.number,
  initialValue: '123',  // String 类型
)

// ✅ 正确
FormFieldConfig(
  name: 'count',
  type: FormFieldType.number,
  initialValue: 123,  // int 类型
)
```

### Dropdown value 不在 items 中

**症状**: DropdownButton value assertion error

```dart
// ❌ 错误：initialValue 可能不在 items 列表中
FormFieldConfig(
  name: 'provider',
  initialValue: _selectedProviderId,  // 可能为空字符串或不存在
  items: _providers.map(...).toList(),
)

// ✅ 正确：确保 initialValue 在 items 中
FormFieldConfig(
  name: 'provider',
  initialValue: _providers.any((p) => p.id == _selectedProviderId)
      ? _selectedProviderId
      : (_providers.isNotEmpty ? _providers.first.id : null),
  items: _providers.map(...).toList(),
)
```

### Picker 不显示

检查是否有对应的 field 文件和正确的 FormFieldType：

```dart
// 确保在 form_builder_wrapper.dart 中有：
case FormFieldType.myPicker:
  return _buildMyPickerField(config, fieldKey!);
```

### 验证不生效

确保设置了 `required: true`：

```dart
FormFieldConfig(
  name: 'email',
  type: FormFieldType.email,
  required: true,  // 必需
  validationMessage: '邮箱不能为空',
)
```

## Notes

- 转换前建议先创建备份或使用版本控制
- 使用 `--dry-run` 参数预览修改
- 复杂表单可以分步骤转换
- 保留原有的业务逻辑代码，只转换 UI 部分
- 使用中文注释与现有代码库保持一致
- 运行 `flutter analyze` 验证转换后的代码
