// Stub implementation for xxh3 package for web compatibility
import 'dart:typed_data';

/// Stub implementation of xxh3 hash function for web
/// This is a placeholder that returns a simple hash for web compatibility
int xxh3(Uint8List data) {
  // Simple hash implementation for web - not cryptographically secure
  // This is just a placeholder since the actual xxh3 won't be called on web
  int hash = 0;
  for (int i = 0; i < data.length; i++) {
    hash = ((hash * 31) + data[i]) & 0xFFFFFFFF;
  }
  return hash;
}
