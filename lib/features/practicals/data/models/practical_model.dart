enum PracticalLevel {
  oLevel,
  aLevel,
}

enum PracticalSubject {
  chemistry,
  physics,
  biology,
}

enum PracticalMode {
  guidedPractice,
  examMode,
  freeExploration,
}

extension PracticalLevelExtension on PracticalLevel {
  String get id {
    switch (this) {
      case PracticalLevel.oLevel:
        return 'o-level';
      case PracticalLevel.aLevel:
        return 'a-level';
    }
  }

  String get labelEn {
    switch (this) {
      case PracticalLevel.oLevel:
        return 'O-Level (Forms 1–4)';
      case PracticalLevel.aLevel:
        return 'A-Level (Forms 5–6)';
    }
  }

  String get labelSw {
    switch (this) {
      case PracticalLevel.oLevel:
        return 'Kidato cha 1–4 (O-Level)';
      case PracticalLevel.aLevel:
        return 'Kidato cha 5–6 (A-Level)';
    }
  }

  static PracticalLevel fromId(String id) {
    if (id.toLowerCase() == 'a-level') {
      return PracticalLevel.aLevel;
    }
    return PracticalLevel.oLevel;
  }
}

extension PracticalSubjectExtension on PracticalSubject {
  String get id {
    switch (this) {
      case PracticalSubject.chemistry:
        return 'chemistry';
      case PracticalSubject.physics:
        return 'physics';
      case PracticalSubject.biology:
        return 'biology';
    }
  }

  String get labelEn {
    switch (this) {
      case PracticalSubject.chemistry:
        return 'Chemistry';
      case PracticalSubject.physics:
        return 'Physics';
      case PracticalSubject.biology:
        return 'Biology';
    }
  }

  String get labelSw {
    switch (this) {
      case PracticalSubject.chemistry:
        return 'Kemia (Chemistry)';
      case PracticalSubject.physics:
        return 'Fizikia (Physics)';
      case PracticalSubject.biology:
        return 'Biolojia (Biology)';
    }
  }

  static PracticalSubject fromId(String id) {
    switch (id.toLowerCase()) {
      case 'physics':
        return PracticalSubject.physics;
      case 'biology':
        return PracticalSubject.biology;
      case 'chemistry':
      default:
        return PracticalSubject.chemistry;
    }
  }
}

extension PracticalModeExtension on PracticalMode {
  String get id {
    switch (this) {
      case PracticalMode.guidedPractice:
        return 'Guided Practice';
      case PracticalMode.examMode:
        return 'Exam Mode';
      case PracticalMode.freeExploration:
        return 'Free Exploration';
    }
  }

  String get labelEn {
    switch (this) {
      case PracticalMode.guidedPractice:
        return 'Guided Practice';
      case PracticalMode.examMode:
        return 'Exam Mode';
      case PracticalMode.freeExploration:
        return 'Free Exploration';
    }
  }

  String get labelSw {
    switch (this) {
      case PracticalMode.guidedPractice:
        return 'Mazoezi Yenye Muongozo';
      case PracticalMode.examMode:
        return 'Hali ya Mtihani';
      case PracticalMode.freeExploration:
        return 'Ugunduzi Huria';
    }
  }

  String get descEn {
    switch (this) {
      case PracticalMode.guidedPractice:
        return 'The AI guides you step by step throughout the practical with hints & explanations.';
      case PracticalMode.examMode:
        return 'Simulate a real practical examination under timed conditions without hints.';
      case PracticalMode.freeExploration:
        return 'Experiment freely in the laboratory workspace without sequential step locking.';
    }
  }

  String get descSw {
    switch (this) {
      case PracticalMode.guidedPractice:
        return 'Msaidizi anakuongoza hatua kwa hatua kwa vidokezo na maelezo ya kina.';
      case PracticalMode.examMode:
        return 'Fanya mtihani halisi wa maabara kwa muda maalum bila vidokezo.';
      case PracticalMode.freeExploration:
        return 'Fanya majaribio kwa uhuru maabarani bila kufungwa na mtiririko wa hatua.';
    }
  }

  static PracticalMode fromId(String id) {
    if (id.toLowerCase().contains('exam')) {
      return PracticalMode.examMode;
    }
    if (id.toLowerCase().contains('free') || id.toLowerCase().contains('exploration')) {
      return PracticalMode.freeExploration;
    }
    return PracticalMode.guidedPractice;
  }
}

class PracticalModel {
  final String id;
  final int number;
  final String title;
  final String titleSw;
  final PracticalSubject subject;
  final PracticalLevel level;
  final String category;
  final String categorySw;
  final String difficulty;
  final String duration;
  final String description;
  final String descriptionSw;
  final String learningObjectivesEn;
  final String learningObjectivesSw;
  final List<String> requiredEquipment;
  final List<String> requiredReagents;
  final String? simulationEngineId;
  final bool isCompleted;
  final int progressPercent;
  final String thumbnailType;

  const PracticalModel({
    required this.id,
    required this.number,
    required this.title,
    required this.titleSw,
    required this.subject,
    required this.level,
    required this.category,
    required this.categorySw,
    required this.difficulty,
    required this.duration,
    required this.description,
    required this.descriptionSw,
    required this.learningObjectivesEn,
    required this.learningObjectivesSw,
    this.requiredEquipment = const [],
    this.requiredReagents = const [],
    this.simulationEngineId,
    this.isCompleted = false,
    this.progressPercent = 0,
    this.thumbnailType = 'flask',
  });

  bool get hasSimulationEngine => simulationEngineId != null && simulationEngineId!.isNotEmpty;
}
