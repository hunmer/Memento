import 'package:Memento/plugins/database/widgets/record_edit_widget.dart';
import 'package:flutter/material.dart';
import '../controllers/database_controller.dart';
import '../models/database_model.dart';
import '../widgets/database_edit_widget.dart';
import '../models/record.dart' as record_model;
import 'record_detail_widget.dart';

class DatabaseDetailWidget extends StatefulWidget {
  final DatabaseController controller;
  final String databaseId;

  const DatabaseDetailWidget({
    super.key,
    required this.controller,
    required this.databaseId,
  });

  @override
  State<DatabaseDetailWidget> createState() => _DatabaseDetailWidgetState();
}

class _DatabaseDetailWidgetState extends State<DatabaseDetailWidget> {
  late Future<void> _loadingFuture;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadingFuture = widget.controller.loadDatabase(widget.databaseId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (widget.controller.currentDatabase == null) {
          return const Center(child: Text('Database not found'));
        }

        final database = widget.controller.currentDatabase!;
        return _buildContent(database);
      },
    );
  }

  Widget _buildContent(DatabaseModel database) {
    return Scaffold(
      appBar: AppBar(
        title: Text(database.name),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder:
                          (context) => DatabaseEditWidget(
                            controller: widget.controller,
                            database: database,
                          ),
                    ),
                  )
                  .then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: _isGridView ? _buildGridView(database) : _buildListView(database),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => RecordEditWidget(
                    controller: widget.controller,
                    database: database,
                    record: null, // 新增记录时传null
                  ),
            ),
          );
          if (result != null) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListView(DatabaseModel database) {
    return FutureBuilder<List<record_model.Record>>(
      future: widget.controller.getRecords(database.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Dismissible(
              key: Key(record.id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await _confirmDelete(context, record);
              },
              onDismissed: (direction) {
                _deleteRecord(record);
              },
              child: ListTile(
                title: Text(record.fields['title']?.toString() ?? 'Untitled'),
                subtitle: Text(record.updatedAt.toString()),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => RecordDetailWidget(
                            record: record,
                            controller: widget.controller,
                          ),
                    ),
                  );
                },
                onLongPress: () {
                  _showRecordMenu(context, record);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridView(DatabaseModel database) {
    return FutureBuilder<List<record_model.Record>>(
      future: widget.controller.getRecords(database.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Card(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => RecordDetailWidget(
                            record: record,
                            controller: widget.controller,
                          ),
                    ),
                  );
                },
                onLongPress: () {
                  _showRecordMenu(context, record);
                },
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (record.fields['image'] != null)
                        Image.network(record.fields['image'], height: 80),
                      Text(record.fields['title']?.toString() ?? 'Untitled'),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    record_model.Record record,
  ) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Record'),
            content: Text(
              'Are you sure you want to delete "${record.fields['title'] ?? 'Untitled'}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    ).then((value) => value ?? false);
  }

  Future<void> _deleteRecord(record_model.Record record) async {
    await widget.controller.deleteRecord(record.id);
    setState(() {});
  }

  void _showRecordMenu(BuildContext context, record_model.Record record) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.of(context).pop();
                _editRecord(context, record);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.of(context).pop();
                final shouldDelete = await _confirmDelete(context, record);
                if (shouldDelete) {
                  await _deleteRecord(record);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _editRecord(BuildContext context, record_model.Record record) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) => RecordEditWidget(
                  controller: widget.controller,
                  database: widget.controller.currentDatabase!,
                  record: record,
                ),
          ),
        )
        .then((_) => setState(() {}));
  }
}
