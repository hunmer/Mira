import 'dart:convert';

import 'package:mira/core/utils/utils.dart';

class LibraryFile {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime importedAt;
  final int size;
  final String hash;
  final Map<String, dynamic> customFields;
  final String? notes;
  final int? rating;
  final List<String> tags;
  final String folderId;
  final String? reference;
  final String? url;
  final String? path;
  final String? thumb;

  LibraryFile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.importedAt,
    required this.size,
    required this.hash,
    required this.customFields,
    this.notes,
    this.rating,
    required this.tags,
    required this.folderId,
    this.reference,
    this.url,
    this.path,
    this.thumb,
  });

  String get fileType => getFileType(name).toLowerCase();

  factory LibraryFile.fromMap(Map<String, dynamic> map) {
    // 处理用户提供的JSON格式
    final createdAt =
        map['created_at'] is int
            ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
            : DateTime.parse(map['createdAt'] ?? '1970-01-01');

    final importedAt =
        map['imported_at'] is int
            ? DateTime.fromMillisecondsSinceEpoch(map['imported_at'])
            : DateTime.parse(map['importedAt'] ?? '1970-01-01');

    return LibraryFile(
      id: map['id'],
      name: map['name'] ?? '',
      createdAt: createdAt,
      importedAt: importedAt,
      size:
          map['size'] is int
              ? map['size']
              : int.tryParse(map['size']?.toString() ?? '0') ?? 0,
      hash: map['hash'] ?? '',
      customFields: Map<String, dynamic>.from(
        map['customFields'] ?? map['custom_fields'] is String
            ? jsonDecode(map['customFields'] ?? map['custom_fields'] ?? '{}')
            : map['customFields'] ?? map['custom_fields'] ?? {},
      ),
      notes: map['notes'],
      rating: map['rating'] ?? map['stars'] ?? 0,
      tags: List<String>.from(jsonDecode(map['tags'] ?? '[]')),
      folderId: map['folderId'] ?? map['folder_id']?.toString() ?? '',
      reference: map['reference'],
      url: map['url'],
      path: map['path'] ?? '',
      thumb: map['thumb'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'importedAt': importedAt.toIso8601String(),
      'size': size,
      'hash': hash,
      'customFields': customFields,
      'notes': notes,
      'rating': rating,
      'tags': tags,
      'folderId': folderId,
      'reference': reference,
      'url': url,
      'path': path,
      'thumb': thumb,
    };
  }
}
