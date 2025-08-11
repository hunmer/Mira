import '../internal/layout/add_item.dart';
import '../internal/layout/layout_factory.dart';
import '../internal/layout/layout_modifier.dart';
import '../internal/layout/layout_stringify.dart';
import '../internal/layout/move_item.dart';
import '../internal/layout/remove_item.dart';
import '../internal/layout/remove_item_by_id.dart';
import 'area_builder.dart';
import 'docking_area_type.dart';
import 'drop_position.dart';
import 'layout_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:mira/multi_split_view/lib/multi_split_view.dart';
import 'package:mira/tabbed/tabbed_view/lib/tabbed_view.dart';
import 'package:responsive_builder/responsive_builder.dart';

/// Defines how device visibility is handled for DockingItems.
enum DeviceVisibilityMode {
  /// Only visible on the exact specified devices
  exactDevices,

  /// Visible on specified devices and larger devices
  specifiedAndLarger,
}

mixin DropArea {}

/// Represents any area of the layout.
abstract class DockingArea extends Area {
  DockingArea({
    this.id,
    super.size,
    super.weight,
    super.minimalWeight,
    super.minimalSize,
  });

  final dynamic id;

  int _layoutId = -1;
  int get layoutId => _layoutId;

  /// The index in the layout.
  int _index = -1;

  /// Gets the index of this area in the layout.
  ///
  /// If the area is outside the layout, the value will be [-1].
  /// It will be unique across the layout.
  int get index => _index;

  DockingParentArea? _parent;

  /// Gets the parent of this area or [NULL] if it is the root.
  DockingParentArea? get parent => _parent;

  bool _disposed = false;
  bool get disposed => _disposed;

  final Key _key = UniqueKey();
  Key get key => _key;

  /// Disposes.
  void _dispose() {
    _parent = null;
    _layoutId = -1;
    _index = -1;
    _disposed = true;
  }

  /// Gets the type of this area.
  DockingAreaType get type;

  /// Gets the acronym for type.
  String get typeAcronym {
    if (type == DockingAreaType.item) {
      return 'I';
    } else if (type == DockingAreaType.column) {
      return 'C';
    } else if (type == DockingAreaType.row) {
      return 'R';
    } else if (type == DockingAreaType.tabs) {
      return 'T';
    }
    throw StateError('DockingAreaType not recognized: $type');
  }

  /// Gets the path in the layout hierarchy.
  String get path {
    String path = typeAcronym;
    DockingParentArea? p = _parent;
    while (p != null) {
      path = p.typeAcronym + path;
      p = p._parent;
    }
    return path;
  }

  /// Gets the level in the layout hierarchy.
  ///
  /// Return [0] if root (null parent).
  int get level {
    int l = 0;
    DockingParentArea? p = _parent;
    while (p != null) {
      l++;
      p = p._parent;
    }
    return l;
  }

  /// Updates recursively the information of parent, index and layoutId.
  int _updateHierarchy(
    DockingParentArea? parentArea,
    int nextIndex,
    int layoutId,
  ) {
    if (disposed) {
      throw StateError('Disposed area');
    }
    _parent = parentArea;
    // Fix: compare with current _layoutId, not the parameter
    if (_layoutId != -1 && _layoutId != layoutId) {
      throw ArgumentError(
        'DockingParentArea already belongs to another layout',
      );
    }
    _layoutId = layoutId;
    _index = nextIndex++;
    return nextIndex;
  }

  /// Converts layout's hierarchical structure to a debug String.
  String hierarchy({
    bool indexInfo = false,
    bool levelInfo = false,
    bool hasParentInfo = false,
    bool nameInfo = false,
  }) {
    String str = typeAcronym;
    if (indexInfo) {
      str += index.toString();
    }
    if (levelInfo) {
      str += level.toString();
    }
    if (hasParentInfo) {
      if (_parent == null) {
        str += 'F';
      } else {
        str += 'T';
      }
    }
    return str;
  }

  String get areaAcronym;
}

