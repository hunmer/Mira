import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/dock/docking/lib/src/layout/area_builder.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/layout_parser.dart';
import 'dock_manager.dart';
import 'dock_tab.dart';

/// DockLayoutParser - 处理DockingLayout的序列化和反序列化
/// 实现LayoutParser接口以支持保存和加载布局
abstract class DockLayoutParser implements LayoutParser {
  /// 将DockItem ID转换为字符串
  @override
  String idToString(dynamic id) {
    if (id == null) {
      return '';
    }
    if (id is String) {
      return id;
    }
    return id.toString();
  }

  /// 将字符串转换为DockItem ID
  @override
  dynamic stringToId(String id) {
    if (id.isEmpty) {
      return null;
    }
    return id;
  }
}

/// 默认的DockLayoutParser实现
class DefaultDockLayoutParser extends DockLayoutParser
    with AreaBuilderMixin
    implements AreaBuilder {
  final String dockTabsId;
  final String tabId;

  DefaultDockLayoutParser({required this.dockTabsId, required this.tabId});

  @override
  String idToString(dynamic id) {
    if (id == null) {
      return '';
    }
    // 对于DockingTabs中的每个tab，我们应该使用特殊的格式
    // 格式: "tab:tabId" 来区分tab ID和DockItem title
    // print('Saving ID: $id (type: ${id.runtimeType})');

    // 检查是否是tab ID（在当前DockTabs中存在的tab）
    final dockTabs = DockManager.getDockTabs(dockTabsId);
    if (dockTabs != null &&
        dockTabs.getAllDockTabs().containsKey(id.toString())) {
      return 'tab:${id.toString()}';
    }

    return id.toString();
  }

  @override
  dynamic stringToId(String id) {
    if (id.isEmpty) {
      return null;
    }
    // print('Loading ID: $id');

    // 如果是tab格式，去掉前缀
    if (id.startsWith('tab:')) {
      return id.substring(4);
    }

    return id;
  }

  @override
  DockingItem buildDockingItem({
    required dynamic id,
    required double? weight,
    required bool maximized,
  }) {
    // print(
    //   'Building DockingItem for ID: $id, tabId: $tabId, dockTabsId: $dockTabsId',
    // );

    if (id == null) {
      return DockingItem(
        weight: weight,
        maximized: maximized,
        widget: const Center(child: Text('Empty')),
      );
    }

    final idString = id.toString();

    try {
      // 检查是否是tab ID（用于处理DockingTabs布局）
      final dockTabs = DockManager.getDockTabs(dockTabsId);
      if (dockTabs != null) {
        final tab = dockTabs.getDockTab(idString);
        if (tab != null) {
          // print('Found tab: ${tab.id} with displayName: ${tab.displayName}');
          // 返回整个tab的内容作为DockingItem
          return DockingItem(
            id: id,
            name: tab.displayName,
            widget: _buildTabContent(tab),
            weight: weight,
            maximized: maximized,
          );
        }
      }

      // 如果不是tab ID，尝试作为DockItem ID或title查找
      // 优先使用ID查找，如果找不到再尝试title查找
      var dockItem = DockManager.getDockItemById(dockTabsId, tabId, idString);

      if (dockItem == null) {
        // 如果ID查找失败，尝试title查找（为了向后兼容）
        dockItem = DockManager.getDockItem(dockTabsId, tabId, idString);
      }

      if (dockItem != null) {
        // print(
        //   'Found DockItem: ${dockItem.title} (ID: ${dockItem.id}) in tab: $tabId',
        // );
        // 获取对应tab的默认配置
        final dockTab = dockTabs?.getDockTab(tabId);
        final defaultConfig = dockTab?.getDefaultDockingItemConfig() ?? {};

        // 使用DockItem的buildDockingItem方法，传入默认配置
        final dockingItem = dockItem.buildDockingItem(
          defaultConfig: defaultConfig,
        );
        return DockingItem(
          id: id,
          name: dockingItem.name,
          widget: dockingItem.widget,
          weight: weight,
          maximized: maximized,
          closable: dockingItem.closable,
          leading: dockingItem.leading,
          buttons: dockingItem.buttons,
        );
      }

      // 如果在指定tab中找不到，尝试在所有tab中查找
      if (dockTabs != null) {
        for (var tab in dockTabs.getAllDockTabs().values) {
          // 优先使用ID查找
          var foundItem = tab.getDockItemById(idString);
          if (foundItem == null) {
            // 如果ID查找失败，尝试title查找
            foundItem = tab.getDockItem(idString);
          }

          if (foundItem != null) {
            // print(
            //   'Found DockItem: ${foundItem.title} (ID: ${foundItem.id}) in tab: ${tab.id} (different from expected tab: $tabId)',
            // );
            // 使用找到的tab的默认配置
            final defaultConfig = tab.getDefaultDockingItemConfig();
            final dockingItem = foundItem.buildDockingItem(
              defaultConfig: defaultConfig,
            );
            return DockingItem(
              id: id,
              name: dockingItem.name,
              widget: dockingItem.widget,
              weight: weight,
              maximized: maximized,
              closable: dockingItem.closable,
              leading: dockingItem.leading,
              buttons: dockingItem.buttons,
            );
          }
        }
      }
    } catch (e) {
      print('Error getting DockItem for id "$id" in tab "$tabId": $e');
    }

    // 如果找不到或出现错误，创建一个默认的DockingItem
    print('DockItem not found for ID: $id, creating placeholder');
    return DockingItem(
      id: id,
      name: idString,
      widget: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text('Item not found: $idString'),
            const SizedBox(height: 8),
            Text(
              'Expected Tab: $tabId',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'This item may have been removed or the layout is corrupted.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      weight: weight,
      maximized: maximized,
    );
  }

  /// 构建Tab内容
  Widget _buildTabContent(DockTab tab) {
    final items = tab.getAllDockItems();
    if (items.isEmpty) {
      return const Center(child: Text('Empty tab'));
    } else if (items.length == 1) {
      return items.first
          .buildDockingItem(defaultConfig: tab.getDefaultDockingItemConfig())
          .widget;
    } else {
      return Docking(
        layout: DockingLayout(
          root: DockingTabs(
            items
                .map(
                  (item) => item.buildDockingItem(
                    defaultConfig: tab.getDefaultDockingItemConfig(),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }
  }
}

/// DockLayoutManager - 管理DockingLayout的保存和加载
class DockLayoutManager {
  static final Map<String, String> _savedLayouts = {};
  static final Map<String, DockLayoutParser> _parsers = {};

  /// 注册一个parser
  static void registerParser(String key, DockLayoutParser parser) {
    _parsers[key] = parser;
  }

  /// 保存布局
  static String saveLayout(
    String key,
    DockingLayout layout,
    DockLayoutParser parser,
  ) {
    final layoutString = layout.stringify(parser: parser);
    _savedLayouts[key] = layoutString;
    return layoutString;
  }

  /// 加载布局
  static bool loadLayout(String key, DockingLayout layout) {
    final layoutString = _savedLayouts[key];
    final parser = _parsers[key];

    if (layoutString != null && parser != null && parser is AreaBuilder) {
      layout.load(
        layout: layoutString,
        parser: parser,
        builder: parser as AreaBuilder,
      );
      return true;
    }
    return false;
  }

  /// 获取保存的布局字符串
  static String? getSavedLayout(String key) {
    return _savedLayouts[key];
  }

  /// 设置保存的布局字符串（用于临时设置）
  static void setSavedLayout(String key, String layoutString) {
    _savedLayouts[key] = layoutString;
  }

  /// 获取所有保存的布局键
  static List<String> getAllSavedLayoutKeys() {
    return _savedLayouts.keys.toList();
  }

  /// 删除保存的布局
  static bool deleteSavedLayout(String key) {
    final removed = _savedLayouts.remove(key);
    _parsers.remove(key);
    return removed != null;
  }

  /// 清空所有保存的布局
  static void clearAllSavedLayouts() {
    _savedLayouts.clear();
    _parsers.clear();
  }

  /// 将所有布局保存为JSON
  static Map<String, dynamic> saveAllLayoutsToJson() {
    return Map<String, dynamic>.from(_savedLayouts);
  }

  /// 从JSON加载所有布局
  static void loadAllLayoutsFromJson(Map<String, dynamic> json) {
    _savedLayouts.clear();
    for (var entry in json.entries) {
      if (entry.value is String) {
        _savedLayouts[entry.key] = entry.value as String;
      }
    }
  }
}
