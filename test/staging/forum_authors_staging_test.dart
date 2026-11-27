// Runs the real ForumRepository against STAGING to prove forum author names
// still load after students lost read access to other people's profiles
// (web repo migration 20261109120000_forum_author_names_only).
//
// Skipped unless QA_SECRETS_DIR points at the folder with stg_keys.json and
// qa_users.json (kept outside the repo):
//   QA_SECRETS_DIR=<folder> flutter test test/staging/forum_authors_staging_test.dart
//
// It posts one thread as the QA forum author and one reply as a QA student,
// and deletes both at the end.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/forum/data/repositories/forum_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const stagingUrl = 'https://eflfzxhyzjkdwbddrsha.supabase.co';

void main() {
  final dir = Platform.environment['QA_SECRETS_DIR'];
  final skip = dir == null ? 'QA_SECRETS_DIR not set (staging-only check)' : null;

  test('forum shows author names to a student, never their profile', () async {
    expect(stagingUrl.contains('jgdsinabjhytasybgtix'), false, reason: 'never production');
    final keys = jsonDecode(File('$dir/stg_keys.json').readAsStringSync()) as List;
    final anon = keys.firstWhere((k) => k['name'] == 'anon')['api_key'] as String;
    final users = jsonDecode(File('$dir/qa_users.json').readAsStringSync()) as Map<String, dynamic>;
    final author = users['forum_author'] as Map<String, dynamic>;
    final student = users['trial_new'] as Map<String, dynamic>;

    Future<SupabaseClient> signIn(Map<String, dynamic> u) async {
      final c = SupabaseClient(stagingUrl, anon,
          authOptions: const AuthClientOptions(autoRefreshToken: false));
      await c.auth.signInWithPassword(email: u['email'] as String, password: u['password'] as String);
      return c;
    }

    final authorClient = await signIn(author);
    final studentClient = await signIn(student);
    final asAuthor = ForumRepository(authorClient);
    final asStudent = ForumRepository(studentClient);

    final authorName = (await authorClient.from('profiles').select('full_name').eq('id', author['id']).single())['full_name'];
    final studentName = (await studentClient.from('profiles').select('full_name').eq('id', student['id']).single())['full_name'];

    final thread = await asAuthor.createDiscussion(title: 'QA flutter forum names', content: 'temporary');
    try {
      expect(thread.authorName, authorName);

      // The leak is closed: the student cannot read the author's profile row.
      final leaked = await studentClient.from('profiles').select('email, phone').eq('id', author['id']);
      expect(leaked, isEmpty);

      // ...but the forum list and detail still show the author's name.
      final list = await asStudent.getDiscussions();
      final listed = list.firstWhere((d) => d.id == thread.id);
      expect(listed.authorName, authorName);
      expect((await asStudent.getDiscussion(thread.id)).authorName, authorName);

      // A reply shows its author's name, to the replier and to others.
      final reply = await asStudent.createReply(discussionId: thread.id, content: 'temporary reply');
      expect(reply.authorName, studentName);
      final seenByAuthor = await asAuthor.getReplies(thread.id);
      expect(seenByAuthor.single.authorName, studentName);
      expect(seenByAuthor.single.authorRole, 'student');
      // ignore: avoid_print
      print('Flutter repository on staging: thread by "$authorName", reply by "$studentName"; student read of author profile = ${leaked.length} rows');
    } finally {
      await asAuthor.deleteDiscussion(thread.id);
      await authorClient.dispose();
      await studentClient.dispose();
    }
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
