import 'package:Memento/plugins/database/controllers/database_controller.dart';
import 'package:Memento/plugins/database/widgets/database_detail_widget.dart';
import 'package:flutter/material.dart';
import '../models/database_model.dart';
import '../services/database_service.dart';

class DatabaseListWidget extends StatefulWidget {
  final DatabaseService service;

  const DatabaseListWidget({super.key, required this.service});

  @override
  State<DatabaseListWidget> createState() => _DatabaseListWidgetState();
}

class _DatabaseListWidgetState extends State<DatabaseListWidget> {
  late Future<List<DatabaseModel>> _databasesFuture;

  @override
  void initState() {
    super.initState();
    _databasesFuture = widget.service.getAllDatabases();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DatabaseModel>>(
      future: _databasesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final databases = snapshot.data ?? [];

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: databases.length,
          itemBuilder: (context, index) {
            final database = databases[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => DatabaseDetailWidget(
                            controller: DatabaseController(widget.service),
                            databaseId: database.id,
                          ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child:
                          database.coverImagePath != null
                              ? Image.asset(
                                database.coverImagePath!,
                                fit: BoxFit.cover,
                              )
                              : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.cloud, size: 48),
                              ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        database.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
