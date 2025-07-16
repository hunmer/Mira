class Library {
  final String id;
  final String name;
  final String icon;
  final String type;
  final Map<String, dynamic> customFields;
  final DateTime createdAt;

  Library({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    required this.customFields,
    required this.createdAt,
  });

  // 从Map转换
  factory Library.fromMap(Map<String, dynamic> map) {
    return Library(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      type: map['type'],
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'type': type,
      'customFields': customFields,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // 转换为JSON
  Map<String, dynamic> toJson() => toMap();
  // 从JSON转换
  factory Library.fromJson(Map<String, dynamic> json) => Library.fromMap(json);
}
