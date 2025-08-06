import 'dart:convert';

/// DockingTabData - Docking标签页数据模型
class DockingTabData {
  final String id;
  String title;
  final DateTime createDate;
  bool needUpdate;
  bool isActive;
  Map<String, dynamic> stored;

  DockingTabData({
    required this.id,
    required this.title,
    required this.createDate,
    this.needUpdate = false,
    this.isActive = false,
    Map<String, dynamic>? stored,
  }) : stored = stored ?? {};

  /// 从Map创建DockingTabData
  factory DockingTabData.fromMap(Map<String, dynamic> map) {
    return DockingTabData(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      createDate: DateTime.tryParse(map['createDate'] ?? '') ?? DateTime.now(),
      needUpdate: map['needUpdate'] ?? false,
      isActive: map['isActive'] ?? false,
      stored: Map<String, dynamic>.from(map['stored'] ?? {}),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createDate': createDate.toIso8601String(),
      'needUpdate': needUpdate,
      'isActive': isActive,
      'stored': stored,
    };
  }

  /// 转换为JSON字符串
  String toJson() => json.encode(toMap());

  /// 从JSON字符串创建DockingTabData
  factory DockingTabData.fromJson(String source) =>
      DockingTabData.fromMap(json.decode(source));

  /// 复制并修改属性
  DockingTabData copyWith({
    String? id,
    String? title,
    DateTime? createDate,
    bool? needUpdate,
    bool? isActive,
    Map<String, dynamic>? stored,
  }) {
    return DockingTabData(
      id: id ?? this.id,
      title: title ?? this.title,
      createDate: createDate ?? this.createDate,
      needUpdate: needUpdate ?? this.needUpdate,
      isActive: isActive ?? this.isActive,
      stored: stored ?? Map<String, dynamic>.from(this.stored),
    );
  }

  @override
  String toString() {
    return 'DockingTabData(id: $id, title: $title, createDate: $createDate, needUpdate: $needUpdate, isActive: $isActive, stored: $stored)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DockingTabData &&
        other.id == id &&
        other.title == title &&
        other.createDate == createDate &&
        other.needUpdate == needUpdate &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        createDate.hashCode ^
        needUpdate.hashCode ^
        isActive.hashCode;
  }
}
