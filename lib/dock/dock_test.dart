import 'package:flutter/material.dart';
import 'dock_controller.dart';
import 'context_menu_wrapper.dart';
import 'demo_data.dart';

void main() {
  runApp(const DockingExampleApp());
}

class DockingExampleApp extends StatelessWidget {
  const DockingExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Docking example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DockingExamplePage(),
    );
  }
}

class DockingExamplePage extends StatefulWidget {
  const DockingExamplePage({Key? key}) : super(key: key);

  @override
  DockingExamplePageState createState() => DockingExamplePageState();
}

class DockingExamplePageState extends State<DockingExamplePage> {
  late DockController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DockController();
    _controller.addListener(_onControllerChanged);
    _controller.initializeDockSystem();
  }

  void _onControllerChanged() {
    setState(() {
      // 控制器状态变化时更新UI
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dock Management System'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLayout,
            tooltip: 'Save Layout',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _controller.hasValidSavedLayout ? _loadLayout : null,
            tooltip: 'Load Layout',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddItemDialog,
            tooltip: 'Add Item',
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: _loadDemoData,
            tooltip: 'Load Demo',
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showStatistics,
            tooltip: 'Statistics',
          ),
        ],
      ),
      body: ContextMenuWrapper(
        itemName: 'Main Workspace',
        itemType: 'workspace',
        onSaveLayout: _saveLayout,
        customActions: {
          '加载演示数据': _loadDemoData,
          '清空所有内容': _clearAllContent,
          '重置布局': _resetLayout,
        },
        child: _controller.dockTabs.buildDockingWidget(context),
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields, color: Colors.blue),
              title: const Text('Text Item'),
              subtitle: const Text('Add a text display panel'),
              onTap: () {
                Navigator.pop(context);
                _controller.addTextItem();
                _showSuccessMessage('Added text item');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('Counter Item'),
              subtitle: const Text('Add a counter widget'),
              onTap: () {
                Navigator.pop(context);
                _controller.addCounterItem();
                _showSuccessMessage('Added counter item');
              },
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Colors.orange),
              title: const Text('List Item'),
              subtitle: const Text('Add a list manager'),
              onTap: () {
                Navigator.pop(context);
                _controller.addListItem();
                _showSuccessMessage('Added list item');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatistics() {
    final stats = _controller.getStatistics();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Text('Statistics'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('DockTabs', '${stats['dockTabs']}', Icons.tab),
            _buildStatRow('Tabs', '${stats['tabs']}', Icons.folder),
            _buildStatRow('Items', '${stats['items']}', Icons.widgets),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: '),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// 保存布局
  void _saveLayout() {
    final success = _controller.saveLayout();
    if (success) {
      _showSuccessMessage('Layout saved successfully');
    } else {
      _showErrorMessage('Failed to save layout');
    }
  }

  /// 加载布局
  void _loadLayout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Layout'),
        content: const Text(
          'Are you sure you want to load the saved layout? This will replace the current layout.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLoadLayout();
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }

  /// 执行加载布局
  void _performLoadLayout() {
    final success = _controller.loadLayout();
    if (success) {
      _showSuccessMessage('Layout loaded successfully');
    } else {
      _showErrorMessage('Failed to load layout');
    }
  }

  /// 加载演示数据
  void _loadDemoData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Demo Data'),
        content: const Text(
          'This will add demonstration content to your workspace. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              DemoData.createDemoEnvironment();
              _showSuccessMessage('Demo data loaded');
            },
            child: const Text('Load Demo'),
          ),
        ],
      ),
    );
  }

  /// 清空所有内容
  void _clearAllContent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Clear All Content'),
          ],
        ),
        content: const Text(
          'This will remove all tabs and items. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.dispose();
              _controller = DockController();
              _controller.addListener(_onControllerChanged);
              _controller.initializeDockSystem();
              _showSuccessMessage('All content cleared');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  /// 重置布局
  void _resetLayout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Layout'),
        content: const Text(
          'This will reset the layout to default arrangement while keeping all content. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 这里可以实现重置布局的逻辑
              _showSuccessMessage('Layout reset');
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }
}
