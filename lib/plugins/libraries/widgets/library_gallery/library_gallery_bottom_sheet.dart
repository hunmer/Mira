import 'package:flutter/material.dart';

class LibraryGalleryBottomSheet extends StatelessWidget {
  final double uploadProgress;

  const LibraryGalleryBottomSheet({required this.uploadProgress, super.key});

  @override
  Widget build(BuildContext context) {
    return uploadProgress > 0
        ? LinearProgressIndicator(
          value: uploadProgress,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        )
        : const SizedBox.shrink();
  }
}
