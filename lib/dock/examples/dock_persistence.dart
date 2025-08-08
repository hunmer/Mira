import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dock_item_registry.dart';

/// 持久化数据模型
class DockPersistenceData {
  final String layout;
  final List<DockItemData> items;
  final int? selectedTabIndex;
  final String? maximizedAreaId;

  DockPersistenceData({
    required this.layout,
    required this.items,
    this.selectedTabIndex,
    this.maximizedAreaId,
  });

  Map<String, dynamic> toJson() => {
    'layout': layout,
    'items': items.map((e) => e.toJson()).toList(),
    if (selectedTabIndex != null) 'selectedTabIndex': selectedTabIndex,
    if (maximizedAreaId != null) 'maximizedAreaId': maximizedAreaId,
  };

  factory DockPersistenceData.fromJson(Map<String, dynamic> json) {
    return DockPersistenceData(
      layout: json['layout'] as String,
      items:
          (json['items'] as List)
              .map((e) => DockItemData.fromJson(e as Map<String, dynamic>))
              .toList(),
      selectedTabIndex: json['selectedTabIndex'] as int?,
      maximizedAreaId: json['maximizedAreaId'] as String?,
    );
  }
}

/// 持久化管理器
class DockPersistence {
  static Future<String> _getFilePath(String managerId) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/dock_$managerId.json';
  }

  /// 保存布局和数据
  static Future<void> save(String managerId, DockPersistenceData data) async {
    try {
      final file = File(await _getFilePath(managerId));
      await file.writeAsString(jsonEncode(data.toJson()));
    } catch (e) {
      print('Failed to save dock data: $e');
    }
  }

  /// 加载布局和数据
  static Future<DockPersistenceData?> load(String managerId) async {
    try {
      final file = File(await _getFilePath(managerId));
      if (await file.exists()) {
        final content = await file.readAsString();
        return DockPersistenceData.fromJson(jsonDecode(content));
      }
    } catch (e) {
      print('Failed to load dock data: $e');
    }
    return null;
  }

  /// 删除保存的数据
  static Future<void> clear(String managerId) async {
    try {
      final file = File(await _getFilePath(managerId));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Failed to clear dock data: $e');
    }
  }
}
