class LibraryFile {
  final String id;
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
  });

  factory LibraryFile.fromMap(Map<String, dynamic> map) {
    return LibraryFile(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
      importedAt: DateTime.parse(map['importedAt']),
      size: map['size'],
      hash: map['hash'],
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      notes: map['notes'],
      rating: map['rating'],
      tags: List<String>.from(map['tags'] ?? []),
      folderId: map['folderId'],
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
    };
  }
}
