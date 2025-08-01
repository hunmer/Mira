// import 'dart:io';
// import 'dart:convert';
// import 'package:mira/plugins/libraries/services/interface/library_server_data_interface.dart';
// import 'package:mira/plugins/libraries/services/interface/library_server_data_sqlite5.dart';
// import 'package:mira/plugins/libraries/services/library_service.dart';
// import 'package:mira/plugins/libraries/services/websocket_server.dart';
// // ignore: depend_on_referenced_packages
// import 'package:shelf_router/shelf_router.dart' as shelf_router;
// // ignore: depend_on_referenced_packages
// import 'package:shelf/shelf.dart' show Request, Response;
// // ignore: depend_on_referenced_packages
// import 'package:shelf/shelf_io.dart' as shelf_io;

// class HttpLibraryServer {
//   final int port;
//   final List<LibraryServerDataInterface> _libraryServices = [];
//   late HttpServer _server;

//   HttpLibraryServer(this.port);

//   Future<LibraryServerDataInterface> loadLibrary(
//     Map<String, dynamic> dbConfig,
//   ) async {
//     final dbServer = LibraryServerDataSQLite5(
//       this as WebSocketServer,
//       dbConfig,
//     );
//     await dbServer.initialize();
//     _libraryServices.add(dbServer);
//     return dbServer;
//   }

//   LibraryService _getLibraryService(String libraryId) {
//     final dbService = _libraryServices.firstWhere(
//       (library) => library.getLibraryId() == libraryId,
//     );
//     return LibraryService(dbService);
//   }

//   bool libraryExists(String libraryId) {
//     return _libraryServices.any(
//       (library) => library.getLibraryId() == libraryId,
//     );
//   }

//   Future<void> start() async {
//     final router = shelf_router.Router();

//     // Library endpoints
//     router.post('/library/connect', _handleLibraryConnect);
//     router.get('/library/<libraryId>/folders', _handleGetFolders);
//     router.get('/library/<libraryId>/tags', _handleGetTags);

//     // File endpoints
//     router.get('/library/<libraryId>/files', _handleGetFiles);
//     router.get('/library/<libraryId>/files/<fileId>', _handleGetFile);
//     router.post('/library/<libraryId>/files', _handleCreateFile);
//     router.put('/library/<libraryId>/files/<fileId>', _handleUpdateFile);
//     router.delete('/library/<libraryId>/files/<fileId>', _handleDeleteFile);

//     // Folder endpoints
//     router.post('/library/<libraryId>/folders', _handleCreateFolder);
//     router.put('/library/<libraryId>/folders/<folderId>', _handleUpdateFolder);
//     router.delete(
//       '/library/<libraryId>/folders/<folderId>',
//       _handleDeleteFolder,
//     );

//     // Tag endpoints
//     router.post('/library/<libraryId>/tags', _handleCreateTag);
//     router.put('/library/<libraryId>/tags/<tagId>', _handleUpdateTag);
//     router.delete('/library/<libraryId>/tags/<tagId>', _handleDeleteTag);

//     _server = await shelf_io.serve(router.call, InternetAddress.anyIPv6, port);

//     print('Serving at http://${_server.address.host}:${_server.port}');
//   }

//   Future<Response> _handleLibraryConnect(Request request) async {
//     try {
//       final body = await request.readAsString();
//       final data = jsonDecode(body) as Map<String, dynamic>;
//       final libraryId = data['libraryId'] as String;
//       final libraryConfig = data['library'] as Map<String, dynamic>;

//       if (libraryExists(libraryId)) {
//         return Response(400, body: 'Library already connected');
//       }

//       final dbService = await loadLibrary(libraryConfig);
//       final service = LibraryService(dbService);
//       final result = await service.connectLibrary(libraryConfig);

//       return Response.ok(jsonEncode(result));
//     } catch (e) {
//       return Response.internalServerError(body: e.toString());
//     }
//   }

