import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/subjects/domain/models/syllabus_topic_model.dart';

SubjectMaterialItem item(Map<String, dynamic> extra) => SubjectMaterialItem.fromMap({
      'id': 'm1',
      'subject_id': 's1',
      'title': 'T',
      'form_level': 1,
      ...extra,
    });

void main() {
  test('a Wistia video opens the Wistia player, like the website', () {
    expect(item({'material_type': 'video', 'wistia_video_id': 'abc123'}).openUri.toString(),
        'https://fast.wistia.net/embed/iframe/abc123');
  });
  test('a document opens its https link', () {
    expect(item({'material_type': 'pdf', 'external_url': 'https://x.supabase.co/a.pdf'}).openUri.toString(),
        'https://x.supabase.co/a.pdf');
  });
  test('nothing to open: no file, a non-https link, or a strange Wistia id', () {
    expect(item({'material_type': 'pdf'}).openUri, isNull);
    expect(item({'material_type': 'pdf', 'external_url': 'http://x.com/a.pdf'}).openUri, isNull);
    expect(item({'material_type': 'video', 'wistia_video_id': 'a/../b'}).openUri, isNull);
  });
}
