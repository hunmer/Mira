import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';
import 'package:number_pagination/number_pagination.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import '../library_gallery_state.dart';
import '../library_gallery_events.dart';
import '../drag_select_view.dart';

/// 主内容面板组件
class MainContentPanel extends StatelessWidget {
  final LibrariesPlugin plugin;
  final Library library;
  final LibraryGalleryState state;
  final LibraryGalleryEvents events;
  final bool isRecycleBin;
  final Function(LibraryFile) onFileOpen;
  final Function(LibraryFile) onFileSelected;
  final Function(LibraryFile) onToggleSelected;

  const MainContentPanel({
    Key? key,
    required this.plugin,
    required this.library,
    required this.state,
    required this.events,
    required this.isRecycleBin,
    required this.onFileOpen,
    required this.onFileSelected,
    required this.onToggleSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    _buildGalleryBodyWithDragSelect(),
                    ValueListenableBuilder(
                      valueListenable: state.isItemsLoadingNotifier,
                      builder: (context, isLoading, _) {
                        return isLoading
                            ? Center(child: CircularProgressIndicator())
                            : SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              _buildPagination(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGalleryBodyWithDragSelect() {
    return MultiValueListenableBuilder(
      valueListenables: [
        state.items,
        state.isSelectionModeNotifier,
        state.selectedFileIds,
        state.displayFieldsNotifier,
        state.imagesPerRowNotifier,
        state.viewTypeNotifier,
      ],
      builder: (context, values, _) {
        return GestureDetector(
          // 双击清除所有选中
          onDoubleTap: () {
            state.selectedFileIds.value = {};
            state.isSelectionModeNotifier.value = false;
          },
          child: DragSelectView(
            plugin: plugin,
            library: library,
            viewType: values[5] as DragSelectViewType,
            isRecycleBin: state.tabData.isRecycleBin,
            displayFields: values[3] as Set<String>,
            items: values[0] as List<LibraryFile>,
            isSelectionMode: values[1] as bool,
            selectedFileIds: values[2] as Set<int>,
            onFileSelected: onFileSelected,
            onToggleSelected: onToggleSelected,
            onFileOpen: onFileOpen,
            imagesPerRow: values[4] as int,
            scrollController: state.scrollController,
            onSelectionChanged: (selectedIds) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                state.selectedFileIds.value = selectedIds;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildPagination(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: state.totalItemsNotifier,
      builder: (context, totalItems, _) {
        final paginationOptions = state.paginationOptionsNotifier.value;
        final totalPages = (totalItems / paginationOptions['perPage']).ceil();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: NumberPagination(
            currentPage: paginationOptions['page'],
            totalPages: totalPages,
            onPageChanged: events.toPage,
            visiblePagesCount: MediaQuery.of(context).size.width ~/ 200 + 2,
            buttonRadius: 10.0,
            buttonElevation: 1.0,
            controlButtonSize: Size(34, 34),
            numberButtonSize: Size(34, 34),
            selectedButtonColor: Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }
}

/// 主内容面板注册器
class MainContentPanelRegistrar {
  static const String type = 'library_main_content';

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
        final isRecycleBin = values['isRecycleBin'] as bool;
        final onFileOpen = values['onFileOpen'] as Function(LibraryFile);
        final onFileSelected =
            values['onFileSelected'] as Function(LibraryFile);
        final onToggleSelected =
            values['onToggleSelected'] as Function(LibraryFile);

        return MainContentPanel(
          plugin: plugin,
          library: library,
          state: state,
          events: events,
          isRecycleBin: isRecycleBin,
          onFileOpen: onFileOpen,
          onFileSelected: onFileSelected,
          onToggleSelected: onToggleSelected,
        );
      },
    );
  }
}
