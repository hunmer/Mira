import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TabData {
  final int index;
  final Tab title;
  final Widget content;
  TabData({required this.index, required this.title, required this.content});
}

enum MoveToTab { idol, next, previous, first, last }

class DynamicTabBarWidget extends TabBar {
  final List<TabData> dynamicTabs;
  final Function(TabController) onTabControllerUpdated;
  final Function(int?)? onTabChanged;
  final MoveToTab? onAddTabMoveTo;
  final int? onAddTabMoveToIndex;
  final Widget? backIcon;
  final Widget? nextIcon;
  final bool? showBackIcon;
  final bool? showNextIcon;
  final Widget? leading;
  final Widget? trailing;
  final ScrollPhysics? physicsTabBarView;
  final DragStartBehavior dragStartBehaviorTabBarView;
  final double viewportFractionTabBarView;
  final Clip clipBehaviorTabBarView;
  final bool enableAnimation;
  DynamicTabBarWidget({
    super.key,
    required this.dynamicTabs,
    required this.onTabControllerUpdated,
    this.onTabChanged,
    this.onAddTabMoveTo,
    this.onAddTabMoveToIndex,
    super.isScrollable,
    this.backIcon,
    this.nextIcon,
    this.showBackIcon = true,
    this.showNextIcon = true,
    this.leading,
    this.trailing,
    this.enableAnimation = true,
    super.padding,
    super.indicatorColor,
    super.automaticIndicatorColorAdjustment = true,
    super.indicatorWeight = 2.0,
    super.indicatorPadding = EdgeInsets.zero,
    super.indicator,
    super.indicatorSize,
    super.dividerColor,
    super.dividerHeight,
    super.labelColor,
    super.labelStyle,
    super.labelPadding,
    super.unselectedLabelColor,
    super.unselectedLabelStyle,
    super.dragStartBehavior = DragStartBehavior.start,
    super.overlayColor,
    super.mouseCursor,
    super.enableFeedback,
    super.onTap,
    super.physics,
    super.splashFactory,
    super.splashBorderRadius,
    super.tabAlignment,
    this.physicsTabBarView,
    this.dragStartBehaviorTabBarView = DragStartBehavior.start,
    this.viewportFractionTabBarView = 1.0,
    this.clipBehaviorTabBarView = Clip.hardEdge,
  }) : super(tabs: []);
  @override
  // ignore: library_private_types_in_public_api
  _DynamicTabBarWidgetState createState() => _DynamicTabBarWidgetState();
}

