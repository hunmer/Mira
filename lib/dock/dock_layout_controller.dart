import 'dart:async';
import 'package:collection/collection.dart';
import 'package:mira/core/storage/storage_manager.dart';
import 'dock_manager.dart';
import 'dock_layout_preset_dialog.dart';
import 'dock_events.dart';

/// DockLayoutController - 专门管理Dock布局的控制器
/// 负责布局的保存、加载、恢复、预设管理等所有布局相关操作
class DockLayoutController {
  final String dockTabsId;
  bool _isLayoutLoading = false;

  // 存储管理相关
  StorageManager? _storageManager;
  bool _isStorageInitialized = false;

  // 事件流控制器
  late DockEventStreamController _eventStreamController;

  DockLayoutController({required this.dockTabsId}) {
    _eventStreamController = DockEventStreamController(
      id: '${dockTabsId}_layout',
    );
  }

  /// 事件流
  Stream<DockEvent> get eventStream => _eventStreamController.stream;

  /// 发射事件
  void _emitEvent(DockEventType type, {Map<String, dynamic> data = const {}}) {
    final event = DockLayoutControllerEvent(
      type: type,
      dockTabsId: dockTabsId,
      data: data,
    );
    _eventStreamController.emit(event);
  }

  /// 是否正在加载布局
  bool get isLayoutLoading => _isLayoutLoading;

  /// 获取当前布局数据
  static Future<String?> getLayoutData(String dockTabsId) async {
    try {
      // 从DockManager获取当前DockTabs实例
      final dockTabs = DockManager.getDockTabs(dockTabsId);
      if (dockTabs == null) {
        print('无法找到DockTabs实例: ${dockTabsId}');
        return null;
      }

      // 获取当前实时的布局数据
      final layoutString = dockTabs.getLayoutString();
      if (layoutString.isEmpty) {
        print('当前布局数据为空');
        return null;
      }

      return layoutString;
    } catch (e) {
      print('获取当前布局数据失败: $e');
      return null;
    }
  }

  /// 初始化布局数据
  /// 返回包含DockingData的initData，如果有的话
  Future<Map<String, dynamic>?> initializeLayoutData({
    String? savedLayoutId,
  }) async {
    Map<String, dynamic>? initData;

    try {
      // 首先检查是否有默认布局预设
      final defaultPreset = await LayoutPresetManager.getDefaultPreset();

      if (defaultPreset != null) {
        print(
          'DockLayoutController: Found default layout preset: ${defaultPreset.name}',
        );
        // 使用默认预设的布局数据，创建基本的initData结构
        initData = {'layout': defaultPreset.layoutData};
      } else if (savedLayoutId != null) {
        // 尝试加载保存的 DockingData
        final savedDockingData = await _loadDockingData();
        if (savedDockingData != null) {
          print('DockLayoutController: Found docking data for $savedLayoutId');
          initData = savedDockingData;
        }
      } else {
        // 如果没有指定savedLayoutId，也尝试加载当前dockTabsId的DockingData
        final savedDockingData = await _loadDockingData();
        if (savedDockingData != null) {
          initData = savedDockingData;
        }
      }
    } catch (e) {
      print('DockLayoutController: Error loading layout data: $e');
    }

    return initData;
  }

  /// 保存当前布局 - 传递 string 直接 JSON 写入
  Future<bool> saveLayout(String layoutString) async {
    if (layoutString.isEmpty) {
      _emitEvent(DockEventType.layoutSaved, data: {'success': false});
      return false;
    }
    try {
      final layoutId = '${dockTabsId}_layout';
      await _storageManager!.writeJson(layoutId, layoutString);
      await _saveDockingData();
      _emitEvent(
        DockEventType.layoutSaved,
        data: {'success': true, 'layoutData': layoutString},
      );
      return true;
    } catch (e) {
      print('DockLayoutController: Error saving layout: $e');
      _emitEvent(DockEventType.layoutSaved, data: {'success': false});
    }
    return false;
  }

  /// 保存 DockingData 到单独的文件
  Future<bool> _saveDockingData() async {
    try {
      final dockTabs = DockManager.getDockTabs(dockTabsId);
      if (dockTabs == null) {
        print(
          'DockLayoutController: DockTabs not found for saving docking data',
        );
        return false;
      }
      final dockingDataId = '${dockTabsId}_docking_data';
      final dockingData = dockTabs.toJson();
      await _storageManager!.writeJson(dockingDataId, dockingData);
      return true;
    } catch (e) {
      print('DockLayoutController: Error saving docking data: $e');
    }
    return false;
  }

