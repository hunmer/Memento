import 'dart:io';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../l10n/contact_localizations.dart';
import '../../../widgets/image_picker_dialog.dart';
import '../../../widgets/circle_icon_picker.dart';
import '../../../utils/image_utils.dart';
import '../models/contact_model.dart';
import '../models/interaction_record_model.dart';
import '../controllers/contact_controller.dart';
import '../l10n/contact_localizations.dart';
import 'interaction_form.dart';
import 'package:uuid/uuid.dart';

// 首先定义ContactForm类
class ContactForm extends StatefulWidget {
  final Contact? contact;
  final Function(Contact) onSave;
  final ContactController controller;
  final GlobalKey<ContactFormState>? formStateKey;

  const ContactForm({
    super.key,
    this.contact,
    required this.onSave,
    required this.controller,
    this.formStateKey,
  });

  @override
  ContactFormState createState() => ContactFormState();
}

// 然后定义ContactFormState类
class ContactFormState extends State<ContactForm> {
  // 添加一个表单键，用于访问表单状态
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  late List<String> _tags;
  late Map<String, String> _customFields;
  late IconData _selectedIcon;
  late Color _selectedIconColor;
  String? _avatarUrl;
  List<InteractionRecord> _interactions = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _addressController = TextEditingController(
      text: widget.contact?.address ?? '',
    );
    _notesController = TextEditingController(text: widget.contact?.notes ?? '');
    _tags = List.from(widget.contact?.tags ?? []);
    _customFields = Map.from(widget.contact?.customFields ?? {});
    _selectedIcon = widget.contact?.icon ?? Icons.person;
    _selectedIconColor = widget.contact?.iconColor ?? Colors.blue;
    _avatarUrl = widget.contact?.avatar;
    _loadInteractions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInteractions() async {
    if (widget.contact != null) {
      final interactions = await widget.controller.getInteractionsByContactId(
        widget.contact!.id,
      );
      setState(() {
        _interactions = interactions;
      });
    }
  }

  void _addTag() {
    showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(ContactLocalizations.of(context)!.addTag),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '输入标签名称'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(ContactLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _tags.add(controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(ContactLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _addCustomField() {
    showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final keyController = TextEditingController();
        final valueController = TextEditingController();
        return AlertDialog(
          title: Text(ContactLocalizations.of(context)!.addCustomField),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(hintText: '字段名称'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(hintText: '字段值'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(ContactLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                if (keyController.text.isNotEmpty &&
                    valueController.text.isNotEmpty) {
                  setState(() {
                    _customFields[keyController.text] = valueController.text;
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(ContactLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
  }

  void _removeCustomField(String key) {
    setState(() {
      _customFields.remove(key);
    });
  }

  void _pickAvatar() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => const ImagePickerDialog(
            // initialUrl: _imageUrl,
            saveDirectory: 'contacts/images',
            enableCrop: true, // 启用裁切功能
            cropAspectRatio: 1 / 1,
          ),
    );

    if (result != null && result['url'] != null) {
      setState(() {
        _avatarUrl = result['url'];
      });
    }
  }

  // 公开的保存方法
  void saveContact() {
    // 使用类中定义的_formKey访问表单状态
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      // 创建联系人对象
      final contact = Contact(
        id: widget.contact?.id ?? const Uuid().v4(),
        name: _nameController.text,
        avatar: _avatarUrl,
        icon: _selectedIcon,
        iconColor: _selectedIconColor,
        phone: _phoneController.text,
        address: _addressController.text,
        notes: _notesController.text,
        tags: _tags,
        customFields: _customFields,
        createdTime: widget.contact?.createdTime ?? DateTime.now(),
      );

      // 直接调用保存回调
      widget.onSave(contact);
    }
  }

  void _addInteraction() async {
    if (widget.contact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ContactLocalizations.of(context)!.saveFirstMessage),
        ),
      );
      return;
    }

    final result = await showDialog<InteractionRecord>(
      context: context,
      builder:
          (context) => InteractionForm(
            contactId: widget.contact!.id,
            controller: widget.controller,
            onSave: (interaction) async {
              await widget.controller.addInteraction(interaction);
              await _loadInteractions();
            },
          ),
    );

    if (result != null) {
      await _loadInteractions();
    }
  }

  Future<void> _deleteInteraction(InteractionRecord interaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.confirmDelete),
            content: Text(
              ContactLocalizations.of(context)!.deleteConfirmMessage,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await widget.controller.deleteInteraction(interaction.id);
      await _loadInteractions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: ContactLocalizations.of(context)!.basicInfoTab),
              Tab(text: ContactLocalizations.of(context)!.recordsTab),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 基本信息标签页
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 头像和图标选择
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: _pickAvatar,
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.5),
                                      width: 2,
                                    ),
                                  ),
                                  child: FutureBuilder<String?>(
                                    future:
                                        _avatarUrl != null
                                            ? ImageUtils.getAbsolutePath(
                                              _avatarUrl!,
                                            )
                                            : Future.value(null),
                                    builder: (context, snapshot) {
                                      return ClipOval(
                                        child:
                                            snapshot.data != null
                                                ? Image.file(
                                                  File(snapshot.data!),
                                                  width: 64,
                                                  height: 64,
                                                  fit: BoxFit.cover,
                                                )
                                                : Container(
                                                  color: _selectedIconColor
                                                      .withOpacity(0.1),
                                                  child: Center(
                                                    child: Text(
                                                      ContactLocalizations.of(
                                                        context,
                                                      )!.upload,
                                                      style: const TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            CircleIconPicker(
                              currentIcon: _selectedIcon,
                              backgroundColor: _selectedIconColor,
                              onIconSelected: (icon) {
                                setState(() {
                                  _selectedIcon = icon;
                                });
                              },
                              onColorSelected: (color) {
                                setState(() {
                                  _selectedIconColor = color;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 基本信息表单
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText:
                                ContactLocalizations.of(context)!.nameLabel,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return ContactLocalizations.of(
                                context,
                              )!.nameRequiredError;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText:
                                ContactLocalizations.of(context)!.phoneLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText:
                                ContactLocalizations.of(context)!.addressLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText:
                                ContactLocalizations.of(context)!.notesLabel,
                            border: const OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // 标签
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '标签',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addTag,
                              tooltip:
                                  ContactLocalizations.of(
                                    context,
                                  )!.addTagTooltip,
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          children:
                              _tags
                                  .map(
                                    (tag) => Chip(
                                      label: Text(tag),
                                      onDeleted: () => _removeTag(tag),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 16),

                        // 自定义字段
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '自定义字段',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addCustomField,
                              tooltip:
                                  ContactLocalizations.of(
                                    context,
                                  )!.addCustomFieldTooltip,
                            ),
                          ],
                        ),
                        ..._customFields.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${entry.key}: ${entry.value}',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed:
                                      () => _removeCustomField(entry.key),
                                  tooltip:
                                      ContactLocalizations.of(
                                        context,
                                      )!.deleteFieldTooltip,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 联系记录标签页
                Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _interactions.length,
                      itemBuilder: (context, index) {
                        final interaction = _interactions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(interaction.notes),
                            subtitle: Text(
                              '${interaction.date.year}-${interaction.date.month.toString().padLeft(2, '0')}-${interaction.date.day.toString().padLeft(2, '0')} ${interaction.date.hour.toString().padLeft(2, '0')}:${interaction.date.minute.toString().padLeft(2, '0')}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteInteraction(interaction),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: FloatingActionButton(
                        onPressed: _addInteraction,
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
