import 'dart:io';
import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import '../../../widgets/image_picker_dialog.dart';
import '../models/contact_model.dart';
import '../l10n/contact_strings.dart';
import 'package:uuid/uuid.dart';
import '../../../widgets/circle_icon_picker.dart';

class ContactForm extends StatefulWidget {
  final Contact? contact;
  final Function(Contact) onSave;

  const ContactForm({
    Key? key,
    this.contact,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  late List<String> _tags;
  late Map<String, String> _customFields;
  late IconData _selectedIcon;
  late Color _selectedIconColor;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _addressController = TextEditingController(text: widget.contact?.address ?? '');
    _notesController = TextEditingController(text: widget.contact?.notes ?? '');
    _tags = List.from(widget.contact?.tags ?? []);
    _customFields = Map.from(widget.contact?.customFields ?? {});
    _selectedIcon = widget.contact?.icon ?? Icons.person;
    _selectedIconColor = widget.contact?.iconColor ?? Colors.blue;
    _avatarUrl = widget.contact?.avatar;
  }
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addTag() {
    showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(ContactStrings.addTag),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '输入标签名称',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(ContactStrings.cancel),
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
              child: Text(ContactStrings.save),
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
          title: Text(ContactStrings.addCustomField),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  hintText: '字段名称',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  hintText: '字段值',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(ContactStrings.cancel),
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
              child: Text(ContactStrings.save),
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

  Future<void> _showImagePickerDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ImagePickerDialog(
        initialUrl: _avatarUrl,
        saveDirectory: 'contacts',
        enableCrop: true,
        cropAspectRatio: 1.0,
      ),
    );
    
    if (result != null && result['url'] != null) {
      setState(() {
        _avatarUrl = result['url'];
      });
    }
  }

  void _saveContact() {
    if (_formKey.currentState!.validate()) {
      final contact = Contact(
        id: widget.contact?.id ?? const Uuid().v4(),
        name: _nameController.text,
        avatar: _avatarUrl,
        icon: _selectedIcon,
        iconColor: _selectedIconColor,
        phone: _phoneController.text,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        tags: _tags,
        customFields: _customFields,
        createdTime: widget.contact?.createdTime,
        lastContactTime: widget.contact?.lastContactTime,
        contactCount: widget.contact?.contactCount ?? 0,
      );
      widget.onSave(contact);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: _showImagePickerDialog,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? FutureBuilder<String>(
                          future: _avatarUrl!.startsWith('http')
                              ? Future.value(_avatarUrl!)
                              : ImageUtils.getAbsolutePath(_avatarUrl),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Center(
                                child: AspectRatio(
                                  aspectRatio: 1.0,
                                  child: ClipOval(
                                    child: _avatarUrl!.startsWith('http')
                                        ? Image.network(
                                            snapshot.data!,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                          )
                                        : Image.file(
                                            File(snapshot.data!),
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                          ),
                                  ),
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return const Icon(Icons.broken_image);
                            } else {
                              return const CircularProgressIndicator();
                            }
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined, size: 24),
                              const SizedBox(height: 2),
                              Text(
                                '头像',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 32),
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
          // 姓名字段
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '姓名',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入联系人姓名';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // 电话字段
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: '电话',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入联系人电话';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // 地址字段
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: '地址',
              prefixIcon: Icon(Icons.home),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          // 备注字段
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: '备注',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: _addTag,
                icon: const Icon(Icons.add),
                label: Text(ContactStrings.addTag),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () => _removeTag(tag),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ContactStrings.customFields,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: _addCustomField,
                icon: const Icon(Icons.add),
                label: Text(ContactStrings.addCustomField),
              ),
            ],
          ),
          ..._customFields.entries.map((entry) {
            return Card(
              child: ListTile(
                title: Text(entry.key),
                subtitle: Text(entry.value),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeCustomField(entry.key),
                ),
              ),
            );
          }),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveContact,
            child: Text(ContactStrings.save),
          ),
        ],
      ),
    );
  }
}