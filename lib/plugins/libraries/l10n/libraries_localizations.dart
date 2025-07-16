import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class LibrariesLocalizations {
  static const LocalizationsDelegate<LibrariesLocalizations> delegate =
      _LibrariesLocalizationsDelegate();

  static LibrariesLocalizations of(BuildContext context) {
    final localizations = Localizations.of<LibrariesLocalizations>(
      context,
      LibrariesLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No LibrariesLocalizations found in context');
    }
    return localizations;
  }

  // 资源库相关文本
  String get librariesTitle => 'Libraries';
  String get newLibrary => 'New Library';
  String get createLibrary => 'Create Library';
  String get editLibrary => 'Edit Library';
  String get libraryName => 'Library Name';
  String get nameRequired => 'Name is required';
  String get localDatabase => 'Local Database';
  String get networkDatabase => 'Network Database';
  String get databaseType => 'Database Type';
  String get selectFolder => 'Select Folder';
  String get serverAddress => 'Server Address';
  String get serverRequired => 'Server is required';
  String get username => 'Username';
  String get password => 'Password';

  // 文件相关文本
  String get filesTitle => 'Files';
  String get fileName => 'File Name';
  String get fileSize => 'Size';
  String get selectLibrary => 'Select Library';
  String get uploadComplete => 'Upload complete';
  String get uploadFailed => 'Upload failed';
}

class _LibrariesLocalizationsDelegate
    extends LocalizationsDelegate<LibrariesLocalizations> {
  const _LibrariesLocalizationsDelegate();

  @override
  Future<LibrariesLocalizations> load(Locale locale) {
    return SynchronousFuture<LibrariesLocalizations>(LibrariesLocalizations());
  }

  @override
  bool isSupported(Locale locale) => true;

  @override
  bool shouldReload(_LibrariesLocalizationsDelegate old) => false;
}
