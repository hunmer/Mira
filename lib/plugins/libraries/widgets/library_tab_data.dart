import 'package:mira/core/utils/utils.dart';
import '../models/library.dart';

class LibraryTabData {
  final Library library;
  final bool isRecycleBin;
  final String tabId;
  bool needUpdate;
  String title;
  final DateTime createDate;
  final Map<String, dynamic> stored;

  LibraryTabData({
    this.title = '',
    required this.tabId,
    this.needUpdate = false,
    required this.library,
    this.isRecycleBin = false,
    required this.createDate,
    required this.stored,
  });

  factory LibraryTabData.fromMap(Map<String, dynamic> map) {
    return LibraryTabData(
      title: map['title'] as String,
      tabId: map['tabId'] as String,
      library: Library.fromMap(map['library']),
      isRecycleBin: map['isRecycleBin'] as bool? ?? false,
      createDate: DateTime.parse(map['create_date'] as String),
      stored: Map<String, dynamic>.from(map['stored'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'tabId': tabId,
      'library': library.toJson(),
      'isRecycleBin': isRecycleBin,
      'create_date': createDate.toIso8601String(),
      'stored': convertSetsToLists(stored),
    };
  }

  LibraryTabData copyWith({
    String? tabId,
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
      title: title ?? this.title,
      tabId: tabId ?? this.tabId,
      library: library ?? this.library,
      needUpdate: needUpdate ?? this.needUpdate,
      isRecycleBin: isRecycleBin ?? this.isRecycleBin,
      createDate: createDate ?? this.createDate,
      stored: stored ?? this.stored,
    );
  }
}