//   Future<Response> _handleGetFolders(Request request, String libraryId) async {
//     try {
//       if (!libraryExists(libraryId)) {
//         return Response.notFound('Library not found');
//       }

//       final service = _getLibraryService(libraryId);
//       final limit =
//           int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
//       final offset =
//           int.tryParse(request.url.queryParameters['offset'] ?? '0') ?? 0;

//       final folders = await service.getFolders(limit: limit, offset: offset);
//       return Response.ok(jsonEncode(folders));
//     } catch (e) {
//       return Response.internalServerError(body: e.toString());
//     }
//   }

//   Future<Response> _handleGetTags(Request request, String libraryId) async {
//     try {
//       if (!libraryExists(libraryId)) {
//         return Response.notFound('Library not found');
//       }

//       final service = _getLibraryService(libraryId);
//       final limit =
//           int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
//       final offset =
//           int.tryParse(request.url.queryParameters['offset'] ?? '0') ?? 0;

//       final tags = await service.getTags(limit: limit, offset: offset);
//       return Response.ok(jsonEncode(tags));
//     } catch (e) {
//       return Response.internalServerError(body: e.toString());
//     }
//   }

//   Future<Response> _handleGetFiles(Request request, String libraryId) async {
//     try {
//       if (!libraryExists(libraryId)) {
//         return Response.notFound('Library not found');
//       }

//       final service = _getLibraryService(libraryId);
//       final select = request.url.queryParameters['select'] ?? '*';
//       final filters =
//           request.url.queryParameters['filters'] != null
//               ? jsonDecode(request.url.queryParameters['filters']!)
//                   as Map<String, dynamic>
//               : null;

//       final files = await service.getFiles(select: select, filters: filters);
//       return Response.ok(jsonEncode(files));
//     } catch (e) {
//       return Response.internalServerError(body: e.toString());
//     }
//   }

//   Future<Response> _handleGetFile(
//     Request request,
//     String libraryId,
//     String fileId,
//   ) async {
//     try {
//       if (!libraryExists(libraryId)) {
//         return Response.notFound('Library not found');
//       }

//       final service = _getLibraryService(libraryId);
//       final id = int.parse(fileId);
//       final file = await service.getFile(id);

//       if (file == null) {
//         return Response.notFound('File not found');
//       }

//       return Response.ok(jsonEncode(file));
//     } catch (e) {
//       return Response.internalServerError(body: e.toString());
//     }
//   }

//   Future<Response> _handleCreateFile(Request request, String libraryId) async {
//     try {
//       if (!libraryExists(libraryId)) {
//         return Response.notFound('Library not found');
//       }

//       final body = await request.readAsString();
//       final data = jsonDecode(body) as Map<String, dynamic>;
//       final service = _getLibraryService(libraryId);

//       final id = await service.createFile(data);
//       return Response.ok(jsonEncode({'id': id}));
//     } catch (e) {
//       return Response.internalServerError(body: e.toString());
//     }
//   }

//   Future<Response> _handleUpdateFile(
//     Request request,
//     String libraryId,
//     String fileId,
//   ) async {
//     try {
//       if (!libraryExists(libraryId)) {
//         return Response.notFound('Library not found');
//       }

//       final body = await request.readAsString();
//       final data = jsonDecode(body) as Map<String, dynamic>;
//       final service = _getLibraryService(libraryId);
//       final id = int.parse(fileId);

//       final success = await service.dbService.updateFile(id, data);
//       return Response.ok(jsonEncode({'success': success}));
//     } catch (e) {
//       return Response.internalServerError(body: e.toString());
//     }
//   }

//   Future<Response> _handleDeleteFile(
//     Request request,
//     String libraryId,
//     String fileId,
//   ) async {
//     try {
//       if (!libraryExists(libraryId)) {
//         return Response.notFound('Library not found');
//       }

//       final service = _getLibraryService(libraryId);
//       final id = int.parse(fileId);
//       final moveToRecycleBin =
//           request.url.queryParameters['moveToRecycleBin'] == 'true';

