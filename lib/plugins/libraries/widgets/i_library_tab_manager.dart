import 'library_tab_manager.dart';
import '../models/library.dart';

/// Tab管理器接口
abstract class ILibraryTabManager {
  dynamic getStoredValue(String tabId, String key, dynamic defaultValue);
  void updateFilter(String tabId, Map<String, dynamic> filter);
  LibraryTabData? getTabData(String tabId);
  void setStoreValue(String tabId, String key, dynamic value);
  void setValue(String tabId, String key, dynamic value);
  void tryUpdate(String tabId);
  void setSortOptions(String tabId, Map<String, dynamic> sortOptions);
  String? getCurrentTabId();
  void addTab(Library library, {String title = '', bool isRecycleBin = false});
}
