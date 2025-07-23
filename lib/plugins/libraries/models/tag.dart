import 'package:flutter/widgets.dart';

class LibraryTag {
  final String id;
  final String title;
  final String? parentId;
  final Color? color;
  final IconData? icon;

  LibraryTag({
    required this.id,
    required this.title,
    this.parentId,
    this.icon,
    required this.color,
  });

  factory LibraryTag.fromMap(Map<String, dynamic> map) {
    return LibraryTag(
      id: map['id'].toString(),
      title: map['title'],
      parentId: map['parent_id']?.toString(),
      color: map['color'] != null ? Color(map['color']) : null,
      icon: map['icon'] != null ? IconData(map['icon']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'parent_id': parentId,
      'color': color,
      'icon': icon,
    };
  }
}
