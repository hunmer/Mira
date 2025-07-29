import 'package:flutter/material.dart';
import 'package:mira/widgets/webview_browser/webview_browser.dart';

class WebViewDialog extends StatefulWidget {
  final String title;
  final String message;
  final String url;

  const WebViewDialog({
    super.key,
    required this.title,
    required this.message,
    required this.url,
  });

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
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                child: WebViewBrowser(initialUrls: [widget.url]),
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
