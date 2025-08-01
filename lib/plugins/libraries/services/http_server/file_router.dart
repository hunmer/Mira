import 'dart:convert';
import 'package:mira/plugins/libraries/services/http_server/base_router.dart';
// ignore: depend_on_referenced_packages
import 'package:shelf/shelf.dart' show Request, Response;
// ignore: depend_on_referenced_packages
import 'package:shelf_router/shelf_router.dart' as shelf_router;

class FileRouter extends BaseRouter {
  FileRouter(super.libraryServices);

  void setupRoutes(shelf_router.Router router) {
    router.get('/library/<libraryId>/files', handleGetFiles);
    router.get('/library/<libraryId>/files/<fileId>', handleGetFile);
    router.post('/library/<libraryId>/files', handleCreateFile);
    router.put('/library/<libraryId>/files/<fileId>', handleUpdateFile);
    router.delete('/library/<libraryId>/files/<fileId>', handleDeleteFile);
  }

  Future<Response> handleGetFiles(Request request, String libraryId) async {
    try {
      final validationError = validateLibraryExists(libraryId);
      if (validationError != null) return validationError;

      final service = getLibraryService(libraryId);
      final select = request.url.queryParameters['select'] ?? '*';
      final filters =
          request.url.queryParameters['filters'] != null
              ? jsonDecode(request.url.queryParameters['filters']!)
                  as Map<String, dynamic>
              : null;

      final files = await service.getFiles(select: select, filters: filters);
      return okJsonResponse(files);
    } catch (e) {
      return internalServerErrorResponse(e);
    }
  }

  Future<Response> handleGetFile(
    Request request,
    String libraryId,
    String fileId,
  ) async {
    try {
      final validationError = validateLibraryExists(libraryId);
      if (validationError != null) return validationError;

      final service = getLibraryService(libraryId);
      final id = int.parse(fileId);
      final file = await service.getFile(id);

      if (file == null) {
        return Response.notFound('File not found');
      }

      return okJsonResponse(file);
    } catch (e) {
      return internalServerErrorResponse(e);
    }
  }

  Future<Response> handleCreateFile(Request request, String libraryId) async {
    try {
      final validationError = validateLibraryExists(libraryId);
      if (validationError != null) return validationError;

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final service = getLibraryService(libraryId);

      final id = await service.createFile(data);
      return okJsonResponse({'id': id});
    } catch (e) {
      return internalServerErrorResponse(e);
    }
  }

  Future<Response> handleUpdateFile(
    Request request,
    String libraryId,
    String fileId,
  ) async {
    try {
      final validationError = validateLibraryExists(libraryId);
      if (validationError != null) return validationError;

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final service = getLibraryService(libraryId);
      final id = int.parse(fileId);

      final success = await service.dbService.updateFile(id, data);
      return okJsonResponse({'success': success});
    } catch (e) {
      return internalServerErrorResponse(e);
    }
  }

  Future<Response> handleDeleteFile(
    Request request,
    String libraryId,
    String fileId,
  ) async {
    try {
      final validationError = validateLibraryExists(libraryId);
      if (validationError != null) return validationError;

      final service = getLibraryService(libraryId);
      final id = int.parse(fileId);
      final moveToRecycleBin =
          request.url.queryParameters['moveToRecycleBin'] == 'true';

      final success = await service.dbService.deleteFile(
        id,
        moveToRecycleBin: moveToRecycleBin,
      );
      return okJsonResponse({'success': success});
    } catch (e) {
      return internalServerErrorResponse(e);
    }
  }
}
