import '../../../../core/widgets/soma_icon.dart';

/// Subject data model matching Supabase `subjects` table.
class SubjectModel {
  final String id;
  final String nameSw;
  final String nameEn;
  final List<int> formLevels;
  final String iconKey;
  final String? description;

  const SubjectModel({
    required this.id,
    required this.nameSw,
    required this.nameEn,
    required this.formLevels,
    required this.iconKey,
    this.description,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    List<int> levels = [1, 2, 3, 4];
    if (map['form_levels'] != null) {
      if (map['form_levels'] is List) {
        levels = (map['form_levels'] as List)
            .map((e) => (e as num).toInt())
            .toList();
      }
    }

    return SubjectModel(
      id: map['id']?.toString() ?? '',
      nameSw: map['name_sw'] as String? ?? 'Somo',
      nameEn: map['name_en'] as String? ?? 'Subject',
      formLevels: levels,
      iconKey: map['icon'] as String? ?? 'BookOpen',
      description: map['description'] as String?,
    );
  }

  /// The SomaSmart drawing for this subject (lib/core/widgets/soma_icon.dart).
  String get somaIcon {
    for (final v in [id, nameEn, nameSw, iconKey]) {
      final k = subjectIconKey(v);
      if (k != 'default') return k;
    }
    return 'default';
  }
}
