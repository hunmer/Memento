import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/notes/controllers/notes_controller.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/plugins/notes/widgets/search_note_item.dart';

class SearchScreen extends StatefulWidget {
  final NotesController controller;

  const SearchScreen({super.key, required this.controller});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Note> _searchResults = [];
  List<String> _selectedTags = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _query = '';
      });
      return;
    }

    setState(() {
      _query = query;
      _searchResults = widget.controller.searchNotes(
        query: query,
        tags: _selectedTags.isEmpty ? null : _selectedTags,
        startDate: _startDate,
        endDate: _endDate,
      );
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('notes_filter'.tr),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('notes_tags'.tr),
                  Wrap(
                    spacing: 8,
                    children: [
                      // This is a simplified version. In a real app, you'd fetch all available tags.
                      _buildTagChip('Work'),
                      _buildTagChip('Personal'),
                      _buildTagChip('Ideas'),
                      _buildTagChip('Important'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('notes_dateRange'.tr),
                  ListTile(
                    title: Text(
                      _startDate != null
                          ? 'From: ${_formatDate(_startDate!)}'
                          : 'notes_typeToSearch'.tr,
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                        _onSearchChanged();
                      }
                    },
                  ),
                  ListTile(
                    title: Text(
                      _endDate != null
                          ? 'To: ${_formatDate(_endDate!)}'
                          : 'notes_typeToSearch'.tr,
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                        _onSearchChanged();
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTags = [];
                    _startDate = null;
                    _endDate = null;
                  });
                  _onSearchChanged();
                  Navigator.pop(context);
                },
                child: Text('notes_clearAll'.tr),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('notes_apply'.tr),
              ),
            ],
          ),
    );
  }

  Widget _buildTagChip(String tag) {
    final isSelected = _selectedTags.contains(tag);
    return FilterChip(
      label: Text(tag),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTags.add(tag);
          } else {
            _selectedTags.remove(tag);
          }
        });
        _onSearchChanged();
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'notes_searchHint'.tr,
            border: InputBorder.none,
          ),
          autofocus: true,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body:
          _searchResults.isEmpty
              ? Center(
                child:
                    _query.isEmpty
                        ? Text('notes_typeToSearch'.tr)
                        : Text('notes_noResultsFound'.tr),
              )
              : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final note = _searchResults[index];
                  final folder = widget.controller.getFolder(note.folderId);
                  return SearchNoteItem(
                    note: note,
                    folderName:
                        folder?.name ??
                        'notes_noResultsFound'.tr,
                    query: _query,
                  );
                },
              ),
    );
  }
}
