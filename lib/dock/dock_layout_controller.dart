import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'dock_manager.dart';
import 'dock_tabs.dart';
import 'dock_layout_preset_dialog.dart';

/// DockLayoutController - 专门管理Dock布局的控制器
/// 负责布局的保存、加载、恢复、预设管理等所有布局相关操作
class DockLayoutController extends ChangeNotifier {
  final String dockTabsId;
  String _lastSavedLayout = '';
  String? _pendingLayoutData;
  bool _isLayoutLoading = false;

  // 防抖相关 - 使用 RxDart
  final PublishSubject<void> _saveLayoutSubject = PublishSubject<void>();
  final PublishSubject<String> _layoutChangedSubject = PublishSubject<String>();
  late final StreamSubscription _saveLayoutSubscription;
  late final StreamSubscription _layoutChangedSubscription;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  DockLayoutController({required this.dockTabsId}) {
    // 初始化防抖订阅
    _saveLayoutSubscription = _saveLayoutSubject
        .debounceTime(_debounceDuration)
        .listen((_) => _performImmediateSave());

    _layoutChangedSubscription = _layoutChangedSubject
        .debounceTime(_debounceDuration)
        .listen((eventDockTabsId) => _performLayoutSave(eventDockTabsId));
  }

  /// 获取上次保存的布局
  String get lastSavedLayout => _lastSavedLayout;

  /// 是否有有效的保存布局
  bool get hasValidSavedLayout => _lastSavedLayout.isNotEmpty;

  /// 是否正在加载布局
  bool get isLayoutLoading => _isLayoutLoading;

  /// 设置待处理的布局数据
  void setPendingLayoutData(String? layoutData) {
    _pendingLayoutData = layoutData;
  }

  /// 获取待处理的布局数据
  String? get pendingLayoutData => _pendingLayoutData;

