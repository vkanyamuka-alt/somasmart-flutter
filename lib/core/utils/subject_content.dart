/// Which tab of a subject page each item shows in. The admin panel's Content
/// page sets the tab; the website uses the same rule (src/lib/subjectContent.js).
/// Shared cases: test/fixtures/subject_content_cases.json.
///
/// Tabs: notes (Muhtasari) · understand (Elewa na Miliki) · memorize (Kumbuka)
///   written notes   notes.section               default notes
///   videos / files  learning_materials.section  default understand
///   memory cards    memorize_items              always memorize
enum SubjectTab { notes, understand, memorize }

enum ContentKind { note, material, card }

const _tabOfSection = {
  'notes': SubjectTab.notes,
  'understand_master': SubjectTab.understand,
  'memorize': SubjectTab.memorize,
};

/// The tab an item of [kind] with the stored [section] belongs in.
SubjectTab tabOf(ContentKind kind, String? section) {
  if (kind == ContentKind.card) return SubjectTab.memorize;
  return _tabOfSection[section] ??
      (kind == ContentKind.note ? SubjectTab.notes : SubjectTab.understand);
}
