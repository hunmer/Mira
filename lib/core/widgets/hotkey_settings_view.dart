import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import '../services/hotkey_service.dart';

class HotKeySettingsView extends StatefulWidget {
  const HotKeySettingsView({super.key});

  @override
  State<HotKeySettingsView> createState() => _HotKeySettingsViewState();
}

class _HotKeySettingsViewState extends State<HotKeySettingsView> {
  final HotKeyService _hotKeyService = HotKeyService();
  List<HotKeyConfig> _hotKeys = [];

  @override
  void initState() {
    super.initState();
    _hotKeyService.initDefaultHotKeys();
    _loadHotKeys();
  }

  void _loadHotKeys() {
    setState(() {
      _hotKeys = _hotKeyService.getAllHotKeys();
    });
  }

  Future<void> _updateHotKey(String id, HotKey? newHotKey) async {
    if (newHotKey != null) {
      await _hotKeyService.registerHotKey(id, newHotKey);
      _loadHotKeys();
    }
  }

  Future<void> _resetHotKey(String id) async {
    final action = _hotKeyService.getAllHotKeys().firstWhere(
      (element) => element.id == id,
    );
    if (action != null) {
      await _hotKeyService.unregisterHotKey(id);
      _loadHotKeys();
    }
  }

  Future<void> _resetAllHotKeys() async {
    await _hotKeyService.resetAllHotKeys();
    _loadHotKeys();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shortcut Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset all shortcuts',
            onPressed: _resetAllHotKeys,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _hotKeys.length,
        itemBuilder: (context, index) {
          final hotKeyConfig = _hotKeys[index];
          return ListTile(
            title: Text(hotKeyConfig.name),
            subtitle: Text(hotKeyConfig.hotKey.toString()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit shortcut',
                  onPressed: () => _showEditDialog(context, hotKeyConfig),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Remove shortcut',
                  onPressed: () => _resetHotKey(hotKeyConfig.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: 'Add new shortcut',
        onPressed: () => _showAddDialog(context),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    HotKeyConfig config,
  ) async {
    HotKey? newHotKey;
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit ${config.name}'),
            content: HotKeyRecorder(
              onHotKeyRecorded: (hotKey) => newHotKey = hotKey,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (newHotKey != null) {
                    _updateHotKey(config.id, newHotKey!);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    String? selectedActionId;
    HotKey? newHotKey;
    final availableActions = _hotKeyService.getAllHotKeys().toList();

    if (availableActions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available actions to add')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Add New Shortcut'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedActionId,
                      hint: const Text('Select action'),
                      items:
                          availableActions.map((action) {
                            return DropdownMenuItem<String>(
                              value: action.id,
                              child: Text(action.name),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedActionId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    if (selectedActionId != null)
                      HotKeyRecorder(
                        onHotKeyRecorded: (hotKey) => newHotKey = hotKey,
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed:
                        selectedActionId != null && newHotKey != null
                            ? () {
                              Navigator.pop(context);
                              _updateHotKey(selectedActionId!, newHotKey!);
                            }
                            : null,
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          ),
    );
  }
}
