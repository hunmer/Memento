import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/database/controllers/database_controller.dart';
import 'package:Memento/plugins/database/models/database_model.dart';
import 'package:Memento/widgets/form_fields/index.dart';
import '../models/record.dart' as record_model;

class RecordEditWidget extends StatefulWidget {
  final DatabaseController controller;
  final DatabaseModel database;
  final Map<String, dynamic>? initialFields;
  final record_model.Record? record;

  const RecordEditWidget({
    super.key,
    required this.controller,
    required this.database,
    this.initialFields,
    this.record,
  });

  @override
  State<RecordEditWidget> createState() => _RecordEditWidgetState();
}

class _RecordEditWidgetState extends State<RecordEditWidget> {
  late Map<String, dynamic> _fields;
  FormBuilderWrapperState? _formState;

  @override
  void initState() {
    super.initState();
    _fields = widget.initialFields ?? {};
    for (final field in widget.database.fields) {
      _fields.putIfAbsent(field.name, () {
        switch (field.type) {
          case 'Checkbox':
            return false;
          case 'Integer':
            return 0;
          case 'Rating':
            return 0;
          case 'Date':
          case 'Time':
          case 'Date/Time':
            return DateTime.now();
          default:
            return '';
        }
      });
    }
  }

  /// 将 DatabaseField 类型映射到 FormFieldType
  FormFieldType _mapFieldType(String databaseFieldType) {
    switch (databaseFieldType) {
      case 'Text':
        return FormFieldType.text;
      case 'Long Text':
        return FormFieldType.textArea;
      case 'Password':
        return FormFieldType.password;
      case 'Integer':
        return FormFieldType.number;
      case 'Checkbox':
        return FormFieldType.switchField;
      case 'Date':
        return FormFieldType.date;
      case 'Time':
        return FormFieldType.time;
      case 'Date/Time':
        return FormFieldType.date;
      case 'Image':
        return FormFieldType.imagePicker;
      case 'URL':
        return FormFieldType.text;
      case 'Rating':
        return FormFieldType.slider;
      case 'Dropdown':
        return FormFieldType.select;
      default:
        return FormFieldType.text;
    }
  }

  /// 将 DatabaseField 列表转换为 FormFieldConfig 列表
  List<FormFieldConfig> _buildFormConfigs() {
    return widget.database.fields.map((field) {
      // 从 metadata 读取配置
      final metadata = field.metadata ?? {};

      // 获取默认值（优先使用 metadata 中的 defaultValue）
      dynamic defaultValue = _fields[field.name];
      if (metadata.containsKey('defaultValue') && defaultValue == null) {
        final metaDefault = metadata['defaultValue'];
        // 根据字段类型转换默认值
        switch (field.type) {
          case 'Integer':
          case 'Rating':
            defaultValue = int.tryParse(metaDefault?.toString() ?? '');
            break;
          case 'Checkbox':
            defaultValue = metaDefault == true;
            break;
          default:
            defaultValue = metaDefault?.toString() ?? '';
        }
      }

      // 构建 extra 配置
      Map<String, dynamic> extra = {};

      // 根据字段类型添加额外配置
      switch (field.type) {
        case 'Long Text':
          if (metadata.containsKey('maxLines')) {
            extra['maxLines'] = int.tryParse(metadata['maxLines']?.toString() ?? '') ?? 3;
          }
          break;
        case 'Integer':
          if (metadata.containsKey('minValue')) {
            extra['min'] = double.tryParse(metadata['minValue']?.toString() ?? '')?.toDouble() ?? 0.0;
          }
          if (metadata.containsKey('maxValue')) {
            extra['max'] = double.tryParse(metadata['maxValue']?.toString() ?? '')?.toDouble() ?? 100.0;
          }
          break;
        case 'Rating':
          if (metadata.containsKey('minValue')) {
            extra['min'] = double.tryParse(metadata['minValue']?.toString() ?? '')?.toDouble() ?? 0.0;
          }
          if (metadata.containsKey('maxValue')) {
            extra['max'] = double.tryParse(metadata['maxValue']?.toString() ?? '')?.toDouble() ?? 5.0;
          }
          extra['divisions'] = int.tryParse(metadata['maxValue']?.toString() ?? '') ?? 5;
          break;
        case 'Dropdown':
          // 解析选项列表
          if (metadata.containsKey('options')) {
            final optionsStr = metadata['options']?.toString() ?? '';
            final optionsList = optionsStr.split('\n').where((s) => s.trim().isNotEmpty).toList();
            extra['items'] = optionsList.map((opt) => DropdownMenuItem(
              value: opt,
              child: Text(opt),
            )).toList();
          }
          break;
        case 'Date':
        case 'Time':
        case 'Date/Time':
          if (metadata.containsKey('format')) {
            extra['format'] = metadata['format'];
          }
          break;
      }

      // 构建 FormFieldConfig
      return FormFieldConfig(
        name: field.name,
        type: _mapFieldType(field.type),
        labelText: field.name,
        hintText: metadata['placeholder']?.toString(),
        initialValue: defaultValue,
        required: field.isRequired,
        validationMessage: '${field.name}不能为空',
        enabled: true,
        extra: extra.isNotEmpty ? extra : null,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final formConfigs = _buildFormConfigs();

    return Scaffold(
      appBar: AppBar(
        title: Text('database_edit_record_title'.tr),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveRecord),
        ],
      ),
      body: FormBuilderWrapper(
        onStateReady: (state) {
          _formState = state;
        },
        config: FormConfig(
          fields: formConfigs,
          showSubmitButton: false,
          showResetButton: false,
          fieldSpacing: 16,
          onSubmit: (values) {
            // 表单提交在 _saveRecord 中处理
          },
        ),
      ),
    );
  }

  Future<void> _saveRecord() async {
    // 验证并保存表单
    final isValid = _formState?.saveAndValidate() ?? false;

    if (isValid) {
      // 从 FormBuilderWrapper 获取表单值
      final formValues = _formState?.currentValues ?? {};

      record_model.Record resultRecord;

      if (widget.record != null) {
        // 更新现有记录
        resultRecord = widget.record!.copyWith(
          fields: formValues,
          updatedAt: DateTime.now(),
        );
        await widget.controller.updateRecord(resultRecord);
      } else {
        // 创建新记录
        resultRecord = record_model.Record(
          id: const Uuid().v4(),
          tableId: widget.database.id,
          fields: formValues,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await widget.controller.createRecord(resultRecord);
      }

      if (mounted) {
        Navigator.of(context).pop(resultRecord);
      }
    }
  }
}
