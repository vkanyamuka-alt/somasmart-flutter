// How a learning file opens for a student, the same rules as the website
// (src/lib/documents.js). PDFs open in the in-app viewer; Word and other
// office files cannot be shown inside the app.

enum MaterialOpenKind { video, audio, pdf, file, link, none }

final _pdfExt = RegExp(r'\.pdf$', caseSensitive: false);
final _audioExt = RegExp(r'\.(mp3|m4a|aac|wav|ogg|oga|opus|weba)$', caseSensitive: false);
final _videoExt = RegExp(r'\.(mp4|webm|mov|m4v)$', caseSensitive: false);
final _officeExt = RegExp(r'\.(docx?|pptx?|xlsx?|odt|odp|ods|rtf|txt)$', caseSensitive: false);
final _anyExt = RegExp(r'\.[a-z0-9]{2,5}$', caseSensitive: false);

/// The path part of a link, without query or fragment ('' when empty).
String _pathOf(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return url.split(RegExp(r'[?#]')).first;
  try {
    return Uri.decodeComponent(uri.path);
  } catch (_) {
    return uri.path;
  }
}

bool isPdfUrl(String? url) => _pdfExt.hasMatch(_pathOf(url));

bool isOfficeUrl(String? url) => _officeExt.hasMatch(_pathOf(url));

/// The file name at the end of a link, without the upload time prefix.
String fileNameFromUrl(String? url) {
  final last = _pathOf(url).split('/').last;
  return last.replaceFirst(RegExp(r'^\d{10,}_'), '');
}

/// How a learning material opens (see [MaterialOpenKind]).
MaterialOpenKind materialOpenKind({
  required String materialType,
  String? url,
  String? wistiaVideoId,
}) {
  final type = materialType.toLowerCase();
  final link = url?.trim() ?? '';
  final path = _pathOf(link);
  final hasWistia = (wistiaVideoId ?? '').trim().isNotEmpty;
  // A PDF saved by mistake as a video still opens as a document.
  if (type == 'video' && !hasWistia && _pdfExt.hasMatch(path)) return MaterialOpenKind.pdf;
  if (type == 'video') return hasWistia || link.isNotEmpty ? MaterialOpenKind.video : MaterialOpenKind.none;
  if (link.isEmpty) return MaterialOpenKind.none;
  if (type == 'audio' || _audioExt.hasMatch(path)) return MaterialOpenKind.audio;
  if (type == 'pdf' || _pdfExt.hasMatch(path)) return MaterialOpenKind.pdf;
  if (_videoExt.hasMatch(path)) return MaterialOpenKind.video;
  if (type == 'document' || _officeExt.hasMatch(path)) return MaterialOpenKind.file;
  return _anyExt.hasMatch(path) ? MaterialOpenKind.file : MaterialOpenKind.link;
}
