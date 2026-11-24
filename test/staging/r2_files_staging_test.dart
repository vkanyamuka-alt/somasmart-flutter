// Runs the app's real syllabus provider against STAGING to prove the Flutter
// app opens files stored in Cloudflare R2: the cover picture (Image.network)
// and the PDF (opened by link) both come from the R2 public address.
//
// Skipped unless QA_SECRETS_DIR points at the folder with stg_keys.json,
// qa_users.json and r2_staging.env (kept outside the repo):
//   QA_SECRETS_DIR=<folder> flutter test test/staging/r2_files_staging_test.dart
//
// It adds one published test syllabus (pointing at files already in the
// staging R2 bucket) as the QA admin and deletes it at the end.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/core/services/supabase_service.dart';
import 'package:somasmart_flutter/features/syllabus/presentation/controllers/syllabus_library_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const stagingUrl = 'https://eflfzxhyzjkdwbddrsha.supabase.co';

Future<({int status, String type, List<int> bytes})> download(String url) async {
  final client = HttpClient();
  try {
    final res = await (await client.getUrl(Uri.parse(url))).close();
    final bytes = await res.fold<List<int>>(<int>[], (all, part) => all..addAll(part));
    return (status: res.statusCode, type: res.headers.contentType?.mimeType ?? '', bytes: bytes);
  } finally {
    client.close();
  }
}

void main() {
  final dir = Platform.environment['QA_SECRETS_DIR'];
  final skip = dir == null ? 'QA_SECRETS_DIR not set (staging-only check)' : null;

  test('the app lists a syllabus whose cover and PDF open from R2', () async {
    expect(stagingUrl.contains('jgdsinabjhytasybgtix'), false, reason: 'never production');
    final keys = jsonDecode(File('$dir/stg_keys.json').readAsStringSync()) as List;
    final anon = keys.firstWhere((k) => k['name'] == 'anon')['api_key'] as String;
    final users = jsonDecode(File('$dir/qa_users.json').readAsStringSync()) as Map<String, dynamic>;
    final env = {
      for (final m in RegExp(r'^([A-Z0-9_]+)=(.*)$', multiLine: true)
          .allMatches(File('$dir/r2_staging.env').readAsStringSync().replaceAll('\r', '')))
        m.group(1)!: m.group(2)!.trim(),
    };
    final r2Base = env['R2_PUBLIC_BASE_URL']!;
    expect(r2Base, startsWith('https://'));

    Future<SupabaseClient> signIn(Map<String, dynamic> u) async {
      final c = SupabaseClient(stagingUrl, anon,
          authOptions: const AuthClientOptions(autoRefreshToken: false));
      await c.auth.signInWithPassword(email: u['email'] as String, password: u['password'] as String);
      return c;
    }

    final admin = await signIn(users['admin'] as Map<String, dynamic>);
    final student = await signIn(users['paid_active'] as Map<String, dynamic>);
    final title = 'QA R2 Flutter ${DateTime.now().millisecondsSinceEpoch} Biology syllabus';
    final row = await admin.from('syllabus_documents').insert({
      'education_level': 'o-level',
      'subject_name': 'Biology',
      'title': title,
      'coverage': 'Form I - IV',
      'form_levels': [1, 2, 3, 4],
      // Files the staging migration copied into R2.
      'file_url': '$r2Base/syllabus/1795347486213_qa-syllabus.pdf',
      'thumbnail_url': '$r2Base/syllabus/1795347486213_qa-syllabus_cover.jpg',
      'is_published': true,
    }).select().single();

    final container = ProviderContainer(overrides: [supabaseClientProvider.overrideWithValue(student)]);
    try {
      final docs = await container.read(syllabusDocumentsProvider.future);
      final doc = docs.firstWhere((d) => d.title == title);
      expect(doc.thumbnailUrl, startsWith('$r2Base/'));
      expect(doc.fileUrl, startsWith('$r2Base/'));

      // The cover: what Image.network downloads, decoded as a picture.
      final cover = await download(doc.thumbnailUrl!);
      expect(cover.status, 200);
      expect(cover.type, 'image/jpeg');
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(cover.bytes));
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0));

      // The PDF the Read / Download buttons open.
      final pdf = await download(doc.fileUrl!);
      expect(pdf.status, 200);
      expect(pdf.type, 'application/pdf');
      expect(ascii.decode(pdf.bytes.take(5).toList()), '%PDF-');
      // ignore: avoid_print
      print('Flutter on staging: "$title" cover ${frame.image.width}x${frame.image.height} and PDF ${pdf.bytes.length} bytes from $r2Base');
    } finally {
      container.dispose();
      await admin.from('syllabus_documents').delete().eq('id', row['id'] as Object);
      await admin.dispose();
      await student.dispose();
    }
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
