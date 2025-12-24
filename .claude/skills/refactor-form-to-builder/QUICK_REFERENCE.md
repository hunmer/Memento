# Refactor Form to Builder - Quick Reference

快速参考指南：将传统表单转换为 FormBuilderWrapper

## 一行命令

```bash
/refactor-form-to-builder <form-file>
```

## 常见模式转换

### TextField → FormFieldConfig

```dart
// Before
TextField(
  controller: _controller,
  decoration: InputDecoration(labelText: '姓名'),
)

// After
FormFieldConfig(
  name: 'name',
  type: FormFieldType.text,
  labelText: '姓名',
  initialValue: _controller.text,
)
```

### DropdownButton → FormFieldConfig

```dart
// Before
DropdownButton<String>(
  value: _selected,
  items: [DropdownMenuItem(value: 'a', child: Text('A'))],
  onChanged: (v) => setState(() => _selected = v),
)

// After
FormFieldConfig(
  name: 'selected',
  type: FormFieldType.select,
  initialValue: 'a',
  items: [DropdownMenuItem(value: 'a', child: Text('A'))],
)
```

### Switch → FormFieldConfig

```dart
// Before
Switch(
  value: _enabled,
  onChanged: (v) => setState(() => _enabled = v),
)

// After
FormFieldConfig(
  name: 'enabled',
  type: FormFieldType.switchField,
  initialValue: true,
)
```

## Picker 字段 extra 参数

```dart
// IconPicker
extra: {'enableIconToImage': false}

// AvatarPicker
extra: {'username': 'User', 'size': 80.0, 'saveDirectory': 'avatars'}

// ImagePicker
extra: {
  'enableCrop': true,
  'cropAspectRatio': 1.0,
  'multiple': false,
  'enableCompression': false,
}

// CalendarStripPicker
extra: {'allowFutureDates': false, 'useShortWeekDay': true}
```

## 表单结构模板

```dart
FormBuilderWrapper(
  config: FormConfig(
    fields: [
      FormFieldConfig(name: 'xxx', type: FormFieldType.xxx, ...),
    ],
    submitButtonText: '提交',
    showResetButton: true,
    onSubmit: (values) => _handleSubmit(values),
  ),
)
```

## 验证配置

```dart
FormFieldConfig(
  name: 'email',
  type: FormFieldType.email,
  required: true,
  validationMessage: '邮箱不能为空',
)
```
