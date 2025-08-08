import 'package:flutter/widgets.dart';
import 'package:mira/dock/docking/lib/src/layout/area_builder.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/drop_position.dart';
import 'package:mira/dock/docking/lib/src/layout/layout_parser.dart';
import 'dock_item_registry.dart';
import 'dock_persistence.dart';

/// 增强版 DockManager，支持持久化
class DockManager extends ChangeNotifier {
  final String id;
  final DockingLayout layout;
  final DockItemRegistry registry = DockItemRegistry();

  bool _autoSave = false;
  Map<String, DockItemData> _itemDataCache = {};

  DockManager({required this.id, DockingArea? root, bool autoSave = true})
    : layout = DockingLayout(root: root),
      _autoSave = autoSave {
    layout.addListener(_onLayoutChanged);
  }

  void _onLayoutChanged() {
    notifyListeners();
    if (_autoSave) {
      saveToFile();
    }
  }

  @override
  void dispose() {
    layout.removeListener(_onLayoutChanged);
    super.dispose();
  }

  // ========= 持久化相关 =========

  /// 保存当前状态到文件
  Future<void> saveToFile() async {
    final data = _extractCurrentData();
    if (data != null) {
      await DockPersistence.save(id, data);
    }
  }

  /// 获取当前布局数据（公共方法）
  DockPersistenceData? getCurrentData() {
    return _extractCurrentData();
  }

  /// 从数据恢复布局（公共方法）
  bool loadFromData(DockPersistenceData data) {
    return _restoreData(data);
  }

  /// 从文件恢复状态
  Future<bool> restoreFromFile() async {
    final data = await DockPersistence.load(id);
    if (data != null) {
      return _restoreData(data);
    }
    return false;
  }

  /// 清除保存的数据
  Future<void> clearSavedData() async {
    await DockPersistence.clear(id);
    _itemDataCache.clear();
  }

  /// 提取当前布局数据
  DockPersistenceData? _extractCurrentData() {
    if (layout.root == null) return null;

    // 提取布局字符串
    final layoutStr = layout.stringify(parser: _Parser());

    // 提取所有 items 的数据
    final items = <DockItemData>[];
    for (final area in layout.layoutAreas()) {
      if (area is DockingItem) {
        final cachedData = _itemDataCache[area.id];
        if (cachedData != null) {
          items.add(
            DockItemData(
              id: area.id.toString(),
              type: cachedData.type,
              values: cachedData.values,
              name: area.name,
              closable: area.closable,
              keepAlive: area.globalKey != null,
              maximizable: area.maximizable,
              weight: area.weight,
            ),
          );
        }
      }
    }

    // 提取最大化区域
    String? maximizedId;
    if (layout.maximizedArea != null) {
      maximizedId = layout.maximizedArea!.id?.toString();
    }

    return DockPersistenceData(
      layout: layoutStr,
      items: items,
      maximizedAreaId: maximizedId,
    );
  }

  /// 恢复布局数据
  bool _restoreData(DockPersistenceData data) {
    try {
      // 缓存 item 数据
      _itemDataCache = {for (final item in data.items) item.id: item};

      // 恢复布局
      layout.load(
        layout: data.layout,
        parser: _Parser(),
        builder: _Builder(this),
      );

      // 恢复最大化状态
      if (data.maximizedAreaId != null) {
        final area = layout.findDockingArea(data.maximizedAreaId);
        if (area is DockingItem) {
          layout.maximizeDockingItem(area);
        } else if (area is DockingTabs) {
          layout.maximizeDockingTabs(area);
        }
      }

      return true;
    } catch (e) {
      print('Failed to restore dock data: $e');
      return false;
    }
  }

  // ========= 添加 Item 增强版 =========

  /// 添加带类型的 Item
  void addTypedItem({
    required String id,
    required String type,
    required Map<String, dynamic> values,
    required DropArea targetArea,
    DropPosition? dropPosition,
    int? dropIndex,
    String? name,
    bool closable = true,
    bool keepAlive = false,
    bool? maximizable,
    double? weight,
  }) {
    final widget = registry.build(type, values);
    if (widget == null) {
      throw ArgumentError('Unknown item type: $type');
    }

    // 缓存数据
    _itemDataCache[id] = DockItemData(
      id: id,
      type: type,
      values: values,
      name: name,
      closable: closable,
      keepAlive: keepAlive,
      maximizable: maximizable,
      weight: weight,
    );

    // 添加到布局
    layout.addItemOn(
      newItem: DockingItem(
        id: id,
        name: name,
        widget: widget,
        closable: closable,
        keepAlive: keepAlive,
        maximizable: maximizable,
        weight: weight,
      ),
      targetArea: targetArea,
      dropPosition: dropPosition,
      dropIndex: dropIndex,
    );
  }

  /// 更新 Item 的值
  void updateItemValues(String id, Map<String, dynamic> values) {
    final item = layout.findDockingItem(id);
    if (item != null) {
      final cachedData = _itemDataCache[id];
      if (cachedData != null) {
        // 更新缓存
        _itemDataCache[id] = DockItemData(
          id: id,
          type: cachedData.type,
          values: values,
          name: item.name,
          closable: item.closable,
          keepAlive: item.globalKey != null,
          maximizable: item.maximizable,
          weight: item.weight,
        );

        // 重建 Widget
        final newWidget = registry.build(cachedData.type, values);
        if (newWidget != null) {
          item.widget = newWidget;
          layout.rebuild();
        }
      }
    }
  }

  // ========= 基础功能（保持原有） =========

  void setRoot(DockingArea? root) {
    layout.root = root;
  }

  void removeItemById(dynamic id) {
    _itemDataCache.remove(id.toString());
    layout.removeItemByIds([id]);
  }

  void renameItem(dynamic id, String newName) {
    final item = layout.findDockingItem(id);
    if (item != null) {
      item.name = newName;
      // 更新缓存中的名称
      final cachedData = _itemDataCache[id.toString()];
      if (cachedData != null) {
        _itemDataCache[id.toString()] = DockItemData(
          id: cachedData.id,
          type: cachedData.type,
          values: cachedData.values,
          name: newName,
          closable: cachedData.closable,
          keepAlive: cachedData.keepAlive,
          maximizable: cachedData.maximizable,
          weight: cachedData.weight,
        );
      }
      layout.rebuild();
    }
  }
}

/// 解析器
class _Parser with LayoutParserMixin {}

/// 构建器
class _Builder with AreaBuilderMixin {
  final DockManager manager;
  _Builder(this.manager);

  DockingItem buildDockingItem({
    required dynamic id,
    required double? weight,
    required bool maximized,
  }) {
    final itemData = manager._itemDataCache[id.toString()];
    if (itemData != null) {
      final widget = manager.registry.build(itemData.type, itemData.values);
      if (widget != null) {
        return DockingItem(
          id: id,
          name: itemData.name,
          widget: widget,
          closable: itemData.closable,
          keepAlive: itemData.keepAlive,
          maximizable: itemData.maximizable,
          maximized: maximized,
          weight: weight ?? itemData.weight,
        );
      }
    }
    // 降级处理
    return DockingItem(
      id: id,
      name: 'Unknown',
      widget: Container(child: Center(child: Text('Item not found: $id'))),
      weight: weight,
      maximized: maximized,
    );
  }
}
