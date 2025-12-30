import 'package:flutter/material.dart';
import 'script_trigger.dart';
import 'script_input.dart';
import 'package:Memento/widgets/form_fields/types.dart';
import 'package:Memento/widgets/form_fields/config.dart';

/// 从JSON解析FormFieldConfig列表
List<FormFieldConfig> _parseConfigFormFields(List<dynamic>? jsonList) {
  if (jsonList == null) return [];

  return jsonList.map((item) {
    final json = item as Map<String, dynamic>;
    final typeName = json['type'] as String?;

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
      prefixIcon: _parseIcon(json['prefixIcon'] as String?),
      extra: json['type'] == 'pluginDataSelector'
          ? {
              'pluginDataType': json['pluginDataType'] as String?,
              if (json['fieldMapping'] != null) 'fieldMapping': json['fieldMapping'] as Map<String, dynamic>,
            }
          : json['type'] == 'eventMultiSelect'
              ? {'eventMultiSelect': true}
              : null,
    );
  }).toList();
}

/// 解析图标名称为IconData
IconData? _parseIcon(String? iconName) {
  if (iconName == null) return null;
  // 简化处理，返回null，实际项目中可以使用图标映射
  return null;
}

/// 脚本元数据模型
///
/// 存储脚本的所有配置信息，对应metadata.json文件
class ScriptInfo {
  /// 脚本唯一标识（通常是目录名）
  final String id;

  /// 脚本目录路径
  final String path;

  /// 脚本名称（显示名称）
  String name;

  /// 版本号（语义化版本）
  String version;

  /// 脚本描述
  String description;

  /// 图标名称（Material Icons）
  String icon;

  /// 作者名称
  String author;

  /// 更新地址（可选，用于未来的自动更新功能）
  String? updateUrl;

  /// 是否启用
  bool enabled;

  /// 是否自动运行（在插件初始化后自动执行）
  bool autoRun;

  /// 脚本类型：module（可接受参数）| standalone（独立运行）
  String type;

  /// 输入参数定义（仅用于 module 类型）
  List<ScriptInput> inputs;

  /// 触发条件列表
  List<ScriptTrigger> triggers;

  /// 配置表单字段（用于动态渲染配置界面）
  List<FormFieldConfig> configFormFields;

  /// 创建时间
  final DateTime? createdAt;

  /// 最后修改时间
  DateTime? updatedAt;

  /// 本地脚本文件路径（可选，用于从外部文件同步脚本内容）
  String? localScriptPath;

  ScriptInfo({
    required this.id,
    required this.path,
    required this.name,
    required this.version,
    required this.description,
    this.icon = 'code',
    this.author = 'Unknown',
    this.updateUrl,
    this.enabled = true,
    this.autoRun = false,
    this.type = 'module',
    this.inputs = const [],
    this.triggers = const [],
    this.configFormFields = const [],
    this.createdAt,
    this.updatedAt,
    this.localScriptPath,
  });

  /// 从JSON创建脚本信息对象
  factory ScriptInfo.fromJson(
    Map<String, dynamic> json, {
    required String id,
    required String path,
  }) {
    return ScriptInfo(
      id: id,
      path: path,
      name: json['name'] as String? ?? 'Unnamed Script',
      version: json['version'] as String? ?? '1.0.0',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'code',
      author: json['author'] as String? ?? 'Unknown',
      updateUrl: json['updateUrl'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      autoRun: json['autoRun'] as bool? ?? false,
      type: json['type'] as String? ?? 'module',
      inputs: (json['inputs'] as List<dynamic>?)
              ?.map((e) => ScriptInput.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      triggers: (json['triggers'] as List<dynamic>?)
              ?.map((e) => ScriptTrigger.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      configFormFields: _parseConfigFormFields(
          json['configFormFields'] as List<dynamic>?),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      localScriptPath: json['localScriptPath'] as String?,
    );
  }

  /// 转换为JSON（用于保存metadata.json）
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'description': description,
      'icon': icon,
      'author': author,
      if (updateUrl != null) 'updateUrl': updateUrl,
      'enabled': enabled,
      'autoRun': autoRun,
      'type': type,
      'inputs': inputs.map((i) => i.toJson()).toList(),
      'triggers': triggers.map((t) => t.toJson()).toList(),
      if (configFormFields.isNotEmpty)
        'configFormFields': configFormFields.map((field) {
          final json = <String, dynamic>{
            'name': field.name,
            'type': field.type.name,
            if (field.labelText != null) 'labelText': field.labelText,
            if (field.hintText != null) 'hintText': field.hintText,
            if (field.initialValue != null) 'initialValue': field.initialValue,
            if (field.required) 'required': field.required,
            if (field.validationMessage != null) 'validationMessage': field.validationMessage,
            if (!field.enabled) 'enabled': field.enabled,
            if (field.extra != null) ...field.extra!,
          };
          return json;
        }).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (localScriptPath != null) 'localScriptPath': localScriptPath,
    };
  }

  /// 创建副本，可选择性修改部分字段
  ScriptInfo copyWith({
    String? name,
    String? version,
    String? description,
    String? icon,
    String? author,
    String? updateUrl,
    bool? enabled,
    bool? autoRun,
    String? type,
    List<ScriptInput>? inputs,
    List<ScriptTrigger>? triggers,
    List<FormFieldConfig>? configFormFields,
    DateTime? updatedAt,
    String? localScriptPath,
  }) {
    return ScriptInfo(
      id: id,
      path: path,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      author: author ?? this.author,
      updateUrl: updateUrl ?? this.updateUrl,
      enabled: enabled ?? this.enabled,
      autoRun: autoRun ?? this.autoRun,
      type: type ?? this.type,
      inputs: inputs ?? this.inputs,
      triggers: triggers ?? this.triggers,
      configFormFields: configFormFields ?? this.configFormFields,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      localScriptPath: localScriptPath ?? this.localScriptPath,
    );
  }

  /// 获取脚本代码文件路径
  String get scriptFilePath => '$path/script.js';

  /// 获取元数据文件路径
  String get metadataFilePath => '$path/metadata.json';

  /// 是否有触发器配置
  bool get hasTriggers => triggers.isNotEmpty;

  /// 是否是 module 类型（可接受参数）
  bool get isModule => type == 'module';

  /// 是否需要输入参数
  bool get hasInputs => inputs.isNotEmpty;

  @override
  String toString() {
    return 'ScriptInfo{id: $id, name: $name, version: $version, enabled: $enabled}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScriptInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
