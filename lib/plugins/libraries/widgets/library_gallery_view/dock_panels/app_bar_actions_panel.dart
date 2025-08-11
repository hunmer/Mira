import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_app_bar.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager_dock.dart';
import '../library_gallery_state.dart';
import '../library_gallery_events.dart';
import '../drag_select_view.dart';

/// 应用栏操作面板组件
class AppBarActionsPanel extends StatelessWidget {
  final LibrariesPlugin plugin;
  final Library library;
  final LibraryGalleryState state;
  final LibraryGalleryEvents events;
  final String tabId;
  final VoidCallback? onShowDropDialog;

  const AppBarActionsPanel({
    Key? key,
    required this.plugin,
    required this.library,
    required this.state,
    required this.events,
    required this.tabId,
    this.onShowDropDialog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: LibraryGalleryAppBar(
        title: library.name,
        getItems: () => state.items.value,
        getSelected: () => state.selectedFileIds.value,
        isSelectionMode: state.isSelectionModeNotifier.value,
        onToggleSelection:
            (bool enable) => state.isSelectionModeNotifier.value = enable,
        isRecycleBin: state.tabData.isRecycleBin,
        onSelectionChanged: (Set<int> selected) {
          state.selectedFileIds.value = selected;
        },
        filterOptions: Map<String, dynamic>.from(
          state.filterOptionsNotifier.value,
        ),
        onFilterChanged: (Map<String, dynamic> filterOptions) {
          if (filterOptions != null &&
              state.filterOptionsNotifier.value != filterOptions) {
            state.filterOptionsNotifier.value = filterOptions;
            LibraryTabManager.updateFilter(tabId, filterOptions);
          }
        },
        onUpload: onShowDropDialog ?? () {},
        uploadProgress: state.uploadProgressNotifier.value,
        displayFields: Set<String>.from(state.displayFieldsNotifier.value),
        onDisplayFieldsChanged: (Set<String> fields) {
          state.displayFieldsNotifier.value = fields;
          LibraryTabManager.setValue(tabId, 'displayFields', fields);
        },
        imagesPerRow: state.imagesPerRowNotifier.value,
        onImagesPerRowChanged: (count) {
          state.imagesPerRowNotifier.value = count;
          LibraryTabManager.setValue(tabId, 'imagesPerRow', count);
        },
        onRefresh: events.refresh,
        sortOptions: state.sortOptionsNotifier.value,
        onSortChanged: (sortOptions) {
          if (sortOptions != null &&
              state.sortOptionsNotifier.value != sortOptions) {
            state.sortOptionsNotifier.value = sortOptions;
            LibraryTabManager.setValue(tabId, 'sortOptions', sortOptions);
            events.loadFiles();
          }
        },
        viewType: state.viewTypeNotifier.value,
        onViewTypeChanged: (DragSelectViewType viewType) {
          state.viewTypeNotifier.value = viewType;
          LibraryTabManager.setValue(tabId, 'viewType', viewType.index);
        },
      ),
    );
  }
}

/// 应用栏操作面板注册器
class AppBarActionsPanelRegistrar {
  static const String type = 'library_app_bar_actions';

  static void register(dynamic manager) {
    manager.registry.register(
      type,
      builder: (values) {
        final plugin = values['plugin'] as LibrariesPlugin;
        final library = Library.fromMap(
          values['library'] as Map<String, dynamic>,
        );
        final state = values['state'] as LibraryGalleryState;
        final events = values['events'] as LibraryGalleryEvents;
        final tabId = values['tabId'] as String;
        final onShowDropDialog = values['onShowDropDialog'] as VoidCallback?;

        return AppBarActionsPanel(
          plugin: plugin,
          library: library,
          state: state,
          events: events,
          tabId: tabId,
          onShowDropDialog: onShowDropDialog,
        );
      },
    );
  }
}
