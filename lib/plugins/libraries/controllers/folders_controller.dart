import 'package:mira/core/event/event.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:stash/stash_api.dart';
import 'package:stash_memory/stash_memory.dart';

class FoldersController {
  late final MemoryCacheStore store;
  final List<FolderCache> caches = [];
  Future<void> init() async {
    store = await newMemoryCacheStore();
    print('Store created');
    EventManager.instance.subscribe(
      'folders_update',
      (EventArgs args) => _onFoldersUpdate(args as MapEventArgs),
    );
  }

  void _onFoldersUpdate(MapEventArgs args) {
    print('Folders updated');
    final data = args.item;
    final cache = getLibraryCache(data['library']);
    data['folders'].forEach((e) => cache.put(LibraryFolder.fromMap(e)));
  }

  Future<FolderCache> createCache(String libraryName) async {
    print('Initializing folder cache for library: $libraryName');
    final cache = FolderCache(store, libraryName);
    await cache.init();
    caches.add(cache);
    return cache;
  }

  FolderCache getLibraryCache(String libraryName) {
    return caches.firstWhere((cache) => cache.name == libraryName);
  }
}

class FolderCache {
  FolderCache(this.store, this.name);
  final MemoryCacheStore store;
  final String name;
  late final Cache<LibraryFolder> cache;

  Future<void> init() async {
    cache =
        await store.cache<LibraryFolder>(
            name: name,
            fromEncodable: (json) => LibraryFolder.fromMap(json),
            eventListenerMode: EventListenerMode.synchronous,
          )
          ..on<CacheEntryCreatedEvent<LibraryFolder>>().listen(
            (event) => print('Key "${event.entry.key}" added'),
          )
          ..on<CacheEntryUpdatedEvent<LibraryFolder>>().listen(
            (event) => print('Key "${event.newEntry.key}" updated'),
          )
          ..on<CacheEntryRemovedEvent<LibraryFolder>>().listen(
            (event) => print('Key "${event.entry.key}" removed'),
          )
          ..on<CacheEntryExpiredEvent<LibraryFolder>>().listen(
            (event) => print('Key "${event.entry.key}" expired'),
          )
          ..on<CacheEntryEvictedEvent<LibraryFolder>>().listen(
            (event) => print('Key "${event.entry.key}" evicted'),
          );
  }

  Future<void> put(LibraryFolder folder) async {
    return await cache.put(folder.id, folder);
  }

  Future<LibraryFolder?> get(String name) async {
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
}
