import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/contact/models/interaction_record_model.dart';
import 'package:Memento/plugins/contact/models/contact_model.dart';
import 'package:Memento/plugins/contact/controllers/contact_controller.dart';
import 'contact_selector.dart';

class InteractionForm extends StatefulWidget {
  final String contactId;
  final InteractionRecord? interaction;
  final Function(InteractionRecord) onSave;
  final ContactController controller;

  const InteractionForm({
    super.key,
    required this.contactId,
    this.interaction,
    required this.onSave,
    required this.controller,
  });

  @override
  State<InteractionForm> createState() => _InteractionFormState();
}

class _InteractionFormState extends State<InteractionForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TextEditingController _notesController;
  List<String> _selectedParticipantIds = [];
  List<Contact> _participants = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.interaction?.date ?? DateTime.now();
    _notesController = TextEditingController(
      text: widget.interaction?.notes ?? '',
    );
    _selectedParticipantIds = widget.interaction?.participants ?? [];
    _loadParticipants();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    if (_selectedParticipantIds.isEmpty) return;

    final List<Contact> participants = [];
    for (final id in _selectedParticipantIds) {
      final contact = await widget.controller.getContact(id);
      if (contact != null) {
        participants.add(contact);
      }
    }

    setState(() {
      _participants = participants;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _showContactSelector() async {
    await showDialog(
      context: context,
      builder:
          (context) => ContactSelector(
            controller: widget.controller,
            selectedContactIds: _selectedParticipantIds,
            onContactsSelected: (selectedIds) {
              setState(() {
                _selectedParticipantIds = selectedIds;
                _loadParticipants();
              });
            },
            excludeContactId: widget.contactId,
          ),
    );
  }

  void _removeParticipant(String id) {
    setState(() {
      _selectedParticipantIds.remove(id);
      _participants.removeWhere((contact) => contact.id == id);
    });
  }

  void _saveInteraction() {
    if (_formKey.currentState!.validate()) {
      final interaction = InteractionRecord(
        id: widget.interaction?.id ?? const Uuid().v4(),
        contactId: widget.contactId,
        date: _selectedDate,
        notes: _notesController.text,
        participants: _selectedParticipantIds,
      );

      widget.onSave(interaction);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.interaction == null ? '添加联系记录' : '编辑联系记录',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // 日期和时间选择
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'contact_dateLabel'.tr,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'contact_timeLabel'.tr,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        child: Text(
                          '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 备注输入
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'contact_notes'.tr,
                  border: const OutlineInputBorder(),
                  hintText: 'contact_notesHint'.tr,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // 其他参与者
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'contact_otherParticipants'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: _showContactSelector,
                    tooltip:
                        'contact_addParticipantTooltip'.tr,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_participants.isNotEmpty)
                ContactChips(
                  contacts: _participants,
                  onDelete: _removeParticipant,
                ),

              const SizedBox(height: 24),

              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveInteraction,
                    child: Text(AppLocalizations.of(context)!.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
