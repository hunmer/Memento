import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/contact/l10n/contact_localizations.dart';
import 'package:flutter/material.dart';
import '../base_plugin.dart';

import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'controllers/contact_controller.dart';
import 'models/contact_model.dart';
import 'models/filter_sort_config.dart';
import 'widgets/contact_card.dart';
import 'widgets/contact_form.dart';
import 'widgets/filter_dialog.dart';

class ContactPlugin extends BasePlugin {
  late ContactController _controller;
  @override
  String get id => 'contact';

  @override
  Color get color => Colors.deepPurple;

  @override
  IconData get icon => Icons.contacts;

  @override
  Future<void> initialize() async {
    _controller = ContactController(this);
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return ContactMainView();
  }

  @override
  String? getPluginName(context) {
    return ContactLocalizations.of(context).name;
  }

  @override
  Widget buildCardView(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCardStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        final theme = Theme.of(context);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部图标和标题
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ContactLocalizations.of(context).name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 统计信息
              Column(
                children: [
                  // 联系人统计
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 总联系人
                      Column(
                        children: [
                          Text(
                            ContactLocalizations.of(context).totalContacts,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${stats['totalContacts']}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),

                      // 最近联系人
                      Column(
                        children: [
                          Text(
                            ContactLocalizations.of(context).recentContacts,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${stats['recentContacts']}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getCardStats() async {
    final contacts = await _controller.getAllContacts();
    final recentContacts = await _controller.getRecentlyContactedCount();
    return {'totalContacts': contacts.length, 'recentContacts': recentContacts};
  }
}

class ContactMainView extends StatefulWidget {
  const ContactMainView({super.key});

  @override
  State<ContactMainView> createState() => ContactMainViewState();
}

class ContactMainViewState extends State<ContactMainView> {
  late ContactPlugin _plugin;
  late ContactController _controller;
  bool _isListView = false;

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager().getPlugin('contact') as ContactPlugin;
    _controller = _plugin._controller;
  }

  Future<void> _showFilterDialog() async {
    final currentFilter = await _controller.getFilterConfig();
    final tags = await _controller.getAllTags();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder:
          (context) => FilterDialog(
            initialFilter: currentFilter,
            availableTags: tags,
            onApply: (filter) async {
              await _controller.saveFilterConfig(filter);
              if (mounted) {
                setState(() {});
              }
            },
          ),
    );
  }

  Future<void> _showSortMenu() async {
    final currentSort = await _controller.getSortConfig();

    if (!mounted) return;

    final result = await showDialog<SortConfig>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text(ContactLocalizations.of(context).sortBy),
            children: [
              for (final type in SortType.values)
                RadioListTile<SortType>(
                  title: Text(_getSortTypeName(type)),
                  value: type,
                  groupValue: currentSort.type,
                  onChanged: (value) {
                    Navigator.pop(
                      context,
                      SortConfig(
                        type: value!,
                        isReverse:
                            type == currentSort.type
                                ? !currentSort.isReverse
                                : false,
                      ),
                    );
                  },
                  secondary:
                      type == currentSort.type
                          ? Icon(
                            currentSort.isReverse
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          )
                          : null,
                ),
            ],
          ),
    );

    if (result != null) {
      await _controller.saveSortConfig(result);
      setState(() {});
    }
  }

  String _getSortTypeName(SortType type) {
    switch (type) {
      case SortType.name:
        return ContactLocalizations.of(context).name;
      case SortType.createdTime:
        return ContactLocalizations.of(context).createdTime;
      case SortType.lastContactTime:
        return ContactLocalizations.of(context).lastContactTime;
      case SortType.contactCount:
        return ContactLocalizations.of(context).contactCount;
    }
  }

  Future<void> _addOrEditContact([Contact? contact]) async {
    final formStateKey = GlobalKey<ContactFormState>();
    Contact? savedContact;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(
                  contact == null
                      ? ContactLocalizations.of(context).addContact
                      : ContactLocalizations.of(context).editContact,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () async {
                      // 调用表单的保存方法
                      formStateKey.currentState?.saveContact();
                      if (savedContact != null) {
                        try {
                          if (contact == null) {
                            await _controller.addContact(savedContact!);
                          } else {
                            await _controller.updateContact(savedContact!);
                          }
                          if (mounted) {
                            Navigator.of(context).pop();
                            setState(() {});
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ContactLocalizations.of(
                                        context,
                                      )?.saveFailedMessage ??
                                      'Save failed',
                                ),
                              ),
                            );
                          }
                        }
                      } else {
                        // 如果 savedContact 为 null，可能是表单验证失败
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ContactLocalizations.of(
                                context,
                              ).formValidationMessage,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  if (contact != null)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteContact(contact),
                    ),
                ],
              ),
              body: ContactForm(
                key: formStateKey,
                formStateKey: formStateKey,
                controller: _controller,
                contact: contact,
                onSave: (updatedContact) {
                  savedContact = updatedContact;
                },
              ),
            ),
      ),
    );
  }

  Future<void> _deleteContact(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(ContactLocalizations.of(context).confirmDelete),
            content: Text(
              ContactLocalizations.of(context).deleteConfirmMessage,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.no),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.yes),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      await _controller.deleteContact(contact.id);
      Navigator.pop(context);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        title: Text(ContactLocalizations.of(context)!.contacts),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(icon: const Icon(Icons.sort), onPressed: _showSortMenu),
          IconButton(
            icon: Icon(_isListView ? Icons.grid_view : Icons.list),
            onPressed: () {
              setState(() {
                _isListView = !_isListView;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Contact>>(
        future: _controller.getFilteredAndSortedContacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(ContactLocalizations.of(context)!.errorMessage),
            );
          }

          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ContactLocalizations.of(context)!.noContacts,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (_isListView) {
            return ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                return ContactCard(
                  contact: contacts[index],
                  onTap: () => _addOrEditContact(contacts[index]),
                  isListView: true,
                );
              },
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
            ),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              return ContactCard(
                contact: contacts[index],
                onTap: () => _addOrEditContact(contacts[index]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditContact(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