  /// 读取 DockingData
  Future<Map<String, dynamic>?> _loadDockingData() async {
    try {
      final dockingDataId = '${dockTabsId}_docking_data';
      final dockingData = await _storageManager!.readJson(dockingDataId, null);

      if (dockingData != null && dockingData is Map<String, dynamic>) {
        print('DockLayoutController: DockingData loaded successfully');
        return dockingData;
      }
    } catch (e) {
      print('DockLayoutController: Error loading docking data: $e');
    }
    return null;
  }

  /// 加载布局
  Future<String?> loadLayout() async {
    try {
      _isLayoutLoading = true;
      _emitEvent(DockEventType.layoutLoading, data: {'isLoading': true});

      final layoutId = '${dockTabsId}_layout';
      final layoutString = await _storageManager!.readJson(layoutId, null);

      if (layoutString != null && layoutString is String) {
        print('DockLayoutController: Layout loaded successfully');
        _emitEvent(
          DockEventType.layoutLoaded,
          data: {'success': true, 'layoutData': layoutString},
        );
        return layoutString;
      }
      _emitEvent(DockEventType.layoutLoaded, data: {'success': false});
      return '';
    } catch (e) {
      print('DockLayoutController: Error loading layout: $e');
      _emitEvent(DockEventType.layoutLoaded, data: {'success': false});
      return null;
    } finally {
      _isLayoutLoading = false;
      _emitEvent(DockEventType.layoutLoading, data: {'isLoading': false});
    }
  }

  /// 加载完整的布局（包括DockingData和Layout字符串）
  Future<bool> loadCompleteLayout() async {
    try {
      _isLayoutLoading = true;
      _emitEvent(DockEventType.layoutLoading, data: {'isLoading': true});

      // 首先加载 DockingData
      final dockingData = await _loadDockingData();
      if (dockingData != null) {
        final dockTabs = DockManager.getDockTabs(dockTabsId);
        if (dockTabs != null) {
          // 恢复 DockingData
          dockTabs.loadFromJson(dockingData);
          print('DockLayoutController: DockingData restored successfully');
        }
      }

      // 然后加载并应用 Layout 字符串
      final layoutString = await loadLayout();
      if (layoutString != null) {
        loadLayoutFromString(layoutString);
      }

      final success = dockingData != null;
      _emitEvent(DockEventType.layoutLoaded, data: {'success': success});
      return success; // 如果至少有DockingData就认为成功
    } catch (e) {
      print('DockLayoutController: Error loading complete layout: $e');
      _emitEvent(DockEventType.layoutLoaded, data: {'success': false});
      return false;
    } finally {
      _isLayoutLoading = false;
      _emitEvent(DockEventType.layoutLoading, data: {'isLoading': false});
    }
  }

  /// 从指定的布局字符串加载布局
  bool loadLayoutFromString(String layoutString) {
    if (layoutString.isEmpty) {
      return false;
    }

    try {
      _isLayoutLoading = true;
      _emitEvent(DockEventType.layoutLoading, data: {'isLoading': true});

      // 直接应用布局字符串，不通过存储
      final dockTabs = DockManager.getDockTabs(dockTabsId);
      if (dockTabs == null) {
        print('DockLayoutController: DockTabs not found for $dockTabsId');
        _emitEvent(DockEventType.layoutLoaded, data: {'success': false});
        return false;
      }

      final success = dockTabs.loadLayout(layoutString);
      if (success) {
        print('DockLayoutController: Layout loaded from string successfully');
      } else {
        print('DockLayoutController: Failed to load layout from string');
      }

      _emitEvent(
        DockEventType.layoutLoaded,
        data: {'success': success, 'layoutData': layoutString},
      );
      return success;
    } catch (e) {
      print('DockLayoutController: Error loading layout from string: $e');
      _emitEvent(DockEventType.layoutLoaded, data: {'success': false});
      return false;
    } finally {
      _isLayoutLoading = false;
      _emitEvent(DockEventType.layoutLoading, data: {'isLoading': false});
    }
  }

