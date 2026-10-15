import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/practical_model.dart';
import '../../data/repositories/practical_repository_impl.dart';

final selectedPracticalLevelProvider = StateProvider<PracticalLevel>((ref) {
  return PracticalLevel.oLevel;
});

final selectedPracticalSubjectProvider = StateProvider<PracticalSubject>((ref) {
  return PracticalSubject.chemistry;
});

final practicalSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

final practicalCatalogListProvider = Provider<List<PracticalModel>>((ref) {
  final repo = ref.watch(practicalRepositoryProvider);
  final level = ref.watch(selectedPracticalLevelProvider);
  final subject = ref.watch(selectedPracticalSubjectProvider);
  final query = ref.watch(practicalSearchQueryProvider).toLowerCase().trim();

  final list = repo.getPracticalsByLevelAndSubject(level: level, subject: subject);
  if (query.isEmpty) {
    return list;
  }
  return list.where((p) {
    return p.title.toLowerCase().contains(query) ||
        p.titleSw.toLowerCase().contains(query) ||
        p.category.toLowerCase().contains(query) ||
        p.description.toLowerCase().contains(query);
  }).toList();
});
