import 'package:flutter/material.dart';

part 'tree_node.dart';

part 'treeview_state.dart';

/// The selection mode for the tree view.
enum TreeSelectionMode {
  /// Only one node can be selected at a time
  single,

  /// Multiple nodes can be selected
  multiple,
}

class TreeView<T> extends StatefulWidget {
  /// The root nodes of the tree.
  final List<TreeNode<T>> nodes;

  /// Callback function called when the selection state changes.
  final Function(List<T?>)? onSelectionChanged;

  /// Optional theme data for the tree view.
  final ThemeData? theme;

  /// Whether to show a "Select All" checkbox.
  final bool showSelectAll;

  /// The number of levels to initially expand. If null, no nodes are expanded.
  final int? initialExpandedLevels;

  /// Custom widget to replace the default "Select All" checkbox.
  final Widget? selectAllWidget;

  /// The trailing widget displayed for select all node.
  final Widget Function(BuildContext context)? selectAllTrailing;

  /// Whether to show the expand/collapse all button.
  final bool showExpandCollapseButton;

  /// Custom function to draw nodes
  final Function(TreeNode<T> node, bool isSelected)? customDrawNode;

  /// Creates a [TreeView] widget.
  ///
  /// The [nodes] and [onSelectionChanged] parameters are required.
  ///
  /// The [theme] parameter can be used to customize the appearance of the tree view.
  ///
  /// Set [showSelectAll] to true to display a "Select All" checkbox.
  ///
  /// The [selectAllWidget] can be used to provide a custom widget for the "Select All" functionality.
  ///
  /// Use [initialExpandedLevels] to control how many levels of the tree are initially expanded.
  /// If null, no nodes are expanded. If set to 0, all nodes are expanded.
  /// If set to 1, only the root nodes are expanded, if set to 2, the root nodes and their direct children are expanded, and so on.
  ///
  /// Set [showExpandCollapseButton] to true to display a button that expands or collapses all nodes.
  ///
  /// The [selectionMode] parameter controls whether single or multiple nodes can be selected.
  /// Defaults to [TreeSelectionMode.multiple].
  const TreeView({
    super.key,
    required this.nodes,
    this.onSelectionChanged,
    this.theme,
    this.showSelectAll = false,
    this.selectAllWidget,
    this.selectAllTrailing,
    this.initialExpandedLevels,
    this.showExpandCollapseButton = false,
    this.customDrawNode,
    this.selectionMode = TreeSelectionMode.multiple,
  });

  /// The selection mode for the tree view.
  /// Defaults to [TreeSelectionMode.multiple].
  final TreeSelectionMode selectionMode;

  @override
  TreeViewState<T> createState() => TreeViewState<T>();
}