/// Represents an abstract area for a collection of widgets.
abstract class DockingParentArea extends DockingArea {
  DockingParentArea(
    List<DockingArea> children, {
    super.id,
    super.size,
    super.weight,
    super.minimalWeight,
    super.minimalSize,
  }) : _children = children {
    for (DockingArea child in _children) {
      if (child.runtimeType == runtimeType) {
        throw ArgumentError(
          'DockingParentArea cannot have children of the same type',
        );
      }
      if (child.disposed) {
        throw ArgumentError('DockingParentArea cannot have disposed child');
      }
    }
  }

  final List<DockingArea> _children;

  /// Gets the count of children.
  int get childrenCount => _children.length;

  /// Gets a child for a given index.
  DockingArea childAt(int index) => _children[index];

  /// The first index of [dockingArea] in this container.
  ///
  /// Returns -1 if [dockingArea] is not found.
  int indexOf(DockingArea dockingArea) => _children.indexOf(dockingArea);

  /// Whether the [DockingParentArea] contains a child equal to [area].
  bool contains(DockingArea area) {
    return _children.contains(area);
  }

  /// Applies the function [f] to each child of this collection in iteration
  /// order.
  void forEach(void Function(DockingArea child) f) {
    _children.forEach(f);
  }

  /// Applies the function [f] to each child of this collection in iteration
  /// reversed order.
  void forEachReversed(void Function(DockingArea child) f) {
    _children.reversed.forEach(f);
  }

  @override
  int _updateHierarchy(
    DockingParentArea? parentArea,
    int nextIndex,
    int layoutId,
  ) {
    nextIndex = super._updateHierarchy(parentArea, nextIndex, layoutId);
    for (DockingArea area in _children) {
      nextIndex = area._updateHierarchy(this, nextIndex, layoutId);
    }
    return nextIndex;
  }

  @override
  String hierarchy({
    bool indexInfo = false,
    bool levelInfo = false,
    bool hasParentInfo = false,
    bool nameInfo = false,
  }) {
    String str =
        '${super.hierarchy(indexInfo: indexInfo, levelInfo: levelInfo, hasParentInfo: hasParentInfo)}(';
    for (int i = 0; i < _children.length; i++) {
      if (i > 0) {
        str += ',';
      }
      str += _children[i].hierarchy(
        levelInfo: levelInfo,
        hasParentInfo: hasParentInfo,
        indexInfo: indexInfo,
        nameInfo: nameInfo,
      );
    }
    str += ')';
    return str;
  }
}

/// Represents an area for a single widget.
/// The [keepAlive] parameter keeps the state during the layout change.
/// The default value is [FALSE]. This feature implies using GlobalKeys and
/// keeping the widget in memory even if its tab is not selected.
class DockingItem extends DockingArea with DropArea {
  /// Builds a [DockingItem].
  DockingItem({
    super.id,
    this.name,
    required this.widget,
    this.value,
    this.closable = true,
    bool keepAlive = true,
    List<TabButton>? buttons,
    this.maximizable,
    bool maximized = false,
    this.leading,
    this.menuBuilder,
    super.size,
    super.weight,
    super.minimalWeight,
    super.minimalSize,
    this.showAtDevices,
    this.visibilityMode = DeviceVisibilityMode.exactDevices,
    this.parentId,
  }) : buttons = buttons != null ? List.unmodifiable(buttons) : [],
       globalKey = keepAlive ? GlobalKey() : null,
       _maximized = maximized;

  String? name;
  Widget widget;
  dynamic value;
  bool closable;
  final bool? maximizable;
  List<TabButton>? buttons;

  /// Limits where this item is visible. If null, visible on all devices.
  /// Uses DeviceScreenType from responsive_builder.
  final List<DeviceScreenType>? showAtDevices;

  /// Defines how device visibility is handled.
  /// - exactDevices: Only visible on the exact specified devices
  /// - specifiedAndLarger: Visible on specified devices and larger devices
  final DeviceVisibilityMode visibilityMode;

  /// Optional parent id. When the item with this id is closed, this item will
  /// be closed together (cascade close).
  final dynamic parentId;

  final GlobalKey? globalKey;
  TabLeadingBuilder? leading;
  TabbedViewMenuBuilder? menuBuilder;
  bool _maximized;

  bool get maximized => _maximized;

  @override
  DockingAreaType get type => DockingAreaType.item;

