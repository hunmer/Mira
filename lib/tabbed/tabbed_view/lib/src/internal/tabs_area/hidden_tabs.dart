import 'dart:collection';

import 'package:flutter/material.dart';

/// Holds the hidden tab indexes.
class HiddenTabs extends ChangeNotifier {
  List<int> _indexes = [];

  bool _hasHiddenTabs = false;
  bool get hasHiddenTabs => _hasHiddenTabs;

  List<int> get indexes {
    _indexes.sort();
    return UnmodifiableListView(_indexes);
  }

  void update(List<int> hiddenIndexes) {
    _indexes = hiddenIndexes;
    bool hasHiddenTabs = _indexes.isNotEmpty;
    if (_hasHiddenTabs != hasHiddenTabs) {
      _hasHiddenTabs = hasHiddenTabs;
      Future.microtask(() => notifyListeners());
    }
  }
}
