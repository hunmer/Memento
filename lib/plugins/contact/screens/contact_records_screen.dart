import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/contact/models/contact_model.dart';
import 'package:Memento/plugins/contact/models/interaction_record_model.dart';
import 'package:Memento/plugins/contact/controllers/contact_controller.dart';
import 'package:Memento/plugins/contact/widgets/interaction_form.dart';

class ContactRecordsScreen extends StatefulWidget {
  final Contact contact;
  final ContactController controller;

  const ContactRecordsScreen({
    super.key,
    required this.contact,
    required this.controller,
  });

  @override
  State<ContactRecordsScreen> createState() => _ContactRecordsScreenState();
}

class _ContactRecordsScreenState extends State<ContactRecordsScreen> {
  List<InteractionRecord> _interactions = [];

  @override
  void initState() {
    super.initState();
    _loadInteractions();
  }

  Future<void> _loadInteractions() async {
    final interactions = await widget.controller.getInteractionsByContactId(
      widget.contact.id,
    );
    setState(() {
      _interactions = interactions;
    });
  }

  void _addInteraction() async {
    final result = await showDialog<InteractionRecord>(
      context: context,
      builder: (context) => InteractionForm(
        contactId: widget.contact.id,
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
      builder: (context) => AlertDialog(
        title: Text('app_confirmDelete'.tr),
        content: Text(
          'contact_deleteConfirmMessage'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('app_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('app_delete'.tr),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('contact_recordsTab'.tr),
      ),
      body: Stack(
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
    );
  }
}
