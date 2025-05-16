import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../controllers/contact_controller.dart';

class ContactSelector extends StatefulWidget {
  final List<String> selectedContactIds;
  final Function(List<String>) onContactsSelected;
  final String? excludeContactId; // 可选排除的联系人ID，通常是当前联系人
  final ContactController controller;

  const ContactSelector({
    Key? key,
    required this.selectedContactIds,
    required this.onContactsSelected,
    required this.controller,
    this.excludeContactId,
  }) : super(key: key);

  @override
  State<ContactSelector> createState() => _ContactSelectorState();
}

class _ContactSelectorState extends State<ContactSelector> {
  List<Contact> _contacts = [];
  List<String> _selectedIds = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedContactIds);
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await widget.controller.getAllContacts();
    
    // 排除当前联系人
    if (widget.excludeContactId != null) {
      contacts.removeWhere((contact) => contact.id == widget.excludeContactId);
    }
    
    setState(() {
      _contacts = contacts;
    });
  }

  List<Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return _contacts;
    }
    return _contacts.where((contact) => 
      contact.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 300,
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '选择联系人',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索联系人...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  final isSelected = _selectedIds.contains(contact.id);
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: contact.iconColor,
                      child: Icon(contact.icon, color: Colors.white),
                    ),
                    title: Text(contact.name),
                    subtitle: Text(contact.phone),
                    trailing: isSelected 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.circle_outlined),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedIds.remove(contact.id);
                        } else {
                          _selectedIds.add(contact.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onContactsSelected(_selectedIds);
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 联系人标签展示组件
class ContactChips extends StatelessWidget {
  final List<Contact> contacts;
  final Function(String)? onDelete;

  const ContactChips({
    Key? key,
    required this.contacts,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: contacts.map((contact) {
        return Chip(
          avatar: CircleAvatar(
            backgroundColor: contact.iconColor,
            child: Icon(contact.icon, color: Colors.white, size: 16),
          ),
          label: Text(contact.name),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: onDelete != null ? () => onDelete!(contact.id) : null,
        );
      }).toList(),
    );
  }
}