# Library Gallery Dock Panels

这个目录包含了图库视图的各个面板组件，每个面板都被分离成独立的组件类型，并注册到 Dock 管理器中。

## 面板组件

### 1. QuickActionsPanel (快速操作面板)
- **文件**: `quick_actions_panel.dart`
- **注册类型**: `library_quick_actions`
- **功能**: 提供侧边栏切换、文件夹选择、标签选择等快速操作

### 2. SidebarPanel (侧边栏面板)
- **文件**: `sidebar_panel.dart`
- **注册类型**: `library_sidebar`
- **功能**: 显示标签和文件夹过滤器

### 3. MainContentPanel (主内容面板)
- **文件**: `main_content_panel.dart`
- **注册类型**: `library_main_content`
- **功能**: 显示文件列表、拖拽选择、分页等主要内容

### 4. DetailsPanel (详情面板)
- **文件**: `details_panel.dart`
- **注册类型**: `library_details`
- **功能**: 显示文件详细信息和选中文件列表

### 5. AppBarActionsPanel (应用栏操作面板)
- **文件**: `app_bar_actions_panel.dart`
- **注册类型**: `library_app_bar_actions`
- **功能**: 提供过滤、排序、视图切换等工具栏功能

## 注册器

### LibraryGalleryPanelRegistrar
- **文件**: `library_gallery_panel_registrar.dart`
- **功能**: 统一注册所有面板组件到 Dock 管理器
- **调用**: 在 `DockItemRegistrar.registerAllComponents()` 中自动注册

## 使用方式

1. 组件会在应用启动时自动注册到 Dock 管理器
2. 在 `LibraryGalleryBuilders._buildItemContent()` 中通过注册类型名称调用组件
3. 每个组件接收必要的数据作为参数，保持数据和UI的分离

## 优势

- **模块化**: 每个面板都是独立的组件
- **可复用**: 组件可以在其他地方复用
- **可维护**: 代码分离，易于维护和测试
- **可扩展**: 易于添加新的面板类型
