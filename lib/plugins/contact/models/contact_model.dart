import 'package:flutter/material.dart';

enum ContactGender {
  male,
  female,
  other,
}

class Contact {
  final String id;
  final String name;
  final String? avatar;
  final IconData icon;
  final Color iconColor;
  final String phone;
  final String? address;
  final String? notes;
  final List<String> tags;
  final Map<String, String> customFields;
  final DateTime createdTime;
  final DateTime lastContactTime;
  final ContactGender? gender;

  Contact({
    required this.id,
    required this.name,
    this.avatar,
    required this.icon,
    required this.iconColor,
    required this.phone,
    this.address,
    this.notes,
    this.gender,
    List<String>? tags,
    Map<String, String>? customFields,
    DateTime? createdTime,
    DateTime? lastContactTime,
  })  : tags = tags ?? [],
        customFields = customFields ?? {},
        createdTime = createdTime ?? DateTime.now(),
        lastContactTime = lastContactTime ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'icon': icon.codePoint,
      // ignore: deprecated_member_use
      'iconColor': iconColor.value,
      'phone': phone,
      'address': address,
      'notes': notes,
      'gender': gender?.name,
      'tags': tags,
      'customFields': customFields,
      'createdTime': createdTime.toIso8601String(),
      'lastContactTime': lastContactTime.toIso8601String(),
    };
  }

  factory Contact.fromJson(Map json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      iconColor: Color(json['iconColor'] as int),
      phone: json['phone'] as String,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      gender: json['gender'] != null
          ? ContactGender.values.firstWhere(
              (e) => e.name == json['gender'],
              orElse: () => ContactGender.other,
            )
          : null,
      tags: List<String>.from(json['tags'] as List),
      customFields: Map<String, String>.from(json['customFields'] as Map),
      createdTime: DateTime.parse(json['createdTime'] as String),
      lastContactTime: DateTime.parse(json['lastContactTime'] as String),
    );
  }

  factory Contact.empty() {
    return Contact(
      id: '',
      name: '',
      icon: IconData(Icons.person.codePoint, fontFamily: 'MaterialIcons'),
      iconColor: Colors.grey,
      phone: '',
    );
  }

  Contact copyWith({
    String? name,
    String? avatar,
    IconData? icon,
    Color? iconColor,
    String? phone,
    String? address,
    String? notes,
    ContactGender? gender,
    List<String>? tags,
    Map<String, String>? customFields,
    DateTime? lastContactTime,
  }) {
    return Contact(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      gender: gender ?? this.gender,
      tags: tags ?? List.from(this.tags),
      customFields: customFields ?? Map.from(this.customFields),
      createdTime: createdTime,
      lastContactTime: lastContactTime ?? this.lastContactTime,
    );
  }
}
