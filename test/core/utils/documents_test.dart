import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/core/utils/documents.dart';

const r2 = 'https://somasmart-files.pjsmart.workers.dev/materials';

void main() {
  group('isPdfUrl', () {
    test('recognises PDFs by the path, ignoring query and case', () {
      expect(isPdfUrl('$r2/1732450000000_Cells.pdf'), isTrue);
      expect(isPdfUrl('$r2/1732450000000_Cells.PDF?v=2#page=3'), isTrue);
      expect(isPdfUrl('$r2/notes.docx'), isFalse);
      expect(isPdfUrl('https://example.com/pdf-guide'), isFalse);
      expect(isPdfUrl(''), isFalse);
      expect(isPdfUrl(null), isFalse);
    });
  });

  test('fileNameFromUrl drops the upload time prefix', () {
    expect(fileNameFromUrl('$r2/1732450000000_Cell_structure.pdf'), 'Cell_structure.pdf');
    expect(fileNameFromUrl('$r2/Cell%20structure.pdf?x=1'), 'Cell structure.pdf');
  });

  group('materialOpenKind (same rules as the website)', () {
    test('PDFs open in the app whatever type they were saved as', () {
      for (final type in ['pdf', 'document', 'other', 'video']) {
        expect(materialOpenKind(materialType: type, url: '$r2/a.pdf'), MaterialOpenKind.pdf, reason: type);
      }
    });

    test('audio, office files, web pages, videos and empty items', () {
      expect(materialOpenKind(materialType: 'audio', url: '$r2/a.mp3'), MaterialOpenKind.audio);
      expect(materialOpenKind(materialType: 'document', url: '$r2/a.docx'), MaterialOpenKind.file);
      expect(materialOpenKind(materialType: 'other', url: '$r2/archive.zip'), MaterialOpenKind.file);
      expect(materialOpenKind(materialType: 'other', url: 'https://www.necta.go.tz/results'), MaterialOpenKind.link);
      expect(materialOpenKind(materialType: 'video', wistiaVideoId: 'abc'), MaterialOpenKind.video);
      expect(materialOpenKind(materialType: 'video'), MaterialOpenKind.none);
      expect(materialOpenKind(materialType: 'pdf', url: ''), MaterialOpenKind.none);
    });
  });
}
