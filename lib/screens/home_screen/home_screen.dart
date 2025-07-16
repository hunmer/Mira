import 'package:mira/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../core/plugin_base.dart';
import '../../widgets/app_drawer.dart';
import '../../main.dart';
import 'card_size.dart';
import 'card_size_manager.dart';
import 'plugin_order_manager.dart';
import 'plugin_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  late Future<List<PluginBase>> _pluginsFuture;
  final CardSizeManager _cardSizeManager = CardSizeManager();
  final PluginOrderManager _pluginOrderManager = PluginOrderManager();
  final bool _isReorderMode = false;

  // 是否是首次加载，使用静态变量确保在热重载时保持状态
  static bool _hasInitialized = false;

  // 显示卡片大小调整对话框
  void _showCardSizeDialog(BuildContext context, PluginBase plugin) {
    if (_isReorderMode) return;

    final currentSize = _cardSizeManager.getCardSize(plugin.id);
    int currentWidth = currentSize.width;
    int currentHeight = currentSize.height;
    final int maxColumns =
        (MediaQuery.of(context).size.width / 150).floor(); // 假设每列最小宽度为150

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.adjustCardSize),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.width),
                      Expanded(
                        child: Slider(
                          min: 1,
                          max: maxColumns.toDouble(),
                          divisions: maxColumns - 1,
                          value: currentWidth.toDouble(),
                          label: currentWidth.toString(),
                          onChanged: (double value) {
                            setState(() {
                              currentWidth = value.round();
                            });
                          },
                        ),
                      ),
                      Text('$currentWidth'),
                    ],
                  ),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.height),
                      Expanded(
                        child: Slider(
                          min: 1,
                          max: 4,
                          divisions: 3,
                          value: currentHeight.toDouble(),
                          label: currentHeight.toString(),
                          onChanged: (double value) {
                            setState(() {
                              currentHeight = value.round();
                            });
                          },
                        ),
                      ),
                      Text('$currentHeight'),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(AppLocalizations.of(context)!.cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context)!.ok),
                  onPressed: () {
                    // 关闭对话框
                    Navigator.of(context).pop();

                    // 使用外部的setState更新HomeScreen状态
                    this.setState(() {
                      _cardSizeManager.cardSizes[plugin.id] = CardSize(
                        width: currentWidth,
                        height: currentHeight,
                      );
                      _cardSizeManager.saveCardSizes();
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _pluginsFuture = _initializePlugins();

    // 延迟初始化，确保在布局完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 首次加载时打开最后使用的插件
        if (!_hasInitialized) {
          _hasInitialized = true;
        }
      }
    });
  }

  Future<List<PluginBase>> _initializePlugins() async {
    await Future.wait([
      _cardSizeManager.loadCardSizes(),
      _pluginOrderManager.loadPluginOrder(),
    ]);
    return globalPluginManager.allPlugins;
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      // 更新插件顺序
      _pluginOrderManager.updatePluginOrder(oldIndex, newIndex);
      _pluginOrderManager.savePluginOrder();
    });
  }

  @override
  void didPopNext() {
    // 当从其他页面返回到HomeScreen时触发
    super.didPopNext();
    setState(() {
      _pluginsFuture = _initializePlugins();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.home),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          // IconButton(
          //   icon: Icon(_isReorderMode ? Icons.done : Icons.sort),
          //   onPressed: () {
          //     setState(() {
          //       _isReorderMode = !_isReorderMode;
          //     });
          //   },
          // ),
        ],
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<PluginBase>>(
        future: _pluginsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noPluginsAvailable),
            );
          }

          return PluginGrid(
            plugins: snapshot.data!,
            isReorderMode: _isReorderMode,
            cardSizes: _cardSizeManager.cardSizes,
            pluginOrder: _pluginOrderManager.pluginOrder,
            onReorder: _handleReorder,
            onShowCardSizeMenu: _showCardSizeDialog,
          );
        },
      ),
    );
  }
}