  /// Reset parent and index in layout.
  void _resetLocationInLayout() {
    _parent = null;
    _index = -1;
  }

  @override
  String hierarchy({
    bool indexInfo = false,
    bool levelInfo = false,
    bool hasParentInfo = false,
    bool nameInfo = false,
  }) {
    String str = super.hierarchy(
      indexInfo: indexInfo,
      levelInfo: levelInfo,
      hasParentInfo: hasParentInfo,
      nameInfo: nameInfo,
    );
    if (nameInfo && name != null) {
      str += name!;
    }
    return str;
  }

  @override
  String get areaAcronym => 'I';
}

/// Represents an area for a collection of widgets.
/// Children will be arranged horizontally.
class DockingRow extends DockingParentArea {
  /// Builds a [DockingRow].
  DockingRow._(
    List<DockingArea> children,
    dynamic id, {
    double? size,
    double? weight,
    double? minimalWeight,
    double? minimalSize,
  }) : super(
         children,
         id: id,
         size: size,
         weight: weight,
         minimalWeight: minimalWeight,
         minimalSize: minimalSize,
       ) {
    controller = MultiSplitViewController(areas: children);
    if (_children.length < 2) {
      throw ArgumentError('Insufficient number of children');
    }
  }

  /// Builds a [DockingRow].
  factory DockingRow(
    List<DockingArea> children, {
    dynamic id,
    double? size,
    double? weight,
    double? minimalWeight,
    double? minimalSize,
  }) {
    List<DockingArea> newChildren = [];
    for (DockingArea child in children) {
      if (child is DockingRow) {
        newChildren.addAll(child._children);
      } else {
        newChildren.add(child);
      }
    }
    return DockingRow._(
      newChildren,
      id,
      size: size,
      weight: weight,
      minimalWeight: minimalWeight,
      minimalSize: minimalSize,
    );
  }

  late MultiSplitViewController controller;

  @override
  DockingAreaType get type => DockingAreaType.row;

  @override
  String get areaAcronym => 'R';
}

/// Represents an area for a collection of widgets.
/// Children will be arranged vertically.
class DockingColumn extends DockingParentArea {
  /// Builds a [DockingColumn].
  DockingColumn._(
    List<DockingArea> children, {
    dynamic id,
    double? size,
    double? weight,
    double? minimalWeight,
    double? minimalSize,
  }) : super(
         children,
         id: id,
         size: size,
         weight: weight,
         minimalWeight: minimalWeight,
         minimalSize: minimalSize,
       ) {
    controller = MultiSplitViewController(areas: children);
    if (_children.length < 2) {
      throw ArgumentError('Insufficient number of children');
    }
  }

  /// Builds a [DockingColumn].
  factory DockingColumn(
    List<DockingArea> children, {
    dynamic id,
    double? size,
    double? weight,
    double? minimalWeight,
    double? minimalSize,
  }) {
    List<DockingArea> newChildren = [];
    for (DockingArea child in children) {
      if (child is DockingColumn) {
        newChildren.addAll(child._children);
      } else {
        newChildren.add(child);
      }
    }
    return DockingColumn._(
      newChildren,
      id: id,
      size: size,
      weight: weight,
      minimalWeight: minimalWeight,
      minimalSize: minimalSize,
    );
  }

  late MultiSplitViewController controller;

  @override
  DockingAreaType get type => DockingAreaType.column;

  @override
  String get areaAcronym => 'C';
}

/// Represents an area for a collection of widgets.
/// Children will be arranged in tabs.
class DockingTabs extends DockingParentArea with DropArea {
  /// Builds a [DockingTabs].
  DockingTabs(
    List<DockingItem> super.children, {
    super.id,
    bool maximized = false,
    this.maximizable,
    super.size,
    super.weight,
    super.minimalWeight,
    super.minimalSize,
  }) : _maximized = maximized {
    if (_children.isEmpty) {
      throw ArgumentError('DockingTabs cannot be empty');
    }
  }

  final bool? maximizable;

  int selectedIndex = 0;
  bool _maximized;

  bool get maximized => _maximized;

  @override
  DockingItem childAt(int index) => _children[index] as DockingItem;

  @override
  void forEach(void Function(DockingItem child) f) {
    for (var child in _children) {
      f(child as DockingItem);
    }
  }

