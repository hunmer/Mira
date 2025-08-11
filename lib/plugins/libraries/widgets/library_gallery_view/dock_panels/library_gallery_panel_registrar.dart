import 'quick_actions_panel.dart';
import 'sidebar_panel.dart';
import 'main_content_panel.dart';
import 'details_panel.dart';
import 'app_bar_actions_panel.dart';

/// 图库面板组件注册器
class LibraryGalleryPanelRegistrar {
  /// 注册所有图库面板组件
  static void registerAllPanels(dynamic manager) {
    QuickActionsPanelRegistrar.register(manager);
    SidebarPanelRegistrar.register(manager);
    MainContentPanelRegistrar.register(manager);
    DetailsPanelRegistrar.register(manager);
    AppBarActionsPanelRegistrar.register(manager);
  }
}