class _DynamicTabBarWidgetState extends State<DynamicTabBarWidget>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int activeTab = 0;
  @override
  void initState() {
    super.initState();
    _tabController = getTabController(initialIndex: activeTab);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabController = getTabController(
      initialIndex: widget.dynamicTabs.length - 1,
    );
    if (_tabController != null) {
      widget.onTabControllerUpdated.call(_tabController!);
    }
  }

  @override
  void didUpdateWidget(covariant DynamicTabBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dynamicTabs.isEmpty) {
      return;
    }
    if (_tabController?.length != widget.dynamicTabs.length) {
      var activeTabIndex = getActiveTab();
      if (activeTabIndex >= widget.dynamicTabs.length) {
        activeTabIndex = widget.dynamicTabs.length - 1;
      }
      _tabController = getTabController(initialIndex: activeTabIndex);
      var tabIndex =
          widget.onAddTabMoveToIndex ??
          getOnAddMoveToTab(widget.onAddTabMoveTo);
      if (tabIndex != null) {
        Future.delayed(const Duration(milliseconds: 50), () {
          _moveToTab(tabIndex);
        });
      }
    }
    if (_tabController != null) {
      widget.onTabControllerUpdated.call(_tabController!);
    }
  }

  TabController getTabController({int initialIndex = 0}) {
    if (initialIndex >= widget.dynamicTabs.length) {
      initialIndex = widget.dynamicTabs.length - 1;
    }
    return TabController(
      initialIndex: initialIndex,
      length: widget.dynamicTabs.length,
      animationDuration:
          widget.enableAnimation
              ? const Duration(milliseconds: 300)
              : Duration.zero,
      vsync: this,
    )..addListener(() {
      setState(() {
        activeTab = _tabController?.index ?? 0;
        widget.onTabChanged!(activeTab);
      });
    });
  }

  int getActiveTab() {
    if (activeTab == 0 && widget.dynamicTabs.isEmpty) {
      return 0;
    }
    if (activeTab == widget.dynamicTabs.length) {
      return widget.dynamicTabs.length - 1;
    }
    if (activeTab < widget.dynamicTabs.length) {
      return activeTab;
    }
    return widget.dynamicTabs.length;
  }

  int? getOnAddMoveToTab(MoveToTab? moveToTab) {
    switch (moveToTab) {
      case MoveToTab.next:
        return activeTab + 1;
      case MoveToTab.previous:
        return activeTab > 0 ? activeTab - 1 : activeTab;
      case MoveToTab.first:
        return 0;
      case MoveToTab.last:
        return widget.dynamicTabs.length - 1;
      case MoveToTab.idol:
        return null;
      case null:
        return widget.dynamicTabs.length - 1;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: DefaultTabController(
        length: widget.dynamicTabs.length,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              children: [
                if (widget.leading != null) widget.leading!,
                if (widget.isScrollable == true && widget.showBackIcon == true)
                  IconButton(
                    icon: widget.backIcon ?? const Icon(Icons.arrow_back_ios),
                    onPressed: _moveToPreviousTab,
                  ),
                Expanded(
                  child:
                      widget.dynamicTabs.isEmpty
                          ? const SizedBox()
                          : TabBar(
                            isScrollable: widget.isScrollable,
                            controller: _tabController,
                            tabs:
                                widget.dynamicTabs
                                    .map((tab) => tab.title)
                                    .toList(),
                            padding: widget.padding,
                            indicatorColor: widget.indicatorColor,
                            automaticIndicatorColorAdjustment:
                                widget.automaticIndicatorColorAdjustment,
                            indicatorWeight: widget.indicatorWeight,
                            indicatorPadding: widget.indicatorPadding,
                            indicator: widget.indicator,
                            indicatorSize: widget.indicatorSize,
                            dividerColor: widget.dividerColor,
                            dividerHeight: widget.dividerHeight,
                            labelColor: widget.labelColor,
                            labelStyle: widget.labelStyle,
                            labelPadding: widget.labelPadding,
                            unselectedLabelColor: widget.unselectedLabelColor,
                            unselectedLabelStyle: widget.unselectedLabelStyle,
                            dragStartBehavior: widget.dragStartBehavior,
                            overlayColor: widget.overlayColor,
                            mouseCursor: widget.mouseCursor,
                            enableFeedback: widget.enableFeedback,
                            onTap: widget.onTap,
                            physics: widget.physics,
                            splashFactory: widget.splashFactory,
                            splashBorderRadius: widget.splashBorderRadius,
                            tabAlignment: widget.tabAlignment,
                          ),
                ),
                if (widget.isScrollable == true && widget.showNextIcon == true)
                  IconButton(
                    icon:
                        widget.nextIcon ?? const Icon(Icons.arrow_forward_ios),
                    onPressed: _moveToNextTab,
                  ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: widget.physicsTabBarView,
                dragStartBehavior: widget.dragStartBehaviorTabBarView,
                viewportFraction: widget.viewportFractionTabBarView,
                clipBehavior: widget.clipBehaviorTabBarView,
                children: widget.dynamicTabs.map((tab) => tab.content).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _moveToTab(int index) {
    if (_tabController != null &&
        index >= 0 &&
        index < _tabController!.length) {
      _tabController!.animateTo(index);
    }
    setState(() {
      activeTab = index;
    });
    widget.onTabChanged!(index);
  }

  _moveToNextTab() {
    if (_tabController != null &&
        _tabController!.index + 1 < _tabController!.length) {
      _moveToTab(_tabController!.index + 1);
    }
  }

  _moveToPreviousTab() {
    if (_tabController != null && _tabController!.index > 0) {
      _moveToTab(_tabController!.index - 1);
    }
  }
}