  @override
  DockingAreaType get type => DockingAreaType.tabs;

  @override
  String get areaAcronym => 'T';
}

/// Represents a layout.
///
/// The layout is organized into [DockingItem], [DockingColumn],
/// [DockingRow] and [DockingTabs].
/// The [root] is single and can be any [DockingArea].
class DockingLayout extends ChangeNotifier {
  // Global registry and guard for cascading removals across layouts
  static final Set<DockingLayout> _registry = <DockingLayout>{};
  static final Set<dynamic> _cascadeInProgress = <dynamic>{};
  static void _register(DockingLayout layout) => _registry.add(layout);

  DockingArea? _root;
  DockingArea? _maximizedArea;

  int get id => hashCode;
  DockingArea? get root => _root;
  DockingArea? get maximizedArea => _maximizedArea;

  DockingLayout({DockingArea? root}) : _root = root {
    _reset();
    DockingLayout._register(this);
  }

  // Core helpers placed early
  List<DockingArea> layoutAreas() {
    final list = <DockingArea>[];
    if (_root != null) {
      _fetchAreas(list, _root!);
    }
    return list;
  }

  void _fetchAreas(List<DockingArea> areas, DockingArea area) {
    areas.add(area);
    if (area is DockingParentArea) {
      for (final child in area._children) {
        _fetchAreas(areas, child);
      }
    }
  }

  void _rebuild(List<LayoutModifier> modifiers) {
    final olderAreas = layoutAreas();
    for (final modifier in modifiers) {
      for (final area in layoutAreas()) {
        if (area is DockingItem) {
          area._resetLocationInLayout();
        }
      }
      _root = modifier.newLayout(this);
      _updateHierarchy();
      for (final area in olderAreas) {
        if (area is DockingParentArea) {
          area._dispose();
        } else if (area is DockingItem) {
          if (area.index == -1) area._dispose();
        }
      }
    }
    _maximizedArea = null;
    for (final area in layoutAreas()) {
      if (area is DockingItem && area.maximized) {
        _maximizedArea = area;
      } else if (area is DockingTabs && area.maximized) {
        _maximizedArea = area;
      }
    }
    notifyListeners();
  }

  // Cascading removal by parentId across all registered layouts
  static void removeItemsByParentId(dynamic parentId) {
    if (parentId == null) return;
    if (_cascadeInProgress.contains(parentId)) return;
    _cascadeInProgress.add(parentId);
    try {
      bool removed;
      do {
        removed = false;
        for (final layout in _registry) {
          // Collect matches for this layout first
          final toClose =
              layout
                  .layoutAreas()
                  .whereType<DockingItem>()
                  .where((item) => item.parentId == parentId)
                  .toList();
          if (toClose.isNotEmpty) {
            // Remove via data-layer API so any nested cascades (grand-children) also trigger
            for (final item in toClose) {
              layout.removeItem(item: item);
            }
            removed = true;
          }
        }
      } while (removed);
    } finally {
      _cascadeInProgress.remove(parentId);
    }
  }

  // API
  void load({
    required String layout,
    required LayoutParser parser,
    required AreaBuilder builder,
  }) {
    root = LayoutFactory.buildRoot(
      layout: layout,
      parser: parser,
      builder: builder,
    );
  }

  set root(DockingArea? root) {
    for (final area in layoutAreas()) {
      area._dispose();
    }
    _root = root;
    _reset();
    notifyListeners();
  }

  void rebuild() => notifyListeners();

  void _reset() {
    _updateHierarchy();
    int maximizedCount = 0;
    for (final area in layoutAreas()) {
      if (area is DockingItem && area.maximized) {
        maximizedCount++;
        _maximizedArea = area;
      } else if (area is DockingTabs && area.maximized) {
        maximizedCount++;
        _maximizedArea = area;
      }
    }
    if (maximizedCount > 1) {
      throw ArgumentError('Multiple maximized areas.');
    }
  }

  String hierarchy({
    bool indexInfo = false,
    bool levelInfo = false,
    bool hasParentInfo = false,
    bool nameInfo = false,
  }) {
    if (_root == null) return '';
    return _root!.hierarchy(
      indexInfo: indexInfo,
      levelInfo: levelInfo,
      hasParentInfo: hasParentInfo,
      nameInfo: nameInfo,
    );
  }

