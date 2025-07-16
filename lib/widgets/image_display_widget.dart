import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/image_utils.dart';

class ImageDisplayWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ImageDisplayWidget({
    super.key,
    required this.imageUrl,
    this.size = 64,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return placeholder ?? const Icon(Icons.auto_awesome, size: 48);
    }

    return FutureBuilder<String>(
      future: imageUrl!.startsWith('http')
          ? Future.value(imageUrl!)
          : ImageUtils.getAbsolutePath(imageUrl!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: ClipOval(
                child: imageUrl!.startsWith('http')
                    ? Image.network(
                        snapshot.data!,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            errorWidget ?? const Icon(Icons.broken_image),
                      )
                    : Image.file(
                        File(snapshot.data!),
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            errorWidget ?? const Icon(Icons.broken_image),
                      ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return errorWidget ?? const Icon(Icons.broken_image);
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}