import 'package:flutter/widgets.dart';

class LibraryFolder {
  final String id;
  final String title;
  final String? parentId;
  final Color? color;
  final IconData? icon;

  LibraryFolder({
    required this.id,
    required this.title,
    this.parentId,
    this.icon,
    required this.color,
  });

  factory LibraryFolder.fromMap(Map<String, dynamic> map) {
    return LibraryFolder(
      id: map['id'].toString(),
      title: map['title'],
      parentId: map['parentId'],
      color: map['color'] != null ? Color(int.parse(map['color'])) : null,
      icon: map['icon'] != null ? IconData(int.parse(map['icon'])) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'parentId': parentId,
      'color': color,
      'icon': icon,
    };
  }
}
