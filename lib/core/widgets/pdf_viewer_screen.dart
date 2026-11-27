import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

/// Shows a PDF inside the app (subject files, PDF notes, the syllabus), so
/// students never leave the app to read. The phone's own PDF engine draws the
/// pages (Android PdfRenderer, iOS PDFKit, pdf.js on the web). Pages scroll
/// top to bottom and pinch to zoom; big files show how much has arrived.
class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  final String? subtitle;
  final String lang;

  const PdfViewerScreen({
    super.key,
    required this.url,
    required this.title,
    this.subtitle,
    this.lang = 'en',
  });

  /// Opens the viewer as a full-screen page.
  static Future<void> open(
    BuildContext context, {
    required String url,
    required String title,
    String? subtitle,
    String lang = 'en',
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfViewerScreen(url: url, title: title, subtitle: subtitle, lang: lang),
      ),
    );
  }

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PdfControllerPinch? _controller;
  bool _failed = false;
  int _received = 0;
  int? _total;
  int _page = 1;
  int _pages = 0;
  http.Client? _client;

  bool get _sw => widget.lang == 'sw';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _client?.close();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _client?.close();
    final client = http.Client();
    _client = client;
    setState(() {
      _failed = false;
      _received = 0;
      _total = null;
      _pages = 0;
      _page = 1;
    });
    try {
      final response = await client.send(http.Request('GET', Uri.parse(widget.url)));
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
      final total = response.contentLength;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.stream) {
        builder.add(chunk);
        if (!mounted) return;
        setState(() {
          _received = builder.length;
          _total = total;
        });
      }
      if (!mounted) return;
      final bytes = builder.takeBytes();
      final old = _controller;
      setState(() {
        _controller = PdfControllerPinch(document: PdfDocument.openData(bytes));
      });
      old?.dispose();
    } catch (e) {
      debugPrint('PDF could not be opened: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = _controller;

    Widget body;
    if (_failed) {
      body = _Failed(
        title: _sw ? 'Hati haikuweza kufunguka' : 'The document could not be opened',
        body: _sw ? 'Angalia intaneti yako kisha ujaribu tena.' : 'Check your internet connection and try again.',
        retry: _sw ? 'Jaribu tena' : 'Try again',
        onRetry: _load,
      );
    } else if (controller == null) {
      body = _Loading(
        label: _sw ? 'Inafungua hati...' : 'Opening the document...',
        downloaded: _received,
        total: _total,
      );
    } else {
      body = PdfViewPinch(
        controller: controller,
        padding: 8,
        backgroundDecoration: BoxDecoration(color: isDark ? const Color(0xFF0B1120) : const Color(0xFFE9EDF2)),
        onDocumentLoaded: (document) {
          if (mounted) setState(() => _pages = document.pagesCount);
        },
        onPageChanged: (page) {
          if (mounted) setState(() => _page = page);
        },
        onDocumentError: (error) {
          debugPrint('PDF could not be drawn: $error');
          if (mounted) setState(() => _failed = true);
        },
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) => _Loading(label: _sw ? 'Inafungua hati...' : 'Opening the document...', downloaded: 0),
          pageLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: _sw ? 'Funga' : 'Close',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            if ((widget.subtitle ?? '').isNotEmpty)
              Text(widget.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          if (_pages > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_sw ? 'Ukurasa' : 'Page'} $_page / $_pages',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]),
                ),
              ),
            ),
        ],
      ),
      body: body,
    );
  }
}

class _Loading extends StatelessWidget {
  final String label;
  final int downloaded;
  final int? total;

  const _Loading({required this.label, required this.downloaded, this.total});

  @override
  Widget build(BuildContext context) {
    final t = total ?? 0;
    final showSize = t > 2000000;
    String mb(int bytes) => (bytes / 1048576).toStringAsFixed(1);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(value: showSize ? (downloaded / t).clamp(0.0, 1.0) : null),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
          if (showSize) ...[
            const SizedBox(height: 4),
            Text('${mb(downloaded)} / ${mb(t)} MB', style: const TextStyle(fontSize: 12, fontFeatures: [FontFeature.tabularFigures()])),
          ],
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  final String title;
  final String body;
  final String retry;
  final VoidCallback onRetry;

  const _Failed({required this.title, required this.body, required this.retry, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(retry)),
          ],
        ),
      ),
    );
  }
}
