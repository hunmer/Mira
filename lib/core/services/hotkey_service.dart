import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Conditional import for web compatibility
import 'hotkey_service_stub.dart' as html if (dart.library.html) 'dart:html';

// Web平台自定义热键实现
class WebHotKeyManager {
  static final WebHotKeyManager _instance = WebHotKeyManager._internal();
  factory WebHotKeyManager() => _instance;
  WebHotKeyManager._internal();

  final Map<String, WebHotKey> _registeredHotKeys = {};
  final Map<String, Function(WebHotKey)> _keyDownHandlers = {};

  void init() {
    if (kIsWeb) {
      html.document.addEventListener('keydown', _handleKeyDown);
    }
  }

  void _handleKeyDown(html.Event event) {
    final keyEvent = event as html.KeyboardEvent;

    for (final entry in _registeredHotKeys.entries) {
      final hotKey = entry.value;
      final handler = _keyDownHandlers[entry.key];

      if (_matchesHotKey(keyEvent, hotKey)) {
        event.preventDefault();
        handler?.call(hotKey);
        break;
      }
    }
  }

  bool _matchesHotKey(html.KeyboardEvent event, WebHotKey hotKey) {
    if (event.code != hotKey.key.keyCode) return false;

    final hasCtrl = hotKey.modifiers.contains(WebHotKeyModifier.control);
    final hasShift = hotKey.modifiers.contains(WebHotKeyModifier.shift);
    final hasAlt = hotKey.modifiers.contains(WebHotKeyModifier.alt);
    final hasMeta = hotKey.modifiers.contains(WebHotKeyModifier.meta);

    return event.ctrlKey == hasCtrl &&
        event.shiftKey == hasShift &&
        event.altKey == hasAlt &&
        event.metaKey == hasMeta;
  }

  Future<void> register(
    WebHotKey hotKey, {
    Function(WebHotKey)? keyDownHandler,
  }) async {
    final id = hotKey.toString();
    _registeredHotKeys[id] = hotKey;
    if (keyDownHandler != null) {
      _keyDownHandlers[id] = keyDownHandler;
    }
  }

  Future<void> unregister(WebHotKey hotKey) async {
    final id = hotKey.toString();
    _registeredHotKeys.remove(id);
    _keyDownHandlers.remove(id);
  }

  Future<void> unregisterAll() async {
    _registeredHotKeys.clear();
    _keyDownHandlers.clear();
  }
}

enum WebHotKeyModifier { control, shift, alt, meta }

enum WebHotKeyScope { inapp, system }

class WebHotKey {
  final WebPhysicalKey key;
  final List<WebHotKeyModifier> modifiers;
  final WebHotKeyScope scope;

  WebHotKey({
    required this.key,
    this.modifiers = const [],
    this.scope = WebHotKeyScope.inapp,
  });

  @override
  String toString() {
    final modifierStr = modifiers.map((m) => m.name).join('+');
    return modifierStr.isEmpty ? key.keyCode : '$modifierStr+${key.keyCode}';
  }
}

class WebPhysicalKey {
  final String keyCode;

  const WebPhysicalKey(this.keyCode);

  static const keyR = WebPhysicalKey('KeyR');
  static const keyF = WebPhysicalKey('KeyF');
  static const keyW = WebPhysicalKey('KeyW');
}

// 兼容原有的hotkey_manager接口
typedef HotKey = WebHotKey;
typedef HotKeyModifier = WebHotKeyModifier;
typedef HotKeyScope = WebHotKeyScope;

class HotKeyManagerWrapper {
  final WebHotKeyManager _webManager = WebHotKeyManager();

  Future<void> register(
    dynamic hotKey, {
    Function(dynamic)? keyDownHandler,
  }) async {
    if (kIsWeb) {
      await _webManager.register(
        hotKey as WebHotKey,
        keyDownHandler: keyDownHandler,
      );
    }
  }

  Future<void> unregister(dynamic hotKey) async {
    if (kIsWeb) {
      await _webManager.unregister(hotKey as WebHotKey);
    }
  }

  Future<void> unregisterAll() async {
    if (kIsWeb) {
      await _webManager.unregisterAll();
    }
  }
}

final hotKeyManager = HotKeyManagerWrapper();

class HotKeyService {
  static final HotKeyService _instance = HotKeyService._internal();
  factory HotKeyService() => _instance;
  HotKeyService._internal();

  final Map<String, HotKeyConfig> _hotKeys = {};
  final Map<String, VoidCallback> _actions = {};

  void init() {
    if (kIsWeb) {
      WebHotKeyManager().init();
    }
  }

  void initDefaultHotKeys() {
    registerAction(
      'restart_app',
      'Restart Application',
      () {
        // 重启应用逻辑
      },
      defaultHotKey: WebHotKey(
        key: kIsWeb ? WebPhysicalKey.keyR : WebPhysicalKey.keyR,
        modifiers: [WebHotKeyModifier.control, WebHotKeyModifier.shift],
        scope: WebHotKeyScope.inapp,
      ),
    );

    registerAction(
      'bring_to_front',
      'Bring to Front',
      () {
        // 窗口置前逻辑
      },
      defaultHotKey: WebHotKey(
        key: kIsWeb ? WebPhysicalKey.keyF : WebPhysicalKey.keyF,
        modifiers: [WebHotKeyModifier.control],
        scope: WebHotKeyScope.inapp,
      ),
    );

    registerAction(
      'refresh_app',
      'Refresh Application',
      () {
        // 刷新应用逻辑
      },
      defaultHotKey: WebHotKey(
        key: kIsWeb ? WebPhysicalKey.keyR : WebPhysicalKey.keyR,
        modifiers: [WebHotKeyModifier.control],
        scope: WebHotKeyScope.inapp,
      ),
    );

    registerAction(
      'open_web_page',
      'Open Web Page',
      () {
        // 打开网页逻辑
        _openWebPage('https://example.com');
      },
      defaultHotKey: WebHotKey(
        key: kIsWeb ? WebPhysicalKey.keyW : WebPhysicalKey.keyW,
        modifiers: [WebHotKeyModifier.control, WebHotKeyModifier.alt],
        scope: WebHotKeyScope.inapp,
      ),
    );
  }

  void _openWebPage(String url) async {
    try {
      if (kIsWeb) {
        html.window.open(url, '_blank');
      }
    } catch (e) {
      debugPrint('Failed to open web page: $e');
    }
  }

  void registerAction(
    String id,
    String name,
    VoidCallback action, {
    WebHotKey? defaultHotKey,
  }) {
    _actions[id] = action;
    if (defaultHotKey != null) {
      _hotKeys[id] = HotKeyConfig(id: id, name: name, hotKey: defaultHotKey);
    }
  }

  Future<void> registerHotKey(String id, WebHotKey hotKey) async {
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
  final WebHotKey hotKey;

  HotKeyConfig({required this.id, required this.name, required this.hotKey});
}
