class LibraryTag {
  final String id;
  final String title;
  final String? parentId;
  final String? notes;
  final int color;

  LibraryTag({
    required this.id,
    required this.title,
    this.parentId,
    this.notes,
    required this.color,
  });

  factory LibraryTag.fromMap(Map<String, dynamic> map) {
    return LibraryTag(
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
