import 'package:flutter/material.dart';
import '../controllers/database_controller.dart';
import '../models/database_model.dart';
import '../models/record.dart' as record_model;
import 'database_edit_widget.dart';
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
          final newRecord = record_model.Record(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            tableId: database.id,
            fields: {},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await widget.controller.createRecord(newRecord);
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListView(DatabaseModel database) {
    return FutureBuilder<List<record_model.Record>>(
      future:
          widget.controller.getRecords(database.id)
              as Future<List<record_model.Record>>,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return ListTile(
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
            );
          },
        );
      },
    );
  }

  Widget _buildGridView(DatabaseModel database) {
    return FutureBuilder<List<record_model.Record>>(
      future:
          widget.controller.getRecords(database.id)
              as Future<List<record_model.Record>>,
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
}