  _updateHierarchy() {
    _root?._updateHierarchy(null, 1, id);
  }

  DockingTabs? findDockingTabsWithItem(dynamic itemId) {
    final item = findDockingItem(itemId);
    if (item != null) {
      final parent = item.parent;
      return parent is DockingTabs ? parent : null;
    }
    return null;
  }

  DockingItem? findDockingItem(dynamic id) {
    final area = _findDockingArea(area: _root, id: id);
    return area is DockingItem ? area : null;
  }

  DockingArea? findDockingArea(dynamic id) {
    return _findDockingArea(area: _root, id: id);
  }

  DockingArea? _findDockingArea({DockingArea? area, dynamic id}) {
    if (area != null) {
      if (area.id == id) {
        return area;
      } else if (area is DockingParentArea) {
        for (final child in area._children) {
          final item = _findDockingArea(area: child, id: id);
          if (item != null) return item;
        }
      }
    }
    return null;
  }

  void maximizeDockingItem(DockingItem dockingItem) {
    if (dockingItem.layoutId != id) {
      throw ArgumentError('DockingItem does not belong to this layout.');
    }
    if (!dockingItem.maximized) {
      _removesMaximizedStatus();
      dockingItem._maximized = true;
      _maximizedArea = dockingItem;
      notifyListeners();
    }
  }

  void maximizeDockingTabs(DockingTabs dockingTabs) {
    if (dockingTabs.layoutId != id) {
      throw ArgumentError('DockingTabs does not belong to this layout.');
    }
    if (!dockingTabs.maximized) {
      _removesMaximizedStatus();
      dockingTabs._maximized = true;
      _maximizedArea = dockingTabs;
      notifyListeners();
    }
  }

  void _removesMaximizedStatus() {
    for (final area in layoutAreas()) {
      if (area is DockingItem) {
        area._maximized = false;
      } else if (area is DockingTabs) {
        area._maximized = false;
      }
    }
    _maximizedArea = null;
  }

  void restore() {
    _removesMaximizedStatus();
    notifyListeners();
  }

  void moveItem({
    required DockingItem draggedItem,
    required DropArea targetArea,
    DropPosition? dropPosition,
    int? dropIndex,
  }) {
    _rebuild([
      MoveItem(
        draggedItem: draggedItem,
        targetArea: targetArea,
        dropPosition: dropPosition,
        dropIndex: dropIndex,
      ),
    ]);
  }

  void removeItemByIds(List<dynamic> ids) {
    final modifiers = <LayoutModifier>[];
    for (final id in ids) {
      modifiers.add(RemoveItemById(id: id));
    }
    _rebuild(modifiers);
    for (final id in ids) {
      if (id != null) {
        DockingLayout.removeItemsByParentId(id);
      }
    }
  }

  void removeItem({required DockingItem item}) {
    _rebuild([RemoveItem(itemToRemove: item)]);
    final pid = item.id;
    if (pid != null) {
      DockingLayout.removeItemsByParentId(pid);
    }
  }

  void addItemOn({
    required DockingItem newItem,
    required DropArea targetArea,
    DropPosition? dropPosition,
    int? dropIndex,
  }) {
    _rebuild([
      AddItem(
        newItem: newItem,
        targetArea: targetArea,
        dropPosition: dropPosition,
        dropIndex: dropIndex,
      ),
    ]);
  }

  void addItemOnRoot({
    required DockingItem newItem,
    DropPosition? dropPosition,
    int? dropIndex,
  }) {
    if (root == null) {
      throw StateError('Root is null');
    }
    if (root is DropArea) {
      final targetArea = root! as DropArea;
      _rebuild([
        AddItem(
          newItem: newItem,
          targetArea: targetArea,
          dropPosition: dropPosition,
          dropIndex: dropIndex,
        ),
      ]);
    } else {
      throw StateError('Root is not a DropArea');
    }
  }

  String stringify({required LayoutParser parser}) {
    final List<DockingArea> areas = layoutAreas();
    return LayoutStringify.stringify(parser: parser, areas: areas);
  }
}
