import 'package:flutter/material.dart';

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

  IconData get iconData {
    switch (iconKey.toLowerCase()) {
      case 'calculator':
      case 'mathematics':
      case 'math':
        return Icons.calculate_rounded;
      case 'atom':
      case 'physics':
        return Icons.biotech_rounded;
      case 'flask':
      case 'chemistry':
        return Icons.science_rounded;
      case 'dna':
      case 'biology':
        return Icons.coronavirus_rounded;
      case 'bookopen':
      case 'kiswahili':
        return Icons.menu_book_rounded;
      case 'languages':
      case 'english':
        return Icons.translate_rounded;
      case 'history':
        return Icons.history_edu_rounded;
      case 'globe':
      case 'geography':
        return Icons.public_rounded;
      case 'users':
      case 'civics':
        return Icons.account_balance_rounded;
      case 'trendingup':
      case 'economics':
        return Icons.trending_up_rounded;
      case 'shoppingbag':
      case 'commerce':
        return Icons.shopping_bag_rounded;
      case 'filespreadsheet':
      case 'bam':
        return Icons.functions_rounded;
      case 'compass':
      case 'general studies':
        return Icons.explore_rounded;
      default:
        return Icons.school_rounded;
    }
  }
}
