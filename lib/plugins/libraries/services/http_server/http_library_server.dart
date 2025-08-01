import 'dart:io';
import 'dart:convert';
import 'package:mira/plugins/libraries/services/interface/library_server_data_interface.dart';
import 'package:mira/plugins/libraries/services/interface/library_server_data_sqlite5.dart';
import 'package:mira/plugins/libraries/services/library_service.dart';
import 'package:mira/plugins/libraries/services/websocket_server.dart';
import 'package:mira/plugins/libraries/services/http_server/library_router.dart';
import 'package:mira/plugins/libraries/services/http_server/file_router.dart';
import 'package:mira/plugins/libraries/services/http_server/folder_router.dart';
import 'package:mira/plugins/libraries/services/http_server/tag_router.dart';
// ignore: depend_on_referenced_packages
import 'package:shelf_router/shelf_router.dart' as shelf_router;
// ignore: depend_on_referenced_packages
import 'package:shelf/shelf.dart' show Request, Response;
// ignore: depend_on_referenced_packages
import 'package:shelf/shelf_io.dart' as shelf_io;

class HttpLibraryServer {
  final int port;
  final List<LibraryServerDataInterface> _libraryServices = [];
  late HttpServer _server;

  // Router instances
  late LibraryRouter _libraryRouter;
  late FileRouter _fileRouter;
  late FolderRouter _folderRouter;
  late TagRouter _tagRouter;

  HttpLibraryServer(this.port) {
    _initializeRouters();
  }

  void _initializeRouters() {
    _libraryRouter = LibraryRouter(_libraryServices);
    _fileRouter = FileRouter(_libraryServices);
    _folderRouter = FolderRouter(_libraryServices);
    _tagRouter = TagRouter(_libraryServices);
  }

  Future<LibraryServerDataInterface> loadLibrary(
    Map<String, dynamic> dbConfig,
  ) async {
    final dbServer = LibraryServerDataSQLite5(
      this as WebSocketServer,
      dbConfig,
    );
    await dbServer.initialize();
    _libraryServices.add(dbServer);
    return dbServer;
  }

  bool libraryExists(String libraryId) {
    return _libraryServices.any(
      (library) => library.getLibraryId() == libraryId,
    );
  }

  Future<void> start() async {
    final router = shelf_router.Router();

    // Setup routes from different routers
    _setupLibraryRoutes(router);
    _fileRouter.setupRoutes(router);
    _folderRouter.setupRoutes(router);
    _tagRouter.setupRoutes(router);

    _server = await shelf_io.serve(router.call, InternetAddress.anyIPv6, port);

    print('Serving at http://${_server.address.host}:${_server.port}');
  }

  void _setupLibraryRoutes(shelf_router.Router router) {
    // Custom library connect handler that needs access to loadLibrary
    router.post('/library/connect', _handleLibraryConnect);
    router.get('/library/<libraryId>/folders', _libraryRouter.handleGetFolders);
    router.get('/library/<libraryId>/tags', _libraryRouter.handleGetTags);
  }

  Future<Response> _handleLibraryConnect(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final libraryId = data['libraryId'] as String;
      final libraryConfig = data['library'] as Map<String, dynamic>;

      if (libraryExists(libraryId)) {
        return Response(400, body: 'Library already connected');
      }

      final dbService = await loadLibrary(libraryConfig);
      final service = LibraryService(dbService);
      final result = await service.connectLibrary(libraryConfig);

      return Response.ok(jsonEncode(result));
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<void> stop() async {
    for (var dbService in _libraryServices) {
      dbService.close();
    }
    await _server.close();
    print('HTTP server stopped');
  }
}
