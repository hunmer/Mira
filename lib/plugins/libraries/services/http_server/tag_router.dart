import 'dart:convert';
import 'package:mira/plugins/libraries/services/http_server/base_router.dart';
// ignore: depend_on_referenced_packages
import 'package:shelf/shelf.dart' show Request, Response;
// ignore: depend_on_referenced_packages
import 'package:shelf_router/shelf_router.dart' as shelf_router;

class TagRouter extends BaseRouter {
  TagRouter(super.libraryServices);

  void setupRoutes(shelf_router.Router router) {
    router.post('/library/<libraryId>/tags', handleCreateTag);
    router.put('/library/<libraryId>/tags/<tagId>', handleUpdateTag);
    router.delete('/library/<libraryId>/tags/<tagId>', handleDeleteTag);
  }

  Future<Response> handleCreateTag(Request request, String libraryId) async {
    try {
      final validationError = validateLibraryExists(libraryId);
      if (validationError != null) return validationError;

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final service = getLibraryService(libraryId);

      final id = await service.createTag(data);
      return okJsonResponse({'id': id});
    } catch (e) {
      return internalServerErrorResponse(e);
    }
  }

  Future<Response> handleUpdateTag(
    Request request,
    String libraryId,
    String tagId,
  ) async {
    try {
      final validationError = validateLibraryExists(libraryId);
      if (validationError != null) return validationError;

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final service = getLibraryService(libraryId);
      final id = int.parse(tagId);

      final success = await service.dbService.updateTag(id, data);
      return okJsonResponse({'success': success});
    } catch (e) {
      return internalServerErrorResponse(e);
    }
  }

  Future<Response> handleDeleteTag(
    Request request,
    String libraryId,
    String tagId,
  ) async {
    try {
      final validationError = validateLibraryExists(libraryId);
      if (validationError != null) return validationError;

      final service = getLibraryService(libraryId);
      final id = int.parse(tagId);

      final success = await service.dbService.deleteTag(id);
      return okJsonResponse({'success': success});
    } catch (e) {
      return internalServerErrorResponse(e);
    }
  }
}
