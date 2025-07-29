import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:flutter/material.dart';

class HotKeyService {
  static final HotKeyService _instance = HotKeyService._internal();
  factory HotKeyService() => _instance;
  HotKeyService._internal();

  final Map<String, HotKeyConfig> _hotKeys = {};
  final Map<String, VoidCallback> _actions = {};
  void initDefaultHotKeys() {
    registerAction(
      'restart_app',
      'Restart Application',
      () {
        // 重启应用逻辑
      },
      defaultHotKey: HotKey(
        key: PhysicalKeyboardKey.keyR,
        modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
        scope: HotKeyScope.inapp,
      ),
    );

    registerAction(
      'bring_to_front',
      'Bring to Front',
      () {
        // 窗口置前逻辑
      },
      defaultHotKey: HotKey(
        key: PhysicalKeyboardKey.keyF,
        modifiers: [HotKeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
    );

    registerAction(
      'refresh_app',
      'Refresh Application',
      () {
        // 刷新应用逻辑
      },
      defaultHotKey: HotKey(
        key: PhysicalKeyboardKey.keyR,
        modifiers: [HotKeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
    );

    registerAction(
      'open_web_page',
      'Open Web Page',
      () {
        // 打开网页逻辑
        _openWebPage('https://example.com');
      },
      defaultHotKey: HotKey(
        key: PhysicalKeyboardKey.keyW,
        modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
        scope: HotKeyScope.inapp,
      ),
    );
  }

  void _openWebPage(String url) async {
    try {
      // 使用url_launcher或其他方式打开网页
      // 示例: await launchUrl(Uri.parse(url));
    } catch (e) {
      debugPrint('Failed to open web page: $e');
    }
  }

  void registerAction(
    String id,
    String name,
    VoidCallback action, {
    HotKey? defaultHotKey,
  }) {
    _actions[id] = action;
    if (defaultHotKey != null) {
      _hotKeys[id] = HotKeyConfig(id: id, name: name, hotKey: defaultHotKey);
    }
  }

  Future<void> registerHotKey(String id, HotKey hotKey) async {
    if (_hotKeys.containsKey(id)) {
      await hotKeyManager.unregister(_hotKeys[id]!.hotKey);
    }

    _hotKeys[id] = HotKeyConfig(
      id: id,
      name: _hotKeys[id]?.name ?? id,
      hotKey: hotKey,
    );

    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (_) => _actions[id]?.call(),
    );
  }

  Future<void> unregisterHotKey(String id) async {
    if (_hotKeys.containsKey(id)) {
      await hotKeyManager.unregister(_hotKeys[id]!.hotKey);
      _hotKeys.remove(id);
    }
  }

  List<HotKeyConfig> getAllHotKeys() {
    return _hotKeys.values.toList();
  }

  Future<void> resetAllHotKeys() async {
    await hotKeyManager.unregisterAll();
    _hotKeys.clear();
    initDefaultHotKeys();
  }
}

class HotKeyConfig {
  final String id;
  final String name;
  final HotKey hotKey;

  HotKeyConfig({required this.id, required this.name, required this.hotKey});
}
