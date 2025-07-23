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
      parentId: map['parent_id']?.toString(),
      color:
          map['color'] != null
              ? Color(int.tryParse(map['color'].toString()) ?? 0)
              : null,
      icon:
          map['icon'] != null
              ? IconData(int.tryParse(map['icon'].toString()) ?? 0)
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'parent_id': parentId,
      // ignore: deprecated_member_use
      'color': color?.value,
      'icon': icon?.codePoint,
    };
  }
}
