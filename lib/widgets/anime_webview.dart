import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AnimeWebView extends StatelessWidget {
  final String initialUrl;
  final void Function(InAppWebViewController) onWebViewCreated;
  final Future<void> Function(String?) onLoadStop;
  final void Function(String?)? onTitleChanged;
  final void Function(InAppWebViewController, WebUri?, bool?)?
      onUpdateVisitedHistory;

  const AnimeWebView({
    super.key,
    required this.initialUrl,
    required this.onWebViewCreated,
    required this.onLoadStop,
    this.onTitleChanged,
    this.onUpdateVisitedHistory,
  });

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
      onWebViewCreated: (controller) {
        onWebViewCreated(controller);
      },
      onLoadStop: (controller, uri) async {
        await onLoadStop(uri?.toString());
      },
      onTitleChanged: onTitleChanged != null
          ? (controller, title) async => onTitleChanged!(title)
          : null,
      onUpdateVisitedHistory: onUpdateVisitedHistory,
    );
  }
}
