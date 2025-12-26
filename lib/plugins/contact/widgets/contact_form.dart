import 'package:Memento/widgets/form_fields/config.dart';
import 'package:Memento/widgets/form_fields/types.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/contact/models/contact_model.dart';
import 'package:Memento/plugins/contact/models/custom_activity_event_model.dart';
import 'package:Memento/plugins/goods/models/custom_field.dart';
import 'package:Memento/widgets/form_fields/form_builder_wrapper.dart';

/// 联系人表单 - 使用 FormBuilderWrapper 重构版本
///
/// 功能特性：
/// - 头像和姓名编辑
/// - 性别选择
/// - 电话、地址、备注等基本信息
/// - 标签管理
/// - 自定义字段
/// - 自定义活动事件
class ContactForm extends StatefulWidget {
  final Contact? contact;
  final Function(Contact) onSave;
  final Function()? onDelete;

  const ContactForm({
    super.key,
    this.contact,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<ContactForm> createState() => ContactFormState();
}

class ContactFormState extends State<ContactForm> {
  // 使用 GlobalKey 访问 FormBuilderWrapperState 的 submitForm 方法
  final GlobalKey<FormBuilderWrapperState> _wrapperKey = GlobalKey<FormBuilderWrapperState>();

  // 从联系人名字中提取名字和姓氏
  ({String firstName, String lastName}) _parseName(String name) {
    if (name.isEmpty) return (firstName: '', lastName: '');
    final names = name.split(' ');
    return (
      firstName: names.first,
      lastName: names.length > 1 ? names.sublist(1).join(' ') : '',
    );
  }

  // 将 Map<String, String> 转换为 List<CustomField>
  List<CustomField> _convertToCustomFields(Map<String, String>? customFields) {
    if (customFields == null) return [];
    return customFields.entries
        .map((e) => CustomField(key: e.key, value: e.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.contact != null;

    // 解析初始值
    final nameParts = widget.contact != null
        ? _parseName(widget.contact!.name)
        : (firstName: '', lastName: '');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditing ? 'contact_editContact'.tr : 'contact_addContact'.tr,
        ),
        actions: [
          if (isEditing) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context),
            ),
          ],
          TextButton(
            onPressed: _handleSave,
            child: Text(
              'contact_done'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FormBuilderWrapper(
            key: _wrapperKey,
            config: FormConfig(
              showSubmitButton: false,
              showResetButton: false,
              fieldSpacing: 24,
              fields: [
                // 头像和姓名区域
                FormFieldConfig(
                  name: 'avatarNameSection',
                  type: FormFieldType.avatarNameSection,
                  initialValue: {
                    'avatarUrl': widget.contact?.avatar,
                    'firstName': nameParts.firstName,
                    'lastName': nameParts.lastName,
                  },
                ),

                // 性别选择
                FormFieldConfig(
                  name: 'gender',
                  type: FormFieldType.genderSelector,
                  initialValue: widget.contact?.gender,
                ),

                // 电话
                FormFieldConfig(
                  name: 'phone',
                  type: FormFieldType.text,
                  labelText: 'Phone',
                  hintText: 'Enter phone number',
                  initialValue: widget.contact?.phone ?? '',
                  prefixIcon: Icons.add_circle,
                ),

                // 备注
                FormFieldConfig(
                  name: 'notes',
                  type: FormFieldType.textArea,
                  labelText: 'Annotation / Introduction',
                  hintText: 'Add a note about this contact...',
                  initialValue: widget.contact?.notes ?? '',
                  extra: {'minLines': 3, 'maxLines': 5},
                ),

                // 标签
                FormFieldConfig(
                  name: 'tags',
                  type: FormFieldType.tags,
                  labelText: 'Tags',
                  hintText: 'Add tags (e.g., Work, Family)',
                  initialTags: widget.contact?.tags ?? [],
                ),

                // 地址
                FormFieldConfig(
                  name: 'address',
                  type: FormFieldType.text,
                  labelText: 'Address',
                  hintText: 'Enter address',
                  initialValue: widget.contact?.address ?? '',
                  prefixIcon: Icons.add_circle,
                ),

                // 自定义活动事件
                FormFieldConfig(
                  name: 'customActivityEvents',
                  type: FormFieldType.customEvents,
                  labelText: 'contact_customActivityEvents'.tr,
                  hintText: 'contact_addCustomEvent'.tr,
                  initialValue: widget.contact?.customActivityEvents ?? [],
                ),

                // 自定义字段
                FormFieldConfig(
                  name: 'customFields',
                  type: FormFieldType.customFields,
                  labelText: 'contact_customFields'.tr,
                  hintText: 'contact_addCustomField'.tr,
                  initialValue: _convertToCustomFields(widget.contact?.customFields),
                ),
              ],
              onSubmit: (values) => _saveContact(context, values),
            ),
          ),
        ),
      ),
    );
  }

  // 处理保存
  void _handleSave() {
    _wrapperKey.currentState?.submitForm();
  }

  // 保存联系人
  void _saveContact(BuildContext context, Map<String, dynamic> values) {
    // 从 avatarNameSection 中提取数据
    final avatarNameSection = values['avatarNameSection'] as Map<String, dynamic>? ?? {};
    final firstName = avatarNameSection['firstName'] as String? ?? '';
    final lastName = avatarNameSection['lastName'] as String? ?? '';
    final avatarUrl = avatarNameSection['avatarUrl'] as String?;

    // 组合姓名
    final name = '$firstName $lastName'.trim();

    // 处理标签
    final tags = values['tags'] as List<String>? ?? [];

    // 处理自定义字段
    final customFieldList = values['customFields'] as List<dynamic>? ?? [];
    final customFields = {
      for (var field in customFieldList)
        if (field is CustomField && field.key.isNotEmpty)
          field.key: field.value,
    };

    // 处理自定义活动事件
    final customEvents = values['customActivityEvents'] as List<dynamic>? ?? [];
    final customActivityEvents = customEvents.cast<CustomActivityEvent>();

    final existingContact = widget.contact;
    final newContact = Contact(
      id: existingContact?.id ?? const Uuid().v4(),
      name: name,
      avatar: avatarUrl,
      phone: values['phone'] as String? ?? '',
      address: values['address'] as String?,
      notes: values['notes'] as String?,
      tags: tags,
      gender: values['gender'] as ContactGender?,
      customFields: customFields,
      customActivityEvents: customActivityEvents,
      createdTime: existingContact?.createdTime ?? DateTime.now(),
      // 保留原有图标设置
      icon: existingContact?.icon ?? Icons.person,
      iconColor: existingContact?.iconColor ?? Colors.blue,
    );

    widget.onSave(newContact);

    // 延迟等待 onSave 回调完成
    Future.delayed(const Duration(milliseconds: 50), () {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // 显示删除确认对话框
  void _showDeleteConfirmation(BuildContext context) {
    final targetContact = widget.contact;
    if (targetContact == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('确认删除'),
          content: Text('确定要删除联系人 "${targetContact.name}" 吗？\n此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // 调用 onDelete 回调
                widget.onDelete?.call();
                // 延迟等待删除完成后导航返回
                await Future.delayed(const Duration(milliseconds: 100));
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}