//       final success = await service.dbService.deleteFile(
//         id,
//         moveToRecycleBin: moveToRecycleBin,
//       );
//       return Response.ok(jsonEncode({'success': success}));
//     } catch (e) {
//       return Response.internalServerError(body: e.toString());
//     }
//   }

//   Future<Response> _handleCreateFolder(
//     Request request,
//     String libraryId,
//   ) async {
//     try {
//       if (!libraryExists(libraryId)) {
//         return Response.notFound('Library not found');
//       }

//       final body = await request.readAsString();
//       final data = jsonDecode(body) as Map<String, dynamic>;
//       final service = _getLibraryService(libraryId);

//       final id = await service.createFolder(data);
//       return Response.ok(jsonEncode({'id': id}));
//     } catch (e) {
//       return Response.internalServerError(body: e.toString());
//     }
//   }

//   Future<Response> _handleUpdateFolder(
//     Request request,
//     String libraryId,
//     String folderId,
//   ) async {
//     try {
//       if (!libraryExists(libraryId)) {
//         return Response.notFound('Library not found');
//       }

//       final body = await request.readAsString();
//       final data = jsonDecode(body) as Map<String, dynamic>;
//       final service = _getLibraryService(libraryId);
//       final id = int.parse(folderId);

//       final success = await service.dbService.updateFolder(id, data);
//       return Response.ok(jsonEncode({'success': success}));
//     } catch (e) {
//       return Response.internalServerError(body: e.toString());
//     }
//   }

//   Future<Response> _handleDeleteFolder(
//     Request request,
//     String libraryId,
//     String folderId,
//   ) async {
//     try {
//       if (!libraryExists(libraryId)) {
//         return Response.notFound('Library not found');
//       }

//       final service = _getLibraryService(libraryId);
//       final id = int.parse(folderId);

//       final success = await service.dbService.deleteFolder(id);
//       return Response.ok(jsonEncode({'success': success}));
//     } catch (e) {
//       return Response.internalServerError(body: e.toString());
//     }
//   }

//   Future<Response> _handleCreateTag(Request request, String libraryId) async {
//     try {
//       if (!libraryExists(libraryId)) {
//         return Response.notFound('Library not found');
//       }

//       final body = await request.readAsString();
//       final data = jsonDecode(body) as Map<String, dynamic>;
//       final service = _getLibraryService(libraryId);

//       final id = await service.createTag(data);
//       return Response.ok(jsonEncode({'id': id}));
//     } catch (e) {
//       return Response.internalServerError(body: e.toString());
//     }
//   }

//   Future<Response> _handleUpdateTag(
//     Request request,
//     String libraryId,
//     String tagId,
//   ) async {
//     try {
//       if (!libraryExists(libraryId)) {
//         return Response.notFound('Library not found');
//       }

//       final body = await request.readAsString();
//       final data = jsonDecode(body) as Map<String, dynamic>;
//       final service = _getLibraryService(libraryId);
//       final id = int.parse(tagId);

//       final success = await service.dbService.updateTag(id, data);
//       return Response.ok(jsonEncode({'success': success}));
//     } catch (e) {
//       return Response.internalServerError(body: e.toString());
//     }
//   }

//   Future<Response> _handleDeleteTag(
//     Request request,
//     String libraryId,
//     String tagId,
//   ) async {
//     try {
//       if (!libraryExists(libraryId)) {
//         return Response.notFound('Library not found');
//       }

//       final service = _getLibraryService(libraryId);
//       final id = int.parse(tagId);

//       final success = await service.dbService.deleteTag(id);
//       return Response.ok(jsonEncode({'success': success}));
//     } catch (e) {
//       return Response.internalServerError(body: e.toString());
//     }
//   }

//   Future<void> stop() async {
//     for (var dbService in _libraryServices) {
//       dbService.close();
//     }
//     await _server.close();
//     print('HTTP server stopped');
//   }
// }
