import 'package:flutter/foundation.dart';

class CompletionRecord {
  final String id;
  final String parentId;
  final DateTime date;
  final Duration duration;
  final String notes;

  CompletionRecord({
    required this.id,
    required this.parentId,
    required this.date,
    required this.duration,
    required this.notes,
  });

  factory CompletionRecord.fromMap(Map<String, dynamic> map) {
    return CompletionRecord(
      id: map['id'] as String,
      parentId: map['parentId'] as String,
      date: DateTime.parse(map['date'] as String),
      duration: Duration(seconds: map['duration'] as int),
      notes: map['notes'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'date': date.toIso8601String(),
      'duration': duration.inSeconds,
      'notes': notes,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletionRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
