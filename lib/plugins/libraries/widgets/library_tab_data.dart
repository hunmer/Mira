import 'package:mira/core/utils/utils.dart';
import '../models/library.dart';

class LibraryTabData {
  final String id;
  final Library library;
  final bool isPinned;
  final bool isRecycleBin;
  bool isActive;
  bool needUpdate;
  String title;
  final DateTime createDate;
  final Map<String, dynamic> stored;

  LibraryTabData({
    this.title = '',
    this.isActive = false,
    this.needUpdate = false,
    required this.id,
    required this.library,
    this.isPinned = false,
    this.isRecycleBin = false,
    required this.createDate,
    required this.stored,
  });

  factory LibraryTabData.fromMap(Map<String, dynamic> map) {
    return LibraryTabData(
      id: map['id'] as String,
      title: map['title'] as String,
      library: Library.fromMap(map['library']),
      isActive: map['isActive'] as bool? ?? false,
      isPinned: map['isPinned'] as bool? ?? false,
      isRecycleBin: map['isRecycleBin'] as bool? ?? false,
      createDate: DateTime.parse(map['create_date'] as String),
      stored: Map<String, dynamic>.from(map['stored'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'library': library.toJson(),
      'isActive': isActive,
      'isPinned': isPinned,
      'isRecycleBin': isRecycleBin,
      'create_date': createDate.toIso8601String(),
      'stored': convertSetsToLists(stored),
    };
  }

  LibraryTabData copyWith({
    String? id,
    String? title,
    Library? library,
    bool? needUpdate,
    bool? isActive,
    bool? isPinned,
    bool? isRecycleBin,
    DateTime? createDate,
    Map<String, dynamic>? stored,
  }) {
    return LibraryTabData(
      id: id ?? this.id,
      title: title ?? this.title,
      library: library ?? this.library,
      needUpdate: needUpdate ?? this.needUpdate,
      isPinned: isPinned ?? this.isPinned,
      isActive: isActive ?? this.isActive,
      isRecycleBin: isRecycleBin ?? this.isRecycleBin,
      createDate: createDate ?? this.createDate,
      stored: stored ?? this.stored,
    );
  }
}
