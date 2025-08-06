import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:mira/core/storage/storage_manager.dart';
import 'dock_manager.dart';
import 'dock_layout_preset_dialog.dart';

/// DockLayoutController - 专门管理Dock布局的控制器
/// 负责布局的保存、加载、恢复、预设管理等所有布局相关操作
class DockLayoutController extends ChangeNotifier {
  final String dockTabsId;
  bool _isLayoutLoading = false;

  // 存储管理相关
  StorageManager? _storageManager;
  bool _isStorageInitialized = false;

  DockLayoutController({required this.dockTabsId});

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
        } else {
          print(
            'DockLayoutController: No saved docking data found for $savedLayoutId',
          );
        }
      } else {
        // 如果没有指定savedLayoutId，也尝试加载当前dockTabsId的DockingData
        final savedDockingData = await _loadDockingData();
        if (savedDockingData != null) {
          print(
            'DockLayoutController: Found docking data for current dockTabsId',
          );
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
      return false;
    }

    try {
      final layoutId = '${dockTabsId}_layout';
      await _storageManager!.writeJson(layoutId, layoutString);
      print('DockLayoutController: Layout saved successfully');

      // 同时保存 DockingData
      await _saveDockingData();

      notifyListeners();
      return true;
    } catch (e) {
      print('DockLayoutController: Error saving layout: $e');
      return false;
    }
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
      print('DockLayoutController: DockingData saved successfully');
      return true;
    } catch (e) {
      print('DockLayoutController: Error saving docking data: $e');
      return false;
    }
  }

  /// 读取 DockingData
  Future<Map<String, dynamic>?> _loadDockingData() async {
    try {
      final dockingDataId = '${dockTabsId}_docking_data';
      final dockingData = await _storageManager!.readJson(dockingDataId, null);

      if (dockingData != null && dockingData is Map<String, dynamic>) {
        print('DockLayoutController: DockingData loaded successfully');
        return dockingData;
      } else {
        print('DockLayoutController: No docking data found');
        return null;
      }
    } catch (e) {
      print('DockLayoutController: Error loading docking data: $e');
      return null;
    }
  }

  /// 加载布局
  Future<String?> loadLayout() async {
    try {
      _isLayoutLoading = true;
      notifyListeners();

      final layoutId = '${dockTabsId}_layout';
      final layoutString = await _storageManager!.readJson(layoutId, null);

      if (layoutString != null && layoutString is String) {
        print('DockLayoutController: Layout loaded successfully');
        return layoutString;
      } else {
        print('DockLayoutController: No layout found');
        return null;
      }
    } catch (e) {
      print('DockLayoutController: Error loading layout: $e');
      return null;
    } finally {
      _isLayoutLoading = false;
      notifyListeners();
    }
  }

  /// 加载完整的布局（包括DockingData和Layout字符串）
  Future<bool> loadCompleteLayout() async {
    try {
      _isLayoutLoading = true;
      notifyListeners();

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

      return dockingData != null; // 如果至少有DockingData就认为成功
    } catch (e) {
      print('DockLayoutController: Error loading complete layout: $e');
      return false;
    } finally {
      _isLayoutLoading = false;
      notifyListeners();
    }
  }

  /// 从指定的布局字符串加载布局
  bool loadLayoutFromString(String layoutString) {
    if (layoutString.isEmpty) {
      return false;
    }

    try {
      _isLayoutLoading = true;
      notifyListeners();

      // 直接应用布局字符串，不通过存储
      final dockTabs = DockManager.getDockTabs(dockTabsId);
      if (dockTabs == null) {
        print('DockLayoutController: DockTabs not found for $dockTabsId');
        return false;
      }

      final success = dockTabs.loadLayout(layoutString);
      if (success) {
        print('DockLayoutController: Layout loaded from string successfully');
      } else {
        print('DockLayoutController: Failed to load layout from string');
      }

      return success;
    } catch (e) {
      print('DockLayoutController: Error loading layout from string: $e');
      return false;
    } finally {
      _isLayoutLoading = false;
      notifyListeners();
    }
  }

  /// 重置布局为默认状态
  Future<bool> resetToDefaultLayout() async {
    try {
      _isLayoutLoading = true;
      notifyListeners();

      // 清除保存的布局字符串
      final layoutId = '${dockTabsId}_layout';
      await _storageManager!.writeJson(layoutId, null);

      // 清除保存的 DockingData
      final dockingDataId = '${dockTabsId}_docking_data';
      await _storageManager!.writeJson(dockingDataId, null);

      print('DockLayoutController: Reset to default layout successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('DockLayoutController: Error resetting to default layout: $e');
      return false;
    } finally {
      _isLayoutLoading = false;
      notifyListeners();
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
      return true;
    } catch (e) {
      print('DockLayoutController: Error saving layout as preset: $e');
      return false;
    }
  }

  /// 从预设加载布局
  Future<bool> loadLayoutFromPreset(String presetId) async {
    try {
      _isLayoutLoading = true;
      notifyListeners();

      // 获取所有预设并找到指定的预设
      final presets = await LayoutPresetManager.getAllPresets();
      final preset = presets.firstWhereOrNull((p) => p.id == presetId);
      if (preset == null) {
        return false;
      }
      final success = loadLayoutFromString(preset.layoutData);

      if (success) {
        print(
          'DockLayoutController: Loaded layout from preset: ${preset.name}',
        );
      }

      return success;
    } catch (e) {
      print('DockLayoutController: Error loading layout from preset: $e');
      return false;
    } finally {
      _isLayoutLoading = false;
      notifyListeners();
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
      return true;
    } catch (e) {
      print('DockLayoutController: Error deleting preset: $e');
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

  @override
  void dispose() {
    super.dispose();
  }
}
