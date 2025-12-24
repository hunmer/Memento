import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:Memento/widgets/picker/image_picker_dialog.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/plugins/contact/models/contact_model.dart';
import 'package:Memento/plugins/contact/models/custom_activity_event_model.dart';
import 'package:Memento/plugins/contact/controllers/contact_controller.dart';
import 'package:uuid/uuid.dart';

class ContactForm extends StatefulWidget {
  final Contact? contact;
  final Function(Contact) onSave;
  final Function()? onDelete;
  final ContactController controller;
  final GlobalKey<ContactFormState>? formStateKey;

  const ContactForm({
    super.key,
    this.contact,
    required this.onSave,
    this.onDelete,
    required this.controller,
    this.formStateKey,
  });

  @override
  ContactFormState createState() => ContactFormState();
}

class ContactFormState extends State<ContactForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  late TextEditingController _tagsController;
  late TextEditingController _addressController;

  String? _avatarUrl;
  ContactGender? _gender;

  List<CustomActivityEvent> _customActivityEvents = [];
  List<MapEntry<TextEditingController, TextEditingController>>
  _customFieldControllers = [];
  List<MapEntry<TextEditingController, Color>> _customEventControllers = [];

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;
    String firstName = '';
    String lastName = '';
    if (contact?.name != null && contact!.name.isNotEmpty) {
      final names = contact.name.split(' ');
      firstName = names.first;
      if (names.length > 1) {
        lastName = names.sublist(1).join(' ');
      }
    }

    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _phoneController = TextEditingController(text: contact?.phone ?? '');
    _addressController = TextEditingController(text: contact?.address ?? '');
    _notesController = TextEditingController(text: contact?.notes ?? '');
    _tagsController = TextEditingController(
      text: contact?.tags.join(', ') ?? '',
    );
    _avatarUrl = contact?.avatar;
    _gender = contact?.gender;

    if (contact?.customFields != null) {
      _customFieldControllers =
          contact!.customFields.entries
              .map(
                (e) => MapEntry(
                  TextEditingController(text: e.key),
                  TextEditingController(text: e.value),
                ),
              )
              .toList();
    }
    if (contact?.customActivityEvents != null) {
      _customActivityEvents = List.from(contact!.customActivityEvents);
      _customEventControllers =
          contact.customActivityEvents
              .map(
                (e) => MapEntry(TextEditingController(text: e.title), e.color),
              )
              .toList();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    for (var entry in _customFieldControllers) {
      entry.key.dispose();
      entry.value.dispose();
    }
    for (var entry in _customEventControllers) {
      entry.key.dispose();
    }
    super.dispose();
  }

  void saveContact() {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final name =
          '${_firstNameController.text} ${_lastNameController.text}'.trim();
      final tags =
          _tagsController.text
              .replaceAll('，', ',')
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

      final customFields = {
        for (var entry in _customFieldControllers)
          if (entry.key.text.isNotEmpty) entry.key.text: entry.value.text,
      };

      final customEvents = <CustomActivityEvent>[];
      for (int i = 0; i < _customEventControllers.length; i++) {
        if (_customEventControllers[i].key.text.isNotEmpty) {
          final id =
              i < _customActivityEvents.length
                  ? _customActivityEvents[i].id
                  : const Uuid().v4();
          customEvents.add(
            CustomActivityEvent(
              id: id,
              title: _customEventControllers[i].key.text,
              color: _customEventControllers[i].value,
            ),
          );
        }
      }

      final contact = Contact(
        id: widget.contact?.id ?? const Uuid().v4(),
        name: name,
        avatar: _avatarUrl,
        phone: _phoneController.text,
        address: _addressController.text,
        notes: _notesController.text,
        tags: tags,
        gender: _gender,
        customFields: customFields,
        customActivityEvents: customEvents,
        createdTime: widget.contact?.createdTime ?? DateTime.now(),
        // These are not in the new form, so we keep the old values
        icon: widget.contact?.icon ?? Icons.person,
        iconColor: widget.contact?.iconColor ?? Colors.blue,
      );
      widget.onSave(contact);
    }
  }

  void _pickAvatar() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => const ImagePickerDialog(
            saveDirectory: 'contacts/images',
            enableCrop: true,
            cropAspectRatio: 1 / 1,
          ),
    );

    if (result != null && result['url'] != null) {
      setState(() {
        _avatarUrl = result['url'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.contact != null;

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
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatarSection(),
                const SizedBox(height: 24),
                _buildGenderPicker(),
                const SizedBox(height: 24),
                _buildTextFieldWithIcon(
                  _phoneController,
                  'Phone',
                  Icons.add_circle,
                ),
                const SizedBox(height: 16),
                _buildNotesField(),
                const SizedBox(height: 16),
                _buildTextFieldWithIcon(
                  _tagsController,
                  'Add Tags (e.g., Work, Family)',
                  null,
                  iconOnLeft: false,
                ),
                const SizedBox(height: 16),
                _buildTextFieldWithIcon(
                  _addressController,
                  'Address',
                  Icons.add_circle,
                ),
                const SizedBox(height: 24),
                _buildCustomEventsSection(),
                const SizedBox(height: 24),
                _buildCustomFieldsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 处理保存操作
  Future<void> _handleSave() async {
    saveContact();
    // 延迟等待 onSave 回调完成
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final contact = widget.contact;
    if (contact == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('确认删除'),
          content: Text('确定要删除联系人 "${contact.name}" 吗？\n此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // 调用 onDelete 回调，由父组件处理删除逻辑
                widget.onDelete?.call();
                // 延迟等待删除完成后导航返回
                await Future.delayed(const Duration(milliseconds: 100));
                if (mounted) {
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

  Widget _buildAvatarSection() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Stack(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: ClipOval(
                child:
                    _avatarUrl != null
                        ? FutureBuilder<String>(
                          future: ImageUtils.getAbsolutePath(_avatarUrl!),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.file(
                                File(snapshot.data!),
                                fit: BoxFit.cover,
                              );
                            }
                            return const CircularProgressIndicator();
                          },
                        )
                        : Container(
                          color: theme.cardColor,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: theme.hintColor,
                          ),
                        ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor,
                    border: Border.all(color: theme.cardColor, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildBorderlessTextField(_firstNameController, 'First Name'),
              _buildBorderlessTextField(_lastNameController, 'Last Name'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBorderlessTextField(
    TextEditingController controller,
    String placeholder,
  ) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: theme.hintColor),
        border: InputBorder.none,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildGenderPicker() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _gender = ContactGender.male),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _gender == ContactGender.male ? theme.cardColor : null,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow:
                      _gender == ContactGender.male
                          ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.male, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Male',
                      style: TextStyle(
                        fontWeight:
                            _gender == ContactGender.male
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color:
                            _gender == ContactGender.male
                                ? theme.colorScheme.primary
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _gender = ContactGender.female),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:
                      _gender == ContactGender.female ? theme.cardColor : null,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow:
                      _gender == ContactGender.female
                          ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.female, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Female',
                      style: TextStyle(
                        fontWeight:
                            _gender == ContactGender.female
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color:
                            _gender == ContactGender.female
                                ? theme.colorScheme.secondary
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldWithIcon(
    TextEditingController controller,
    String placeholder,
    IconData? icon, {
    bool iconOnLeft = true,
  }) {
    final theme = Theme.of(context);
    final iconWidget =
        icon != null
            ? Icon(icon, color: theme.colorScheme.primary)
            : const SizedBox(width: 24);

    List<Widget> children = [
      Expanded(child: _buildBorderlessTextField(controller, placeholder)),
    ];

    if (iconOnLeft) {
      children.insert(0, iconWidget);
      children.insert(1, const SizedBox(width: 8));
    } else {
      children.add(const SizedBox(width: 8));
      children.add(iconWidget);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  Widget _buildNotesField() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Annotation / Introduction',
          style: TextStyle(fontSize: 12, color: theme.hintColor),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Add a note about this contact...',
              hintStyle: TextStyle(color: theme.hintColor),
            ),
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomFieldsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('contact_customFields'.tr, style: theme.textTheme.titleMedium),
        ..._customFieldControllers.asMap().entries.map((entry) {
          int idx = entry.key;
          var controller = entry.value;
          return Row(
            children: [
              Expanded(
                child: _buildBorderlessTextField(
                  controller.key,
                  'Field Name (e.g., Birthday)',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBorderlessTextField(controller.value, 'Value'),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle, color: theme.colorScheme.error),
                onPressed: () {
                  setState(() {
                    controller.key.dispose();
                    controller.value.dispose();
                    _customFieldControllers.removeAt(idx);
                  });
                },
              ),
            ],
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
          label: Text('contact_addCustomField'.tr),
          onPressed: () {
            setState(() {
              _customFieldControllers.add(
                MapEntry(TextEditingController(), TextEditingController()),
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildCustomEventsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'contact_customActivityEvents'.tr,
          style: theme.textTheme.titleMedium,
        ),
        ..._customEventControllers.asMap().entries.map((entry) {
          int idx = entry.key;
          var controller = entry.value;
          return Row(
            children: [
              _buildColorPickerButton(idx),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBorderlessTextField(controller.key, 'Event Title'),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle, color: theme.colorScheme.error),
                onPressed: () {
                  setState(() {
                    controller.key.dispose();
                    _customEventControllers.removeAt(idx);
                    if (idx < _customActivityEvents.length) {
                      _customActivityEvents.removeAt(idx);
                    }
                  });
                },
              ),
            ],
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
          label: Text('contact_addCustomEvent'.tr),
          onPressed: () {
            setState(() {
              _customEventControllers.add(
                MapEntry(TextEditingController(), theme.colorScheme.primary),
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildColorPickerButton(int index) {
    Color currentColor = _customEventControllers[index].value;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: theme.colorScheme.surface,
                title: Text(
                  'contact_pickColor'.tr,
                  style: theme.textTheme.titleLarge,
                ),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: currentColor,
                    onColorChanged: (color) {
                      setState(() {
                        _customEventControllers[index] = MapEntry(
                          _customEventControllers[index].key,
                          color,
                        );
                      });
                    },
                    pickerAreaHeightPercent: 0.8,
                  ),
                ),
                actions: [
                  TextButton(
                    child: Text(
                      'contact_done'.tr,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
        );
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: currentColor, shape: BoxShape.circle),
      ),
    );
  }
}
