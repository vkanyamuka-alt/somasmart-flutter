/// Badge shown next to a forum author's name. Only staff get one: teachers
/// (owner's decision: teachers may answer in the forum with a "Teacher" badge)
/// and admins. Students get none. Website mirror: src/lib/forumRole.js
/// (shared cases: test/fixtures/forum_role_cases.json = src/lib/forumRoleCases.json).
enum ForumRoleKind { teacher, admin }

class ForumRoleBadgeInfo {
  const ForumRoleBadgeInfo(this.kind, this.label);
  final ForumRoleKind kind;
  final String label;
}

ForumRoleBadgeInfo? forumRoleBadge(String? role, String lang) {
  final r = (role ?? '').toLowerCase();
  if (r == 'teacher') {
    return ForumRoleBadgeInfo(ForumRoleKind.teacher, lang == 'en' ? 'Teacher' : 'Mwalimu');
  }
  if (r == 'admin') return const ForumRoleBadgeInfo(ForumRoleKind.admin, 'Admin');
  return null;
}
