import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewDialog extends StatefulWidget {
  final String title;
  final String message;
  final String url;

  const WebViewDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.url,
  }) : super(key: key);

  @override
  State<WebViewDialog> createState() => _WebViewDialogState();
}

class _WebViewDialogState extends State<WebViewDialog> {
  bool _showWebView = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content:
          _showWebView
              ? SizedBox(
                height: 300,
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                ),
              )
              : Text(widget.message),
      actions: [
        TextButton(
          onPressed: () {
            if (widget.url.isNotEmpty) {
              setState(() {
                _showWebView = true;
              });
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