  /// 初始化布局数据
  /// 返回包含布局数据的initData，如果有的话
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
        // 使用默认预设的布局数据
        _pendingLayoutData = defaultPreset.layoutData;
        initData = {'layout': defaultPreset.layoutData};
      } else if (savedLayoutId != null) {
        final savedData = DockManager.getStoredLayout(savedLayoutId);
        if (savedData != null) {
          try {
            // 尝试解析为完整的布局数据（新格式）
            final layoutData = json.decode(savedData) as Map<String, dynamic>;

            if (layoutData.containsKey('dockTabsData')) {
              // 这是新格式的完整布局数据，直接使用dockTabsData
              final dockTabsData =
                  layoutData['dockTabsData'] as Map<String, dynamic>;
              print(
                'DockLayoutController: Found complete layout data for $savedLayoutId',
              );

              // 提取布局字符串用于后续应用
              if (layoutData.containsKey('layoutString')) {
                _pendingLayoutData = layoutData['layoutString'] as String;
              }

              initData = dockTabsData;
            }
          } catch (jsonError) {
            // 如果JSON解析失败，当作纯布局字符串处理（兼容旧格式）
            print(
              'DockLayoutController: Found layout string for $savedLayoutId, length: ${savedData.length}',
            );
            _pendingLayoutData = savedData;
            initData = {'layout': savedData};
          }
        } else {
          print(
            'DockLayoutController: No saved layout found for $savedLayoutId',
          );
        }
      }
    } catch (e) {
      print('DockLayoutController: Error loading default preset: $e');
    }

    return initData;
  }

  /// 应用待处理的布局数据到DockTabs
  bool applyPendingLayout(DockTabs? dockTabs) {
    if (dockTabs == null || _pendingLayoutData == null) {
      return false;
    }

    try {
      _isLayoutLoading = true;
      notifyListeners();

      print('DockLayoutController: Applying pending layout data...');
      final success = dockTabs.loadLayout(_pendingLayoutData!);

      if (success) {
        _lastSavedLayout = _pendingLayoutData!;
        _pendingLayoutData = null; // 清除待处理数据
      }

      return success;
    } catch (e) {
      print('DockLayoutController: Error applying pending layout: $e');
      return false;
    } finally {
      _isLayoutLoading = false;
      notifyListeners();
    }
  }

  /// 保存当前布局
  bool saveLayout({bool useDebounce = false}) {
    if (useDebounce) {
      // 使用 RxDart 防抖保存
      _saveLayoutSubject.add(null);
      return true; // 防抖模式下总是返回true，实际结果在异步回调中
    } else {
      // 立即保存
      return _performImmediateSave();
    }
  }

  /// 执行立即保存操作
  bool _performImmediateSave() {
    try {
      final success = DockManager.saveLayoutForDockTabs(dockTabsId);
      if (success) {
        // 从存储中获取实际的布局字符串用于设置_lastSavedLayout
        final storedData = DockManager.getStoredLayout('${dockTabsId}_layout');
        if (storedData != null) {
          try {
            // 尝试解析为完整的布局数据
            final layoutData = json.decode(storedData) as Map<String, dynamic>;
            if (layoutData.containsKey('layoutString')) {
              _lastSavedLayout = layoutData['layoutString'] as String;
            } else {
              _lastSavedLayout = storedData; // 兼容旧格式
            }
          } catch (jsonError) {
            // JSON解析失败，直接使用原始数据（兼容旧格式）
            _lastSavedLayout = storedData;
          }
        } else {
          _lastSavedLayout = '';
        }
        print('DockLayoutController: Layout saved successfully');
        notifyListeners();
      } else {
        print('DockLayoutController: Failed to save layout');
      }
      return success;
    } catch (e) {
      print('DockLayoutController: Error saving layout: $e');
      return false;
    }
  }

  /// 强制执行待处理的防抖保存操作
  void flushPendingSave() {
    // 在 RxDart 防抖模式下，直接执行保存
    // 因为 RxDart 会自动处理防抖，我们只需要强制执行一次保存
    _performImmediateSave();
  }

  /// 加载布局
  bool loadLayout() {
    try {
      _isLayoutLoading = true;
      notifyListeners();

      final success = DockManager.loadLayoutForDockTabs(dockTabsId);
      if (success) {
        // 从存储中获取实际的布局字符串用于设置_lastSavedLayout
        final storedData = DockManager.getStoredLayout('${dockTabsId}_layout');
        if (storedData != null) {
          try {
            // 尝试解析为完整的布局数据
            final layoutData = json.decode(storedData) as Map<String, dynamic>;
            if (layoutData.containsKey('layoutString')) {
              _lastSavedLayout = layoutData['layoutString'] as String;
            } else {
              _lastSavedLayout = storedData; // 兼容旧格式
            }
          } catch (jsonError) {
            // JSON解析失败，直接使用原始数据（兼容旧格式）
            _lastSavedLayout = storedData;
          }
        } else {
          _lastSavedLayout = '';
        }
        print('DockLayoutController: Layout loaded successfully');
      } else {
        print('DockLayoutController: Failed to load layout');
      }

      return success;
    } catch (e) {
      print('DockLayoutController: Error loading layout: $e');
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
        _lastSavedLayout = layoutString;
        print('DockLayoutController: Layout loaded from string successfully');

        // 触发自动保存，让正常的保存机制来处理数据的持久化
        // 这将确保以正确的JSON格式保存
        DockManager.saveLayoutForDockTabs(dockTabsId);
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
  bool resetToDefaultLayout() {
    try {
      _isLayoutLoading = true;
      notifyListeners();

      // 清除保存的布局
      DockManager.clearStoredLayout('${dockTabsId}_layout');
      _lastSavedLayout = '';
      _pendingLayoutData = null;

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
      final currentLayout = DockManager.getStoredLayout('${dockTabsId}_layout');
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

  /// 处理布局变化事件（由DockController调用）
  void handleLayoutChanged(String eventDockTabsId) {
    if (eventDockTabsId == dockTabsId) {
      // 使用 RxDart 防抖来避免频繁保存布局
      _layoutChangedSubject.add(eventDockTabsId);
    }
  }

  /// 执行实际的布局保存操作
  void _performLayoutSave(String eventDockTabsId) {
    // 自动保存布局
    final success = DockManager.saveLayoutForDockTabs(eventDockTabsId);
    if (success) {
      // 从存储中获取实际的布局字符串用于设置_lastSavedLayout
      final storedData = DockManager.getStoredLayout(
        '${eventDockTabsId}_layout',
      );
      if (storedData != null) {
        try {
          // 尝试解析为完整的布局数据
          final layoutData = json.decode(storedData) as Map<String, dynamic>;
          if (layoutData.containsKey('layoutString')) {
            _lastSavedLayout = layoutData['layoutString'] as String;
          } else {
            _lastSavedLayout = storedData; // 兼容旧格式
          }
        } catch (jsonError) {
          // JSON解析失败，直接使用原始数据（兼容旧格式）
          _lastSavedLayout = storedData;
        }
      } else {
        _lastSavedLayout = '';
      }
      notifyListeners();
      print(
        'DockLayoutController: Layout auto-saved with debounce for $eventDockTabsId',
      );
    }
  }

  /// 获取布局统计信息
  Map<String, dynamic> getLayoutStats() {
    return {
      'dockTabsId': dockTabsId,
      'hasValidSavedLayout': hasValidSavedLayout,
      'lastSavedLayoutLength': _lastSavedLayout.length,
      'hasPendingLayout': _pendingLayoutData != null,
      'pendingLayoutLength': _pendingLayoutData?.length ?? 0,
      'isLayoutLoading': _isLayoutLoading,
    };
  }

  @override
  void dispose() {
    _saveLayoutSubscription.cancel();
    _layoutChangedSubscription.cancel();
    _saveLayoutSubject.close();
    _layoutChangedSubject.close();
    _pendingLayoutData = null;
    super.dispose();
  }
}
