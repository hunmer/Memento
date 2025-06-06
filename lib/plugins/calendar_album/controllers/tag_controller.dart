import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/storage/storage_manager.dart';

class Tag {
  final String id;
  final String name;
  final Color color;

  Tag({required this.id, required this.name, Color? color})
    : color = color ?? Colors.grey;

  factory Tag.create({required String name, Color? color}) {
    return Tag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: color,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'color': color.value};
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      color: json.containsKey('color') ? Color(json['color']) : null,
    );
  }
}

class TagController extends ChangeNotifier {
  final StorageManager _storage;
  List<Tag> _tags = [];
  final String _storageKey = 'calendar_tags';

  TagController(this._storage) {
    _loadTags();
  }

  List<Tag> get tags => _tags;

  Future<void> _loadTags() async {
    final String? data = await _storage.getString(_storageKey);
    if (data != null) {
      final List<dynamic> jsonData = json.decode(data);
      _tags =
          jsonData.map((e) => Tag.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveTags() async {
    final List<Map<String, dynamic>> data =
        _tags.map((tag) => tag.toJson()).toList();
    await _storage.setString(_storageKey, json.encode(data));
  }

  Future<void> addTag(Tag tag) async {
    _tags.add(tag);
    await _saveTags();
    notifyListeners();
  }

  Future<void> updateTag(Tag tag) async {
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index != -1) {
      _tags[index] = tag;
      await _saveTags();
      notifyListeners();
    }
  }

  Future<void> deleteTag(String id) async {
    _tags.removeWhere((tag) => tag.id == id);
    await _saveTags();
    notifyListeners();
  }

  Tag? getTagByName(String name) {
    try {
      return _tags.firstWhere((tag) => tag.name == name);
    } catch (e) {
      return null;
    }
  }
}
