class LibraryFolder {
  final String id;
  final String title;
  final String? parentId;
  final String? notes;
  final int color;

  LibraryFolder({
    required this.id,
    required this.title,
    this.parentId,
    this.notes,
    required this.color,
  });

  factory LibraryFolder.fromMap(Map<String, dynamic> map) {
    return LibraryFolder(
      id: map['id'],
      title: map['title'],
      parentId: map['parentId'],
      notes: map['notes'],
      color: map['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'parentId': parentId,
      'notes': notes,
      'color': color,
    };
  }
}
