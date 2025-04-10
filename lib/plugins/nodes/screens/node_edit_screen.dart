import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/nodes_controller.dart';
import '../models/node.dart';
import '../l10n/nodes_localizations.dart';

class NodeEditScreen extends StatefulWidget {
  final String notebookId;
  final Node node;
  final bool isNew;

  const NodeEditScreen({
    Key? key,
    required this.notebookId,
    required this.node,
    this.isNew = false,
  }) : super(key: key);

  @override
  _NodeEditScreenState createState() => _NodeEditScreenState();
}

class _NodeEditScreenState extends State<NodeEditScreen> {
  late TextEditingController _titleController;
  late List<String> _tags;
  late NodeStatus _status;
  DateTime? _startDate;
  DateTime? _endDate;
  late List<CustomField> _customFields;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.node.title);
    _tags = List.from(widget.node.tags);
    _status = widget.node.status;
    _startDate = widget.node.startDate;
    _endDate = widget.node.endDate;
    _customFields = List.from(widget.node.customFields);
    _notesController = TextEditingController(text: widget.node.notes);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = NodesLocalizations.of(context);
    final controller = Provider.of<NodesController>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isNew ? l10n.addNode : l10n.editNode),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _saveNode(context, controller),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Node path (breadcrumbs)
            if (!widget.isNew) ...[
              Wrap(
                spacing: 8,
                children: controller
                    .getNodePath(widget.notebookId, widget.node.id)
                    .map((title) => Chip(label: Text(title)))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.nodeTitle,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            Wrap(
              spacing: 8,
              children: [
                ..._tags.map(
                  (tag) => Chip(
                    label: Text(tag),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  ),
                ),
                ActionChip(
                  label: const Icon(Icons.add, size: 20),
                  onPressed: () => _showAddTagDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<NodeStatus>(
              value: _status,
              decoration: InputDecoration(
                labelText: l10n.status,
                border: const OutlineInputBorder(),
              ),
              items: NodeStatus.values.map((status) {
                String label;
                switch (status) {
                  case NodeStatus.todo:
                    label = l10n.todo;
                    break;
                  case NodeStatus.doing:
                    label = l10n.doing;
                    break;
                  case NodeStatus.done:
                    label = l10n.done;
                    break;
                }
                return DropdownMenuItem(
                  value: status,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Dates
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_startDate != null
                        ? _startDate!.toString().split(' ')[0]
                        : l10n.startDate),
                    onPressed: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_endDate != null
                        ? _endDate!.toString().split(' ')[0]
                        : l10n.endDate),
                    onPressed: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Custom fields
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(l10n.customFields),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddCustomFieldDialog(context),
                    ),
                  ),
                  if (_customFields.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _customFields.length,
                      itemBuilder: (context, index) {
                        final field = _customFields[index];
                        return ListTile(
                          title: Text(field.key),
                          subtitle: Text(field.value),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _customFields.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.notes,
                border: const OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTagDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Tag',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(NodesLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                setState(() {
                  _tags.add(textController.text);
                });
                Navigator.pop(context);
              }
            },
            child: Text(NodesLocalizations.of(context).save),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showAddCustomFieldDialog(BuildContext context) {
    final keyController = TextEditingController();
    final valueController = TextEditingController();
    final l10n = NodesLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addCustomField),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: InputDecoration(
                labelText: l10n.key,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: valueController,
              decoration: InputDecoration(
                labelText: l10n.value,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (keyController.text.isNotEmpty && valueController.text.isNotEmpty) {
                setState(() {
                  _customFields.add(CustomField(
                    key: keyController.text,
                    value: valueController.text,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _saveNode(BuildContext context, NodesController controller) {
    final updatedNode = Node(
      id: widget.node.id,
      title: _titleController.text,
      createdAt: widget.node.createdAt,
      tags: _tags,
      status: _status,
      startDate: _startDate,
      endDate: _endDate,
      customFields: _customFields,
      notes: _notesController.text,
      parentId: widget.node.parentId,
      children: widget.node.children,
    );

    if (widget.isNew) {
      controller.addNode(widget.notebookId, updatedNode, parentId: widget.node.parentId);
    } else {
      controller.updateNode(widget.notebookId, updatedNode);
    }

    Navigator.pop(context);
  }
}