  /// 重置布局为默认状态
  Future<bool> resetToDefaultLayout() async {
    try {
      _isLayoutLoading = true;
      _emitEvent(DockEventType.layoutLoading, data: {'isLoading': true});

      // 清除保存的布局字符串
      final layoutId = '${dockTabsId}_layout';
      await _storageManager!.writeJson(layoutId, null);

      // 清除保存的 DockingData
      final dockingDataId = '${dockTabsId}_docking_data';
      await _storageManager!.writeJson(dockingDataId, null);

      print('DockLayoutController: Reset to default layout successfully');
      _emitEvent(DockEventType.layoutReset, data: {'success': true});
      return true;
    } catch (e) {
      print('DockLayoutController: Error resetting to default layout: $e');
      _emitEvent(DockEventType.layoutReset, data: {'success': false});
      return false;
    } finally {
      _isLayoutLoading = false;
      _emitEvent(DockEventType.layoutLoading, data: {'isLoading': false});
    }
  }

  /// 保存布局到预设
  Future<bool> saveLayoutAsPreset({
    required String presetName,
    String? description,
    bool setAsDefault = false,
  }) async {
    try {
      // 获取当前布局
      final currentLayout = await getLayoutData(dockTabsId);
      if (currentLayout == null || currentLayout.isEmpty) {
        print('DockLayoutController: No current layout to save as preset');
        _emitEvent(
          DockEventType.presetSaved,
          data: {'success': false, 'presetName': presetName},
        );
        return false;
      }

      // 创建预设（只使用LayoutPreset支持的字段）
      final preset = LayoutPreset(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: presetName,
        layoutData: currentLayout,
        createdAt: DateTime.now(),
      );

      // 保存预设
      await LayoutPresetManager.savePreset(preset);

      // 如果需要设为默认，单独处理
      if (setAsDefault) {
        await LayoutPresetManager.setDefaultPreset(preset.id);
      }

      print('DockLayoutController: Saved layout as preset: $presetName');
      _emitEvent(
        DockEventType.presetSaved,
        data: {
          'success': true,
          'presetName': presetName,
          'presetId': preset.id,
        },
      );
      return true;
    } catch (e) {
      print('DockLayoutController: Error saving layout as preset: $e');
      _emitEvent(
        DockEventType.presetSaved,
        data: {'success': false, 'presetName': presetName},
      );
      return false;
    }
  }

  /// 从预设加载布局
  Future<bool> loadLayoutFromPreset(String presetId) async {
    try {
      _isLayoutLoading = true;
      _emitEvent(DockEventType.layoutLoading, data: {'isLoading': true});

      // 获取所有预设并找到指定的预设
      final presets = await LayoutPresetManager.getAllPresets();
      final preset = presets.firstWhereOrNull((p) => p.id == presetId);
      if (preset == null) {
        _emitEvent(
          DockEventType.presetLoaded,
          data: {'success': false, 'presetId': presetId},
        );
        return false;
      }
      final success = loadLayoutFromString(preset.layoutData);

      if (success) {
        print(
          'DockLayoutController: Loaded layout from preset: ${preset.name}',
        );
      }

      _emitEvent(
        DockEventType.presetLoaded,
        data: {
          'success': success,
          'presetId': presetId,
          'presetName': preset.name,
        },
      );
      return success;
    } catch (e) {
      print('DockLayoutController: Error loading layout from preset: $e');
      _emitEvent(
        DockEventType.presetLoaded,
        data: {'success': false, 'presetId': presetId},
      );
      return false;
    } finally {
      _isLayoutLoading = false;
      _emitEvent(DockEventType.layoutLoading, data: {'isLoading': false});
    }
  }

  /// 获取所有可用的布局预设
  Future<List<LayoutPreset>> getAvailablePresets() async {
    try {
      return await LayoutPresetManager.getAllPresets();
    } catch (e) {
      print('DockLayoutController: Error getting available presets: $e');
      return [];
    }
  }

  /// 删除布局预设
  Future<bool> deletePreset(String presetId) async {
    try {
      await LayoutPresetManager.deletePreset(presetId);
      print('DockLayoutController: Deleted preset: $presetId');
      _emitEvent(
        DockEventType.presetDeleted,
        data: {'success': true, 'presetId': presetId},
      );
      return true;
    } catch (e) {
      print('DockLayoutController: Error deleting preset: $e');
      _emitEvent(
        DockEventType.presetDeleted,
        data: {'success': false, 'presetId': presetId},
      );
      return false;
    }
  }

  // ===================== Storage Management =====================

  /// 初始化存储管理器
  Future<void> initializeStorage(StorageManager storageManager) async {
    _storageManager = storageManager;
    _isStorageInitialized = true;
  }

  /// 检查存储是否已初始化
  bool get isStorageInitialized => _isStorageInitialized;

  void dispose() {
    _eventStreamController.dispose();
  }
}
