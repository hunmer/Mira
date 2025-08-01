// Stub implementation for shelf package for web compatibility
import 'dart:io';

/// Stub implementation of shelf_io for web
class ShelfIO {
  /// Serve a handler (stub implementation for web)
  static Future<HttpServer> serve(
    dynamic handler,
    InternetAddress address,
    int port, {
    int? backlog,
    bool v6Only = false,
    bool requestClientCertificate = false,
    bool shared = false,
    SecurityContext? securityContext,
  }) async {
    // Stub implementation for web - creates a minimal HttpServer-like object
    throw UnsupportedError('HTTP server is not supported on web platform');
  }
}

// Export the serve function as it would be in the real package
Future<HttpServer> serve(
  dynamic handler,
  InternetAddress address,
  int port, {
  int? backlog,
  bool v6Only = false,
  bool requestClientCertificate = false,
  bool shared = false,
  SecurityContext? securityContext,
}) {
  return ShelfIO.serve(
    handler,
    address,
    port,
    backlog: backlog,
    v6Only: v6Only,
    requestClientCertificate: requestClientCertificate,
    shared: shared,
    securityContext: securityContext,
  );
}
