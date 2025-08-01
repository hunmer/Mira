import 'dart:convert';
import 'package:mira/plugins/libraries/services/http_server/base_router.dart';
// ignore: depend_on_referenced_packages
import 'package:shelf/shelf.dart' show Request, Response;
// ignore: depend_on_referenced_packages
import 'package:shelf_router/shelf_router.dart' as shelf_router;

class FolderRouter extends BaseRouter {
  FolderRouter(super.libraryServices);

  void setupRoutes(shelf_router.Router router) {
    router.post('/library/<libraryId>/folders', handleCreateFolder);
    router.put('/library/<libraryId>/folders/<folderId>', handleUpdateFolder);
    router.delete(
      '/library/<libraryId>/folders/<folderId>',
      handleDeleteFolder,
    );
  }

  Future<Response> handleCreateFolder(Request request, String libraryId) async {
    try {
      final validationError = validateLibraryExists(libraryId);
      if (validationError != null) return validationError;

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final service = getLibraryService(libraryId);

      final id = await service.createFolder(data);
      return okJsonResponse({'id': id});
    } catch (e) {
      return internalServerErrorResponse(e);
    }
  }

  Future<Response> handleUpdateFolder(
    Request request,
    String libraryId,
    String folderId,
  ) async {
    try {
      final validationError = validateLibraryExists(libraryId);
      if (validationError != null) return validationError;

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final service = getLibraryService(libraryId);
      final id = int.parse(folderId);

      final success = await service.dbService.updateFolder(id, data);
      return okJsonResponse({'success': success});
    } catch (e) {
      return internalServerErrorResponse(e);
    }
  }

  Future<Response> handleDeleteFolder(
    Request request,
    String libraryId,
    String folderId,
  ) async {
    try {
      final validationError = validateLibraryExists(libraryId);
      if (validationError != null) return validationError;

      final service = getLibraryService(libraryId);
      final id = int.parse(folderId);

      final success = await service.dbService.deleteFolder(id);
      return okJsonResponse({'success': success});
    } catch (e) {
      return internalServerErrorResponse(e);
    }
  }
}
