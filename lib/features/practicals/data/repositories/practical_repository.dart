import '../models/practical_model.dart';

abstract class PracticalRepository {
  List<PracticalModel> getPracticalsByLevelAndSubject({
    required PracticalLevel level,
    required PracticalSubject subject,
  });

  PracticalModel? getPracticalById(String id);

  List<PracticalModel> getAllPracticals();
}
