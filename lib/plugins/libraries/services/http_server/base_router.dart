import 'dart:convert';
import 'package:mira/plugins/libraries/services/interface/library_server_data_interface.dart';
import 'package:mira/plugins/libraries/services/library_service.dart';
// ignore: depend_on_referenced_packages
import 'package:shelf/shelf.dart' show Response;

/// Base class for HTTP routers with common functionality
abstract class BaseRouter {
  final List<LibraryServerDataInterface> libraryServices;

  BaseRouter(this.libraryServices);

  /// Check if a library exists
  bool libraryExists(String libraryId) {
    return libraryServices.any(
      (library) => library.getLibraryId() == libraryId,
    );
  }

  /// Get library service by ID
  LibraryService getLibraryService(String libraryId) {
    final dbService = libraryServices.firstWhere(
      (library) => library.getLibraryId() == libraryId,
    );
    return LibraryService(dbService);
  }

  /// Create a standard error response for library not found
  Response libraryNotFoundResponse() {
    return Response.notFound('Library not found');
  }

  /// Create a standard error response for internal server errors
  Response internalServerErrorResponse(dynamic error) {
    return Response.internalServerError(body: error.toString());
  }

  /// Create a successful JSON response
  Response okJsonResponse(dynamic data) {
    return Response.ok(jsonEncode(data));
  }

  /// Parse integer from string with default value
  int parseIntWithDefault(String? value, int defaultValue) {
    return int.tryParse(value ?? '') ?? defaultValue;
  }

  /// Validate library exists and return error response if not
  Response? validateLibraryExists(String libraryId) {
    if (!libraryExists(libraryId)) {
      return libraryNotFoundResponse();
    }
    return null;
  }
}
