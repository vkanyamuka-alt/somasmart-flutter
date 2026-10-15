/// Domain model mirroring the `syllabus_documents` Supabase table.
class SyllabusDocument {
  final String id;
  final String title;
  final String subjectName;
  final String educationLevel; // 'o-level' | 'a-level'
  final String? coverage;      // e.g. "Form I – IV"
  final String? academicYear;
  final String? fileUrl;
  final String? thumbnailUrl;
  final bool isVerified;
  final bool isPublished;
  final bool downloadAllowed;
  final String? officialSourceUrl;
  final String? sourceOrganization;
  final String? version;       // 'Current' | year string

  const SyllabusDocument({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.educationLevel,
    this.coverage,
    this.academicYear,
    this.fileUrl,
    this.thumbnailUrl,
    this.isVerified = false,
    this.isPublished = true,
    this.downloadAllowed = false,
    this.officialSourceUrl,
    this.sourceOrganization,
    this.version,
  });

  factory SyllabusDocument.fromMap(Map<String, dynamic> map) {
    return SyllabusDocument(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subjectName: map['subject_name']?.toString() ?? '',
      educationLevel: map['education_level']?.toString() ?? 'o-level',
      coverage: map['coverage']?.toString(),
      academicYear: map['academic_year']?.toString(),
      fileUrl: map['file_url']?.toString(),
      thumbnailUrl: map['thumbnail_url']?.toString(),
      isVerified: map['is_verified'] == true,
      isPublished: map['is_published'] != false,
      downloadAllowed: map['download_allowed'] == true,
      officialSourceUrl: map['official_source_url']?.toString(),
      sourceOrganization: map['source_organization']?.toString(),
      version: map['version']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject_name': subjectName,
      'education_level': educationLevel,
      'coverage': coverage,
      'academic_year': academicYear,
      'file_url': fileUrl,
      'thumbnail_url': thumbnailUrl,
      'is_verified': isVerified,
      'is_published': isPublished,
      'download_allowed': downloadAllowed,
      'official_source_url': officialSourceUrl,
      'source_organization': sourceOrganization,
      'version': version,
    };
  }
}
