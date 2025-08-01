import 'dart:convert';
import 'package:mira/plugins/libraries/services/http_server/base_router.dart';
// ignore: depend_on_referenced_packages
import 'package:shelf/shelf.dart' show Request, Response;
// ignore: depend_on_referenced_packages
import 'package:shelf_router/shelf_router.dart' as shelf_router;

class LibraryRouter extends BaseRouter {
  LibraryRouter(super.libraryServices);

  void setupRoutes(shelf_router.Router router) {
    router.post('/library/connect', handleLibraryConnect);
    router.get('/library/<libraryId>/folders', handleGetFolders);
    router.get('/library/<libraryId>/tags', handleGetTags);
  }

  Future<Response> handleLibraryConnect(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final libraryId = data['libraryId'] as String;
      final libraryConfig = data['library'] as Map<String, dynamic>;

      if (libraryExists(libraryId)) {
        return Response(400, body: 'Library already connected');
      }

      // Note: This requires access to loadLibrary method from HttpLibraryServer
      // This will need to be refactored to work with the new structure
      throw UnimplementedError('Library loading needs to be refactored');
    } catch (e) {
      return internalServerErrorResponse(e);
    }
  }

  Future<Response> handleGetFolders(Request request, String libraryId) async {
    try {
      final validationError = validateLibraryExists(libraryId);
      if (validationError != null) return validationError;

      final service = getLibraryService(libraryId);
      final limit = parseIntWithDefault(
        request.url.queryParameters['limit'],
        100,
      );
      final offset = parseIntWithDefault(
        request.url.queryParameters['offset'],
        0,
      );

      final folders = await service.getFolders(limit: limit, offset: offset);
      return okJsonResponse(folders);
    } catch (e) {
      return internalServerErrorResponse(e);
    }
  }

  Future<Response> handleGetTags(Request request, String libraryId) async {
    try {
      final validationError = validateLibraryExists(libraryId);
      if (validationError != null) return validationError;

      final service = getLibraryService(libraryId);
      final limit = parseIntWithDefault(
        request.url.queryParameters['limit'],
        100,
      );
      final offset = parseIntWithDefault(
        request.url.queryParameters['offset'],
        0,
      );

      final tags = await service.getTags(limit: limit, offset: offset);
      return okJsonResponse(tags);
    } catch (e) {
      return internalServerErrorResponse(e);
    }
  }
}
