// Stub implementation for dart:io on web platform
// This file provides dummy implementations of File, Directory, and related classes
// to prevent compilation errors on web platform

import 'dart:typed_data';

class File {
  final String path;
  File(this.path);

  Future<bool> exists() async => false;
  Future<void> delete() async {}
  Future<void> copy(String target) async {}
  Future<Uint8List> readAsBytes() async => Uint8List(0);
  Future<void> writeAsBytes(List<int> bytes) async {}
}

class Directory {
  final String path;
  Directory(this.path);

  Future<bool> exists() async => false;
  Future<void> create({bool recursive = false}) async {}
  Future<void> delete({bool recursive = false}) async {}
  Future<Directory> rename(String newPath) async => Directory(newPath);
  List<FileSystemEntity> listSync({bool recursive = false}) => [];
  Stream<FileSystemEntity> list({bool recursive = false}) => Stream.empty();
}

abstract class FileSystemEntity {
  String get path;
  Future<void> delete({bool recursive = false});

  static bool isDirectorySync(String path) => false;
  static FileSystemEntityType typeSync(String path) =>
      FileSystemEntityType.notFound;
}

enum FileSystemEntityType { file, directory, link, notFound }

class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isWindows => false;
  static bool get isMacOS => false;
  static bool get isLinux => false;
}
