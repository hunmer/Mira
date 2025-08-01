// ignore_for_file: non_constant_identifier_names

import 'package:mira/core/event/event.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:stash/stash_api.dart';
import 'package:stash_memory/stash_memory.dart';

class FoldersTagsCache {
  final List<FolderCache> folder_caches = [];
  final List<TagCache> tag_caches = [];
  Future<void> init() async {
    EventManager.instance.subscribe(
      'folders::update',
      (EventArgs args) => _onFoldersUpdate(args as MapEventArgs),
    );
    EventManager.instance.subscribe(
      'tags::update',
      (EventArgs args) => _onTagsUpdate(args as MapEventArgs),
    );
  }

  void _onFoldersUpdate(MapEventArgs args) {
    final data = args.item;
    final cache = getFolderCache(data['libraryId']);
    data['folders'].forEach((e) => {cache.put(LibraryFolder.fromMap(e))});
  }

  void _onTagsUpdate(MapEventArgs args) {
    final data = args.item;
    final cache = getTagCache(data['libraryId']);
    data['tags'].forEach((e) => cache.put(LibraryTag.fromMap(e)));
  }

  Future<FolderCache> createFolderCache(String libraryId) async {
    final cache = FolderCache(libraryId);
    await cache.init();
    folder_caches.add(cache);
    return cache;
  }

  Future<TagCache> createTagCache(String libraryId) async {
    final cache = TagCache(libraryId);
    await cache.init();
    tag_caches.add(cache);
    return cache;
  }

  FolderCache getFolderCache(String libraryId) {
    return folder_caches.firstWhere((cache) => cache.id == libraryId);
  }

  TagCache getTagCache(String libraryId) {
    return tag_caches.firstWhere((cache) => cache.id == libraryId);
  }

  Future<String> getFolderTitleById(String libraryId, String folderId) async {
    if (folderId.isEmpty) return '';
    final cache = getFolderCache(libraryId);
    final folder = await cache.get(folderId);
    return (folder != null) ? folder.title : folderId;
  }

  Future<String> getTagTitleById(String libraryId, String tagId) async {
    if (tagId.isEmpty) return '';
    final cache = getTagCache(libraryId);
    final tag = await cache.get(tagId);
    return (tag != null) ? tag.title : tagId;
  }
}

class FolderCache {
  FolderCache(this.id);
  late final MemoryCacheStore store;
  final String id;
  late final Cache<LibraryFolder> cache;

  Future<void> init() async {
    store = await newMemoryCacheStore();
    cache = await store.cache<LibraryFolder>(
      name: '${id}_folders',
      fromEncodable: (json) => LibraryFolder.fromMap(json),
      eventListenerMode: EventListenerMode.synchronous,
    );
    // ..on<CacheEntryCreatedEvent<LibraryFolder>>().listen(
    //   (event) => print('Folder "${event.entry.key}" added'),
    // )
    // ..on<CacheEntryUpdatedEvent<LibraryFolder>>().listen(
    //   (event) => print('Folder "${event.newEntry.key}" updated'),
    // )
    // ..on<CacheEntryRemovedEvent<LibraryFolder>>().listen(
    //   (event) => print('Folder "${event.entry.key}" removed'),
    // );
  }

  Future<void> put(LibraryFolder folder) async {
    return await cache.put(folder.id, folder);
  }

  Future<LibraryFolder?> get(String folderId) async {
    return await cache.get(folderId);
  }

  Future<void> remove(String folderId) async {
    return await cache.remove(folderId);
  }

  Future<void> clear() async {
    return await cache.clear();
  }

  Future<void> close() async {
    return await cache.close();
  }

  Future<List<LibraryFolder?>> getAll() async {
    return (await cache.getAll(
      (await cache.keys).toSet(),
    )).values.whereType<LibraryFolder>().toList();
  }
}

class TagCache {
  TagCache(this.id);
  late final MemoryCacheStore store;
  final String id;
  late final Cache<LibraryTag> cache;

  Future<void> init() async {
    store = await newMemoryCacheStore();
    cache = await store.cache<LibraryTag>(
      name: '${id}_tags',
      fromEncodable: (json) => LibraryTag.fromMap(json),
      eventListenerMode: EventListenerMode.synchronous,
    );
    // ..on<CacheEntryCreatedEvent<LibraryTag>>().listen(
    //   (event) => print('Tag "${event.entry.key}" added'),
    // )
    // ..on<CacheEntryUpdatedEvent<LibraryTag>>().listen(
    //   (event) => print('Tag "${event.newEntry.key}" updated'),
    // )
    // ..on<CacheEntryRemovedEvent<LibraryTag>>().listen(
    //   (event) => print('Tag "${event.entry.key}" removed'),
    // );
  }

  Future<void> put(LibraryTag tag) async {
    return await cache.put(tag.id, tag);
  }

  Future<LibraryTag?> get(String name) async {
    return await cache.get(name);
  }

  Future<void> remove(String name) async {
    return await cache.remove(name);
  }

  Future<void> clear() async {
    return await cache.clear();
  }

  Future<void> close() async {
    return await cache.close();
  }

  Future<List<LibraryTag?>> getAll() async {
    return (await cache.getAll(
      (await cache.keys).toSet(),
    )).values.whereType<LibraryTag>().toList();
  }
}
