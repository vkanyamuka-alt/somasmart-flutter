import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_score_result.dart';
import 'package:somasmart_flutter/features/practicals/data/repositories/practical_repository_impl.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_engine_registry.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_simulation_engine.dart';
import 'package:somasmart_flutter/features/practicals/domain/titration_engine.dart';

// Mock engine to demonstrate that future engines (e.g. Ohm's Law) can be registered seamlessly
class MockOhmsLawEngine implements PracticalSimulationEngine<String, String> {
  @override
  String get engineId => 'ohms_law';

  @override
  String get titleEn => "Ohm's Law Verification";

  @override
  String get titleSw => 'Uthibitisho wa Sheria ya Ohm';

  @override
  PracticalSubject get subject => PracticalSubject.physics;

  @override
  List<PracticalMode> get supportedModes => const [
        PracticalMode.guidedPractice,
        PracticalMode.examMode,
      ];

  @override
  String createInitialState(PracticalMode mode) => 'initial_ohms_law';

  @override
  String processAction(String currentState, String action) => 'action_$action';

  @override
  PracticalScoreResult calculateScore(String currentState) {
    return const PracticalScoreResult(
      practicalNameEn: "Ohm's Law",
      practicalNameSw: 'Sheria ya Ohm',
      totalScore: 90,
      grade: 'A',
      errorPercentage: 2.0,
      studentMolarity: 0.0,
      theoreticalMolarity: 0.0,
      studentTitreVolume: 0.0,
      durationFormatted: '15m 0s',
      competencies: [],
      achievementsEn: [],
      achievementsSw: [],
    );
  }

  @override
  String reset(PracticalMode mode) => 'initial_ohms_law';
}

void main() {
  group('Practical Simulation Framework & Engine Registry Tests', () {
    late PracticalEngineRegistry registry;

    setUp(() {
      registry = PracticalEngineRegistry();
      registry.clear();
      registry.registerEngine(AcidBaseTitrationEngine());
    });

    test('Engine #1 (Acid-Base Titration) is pre-registered and resolvable', () {
      expect(registry.isEngineRegistered('acid_base_titration'), isTrue);
      final engine = registry.resolveEngine('acid_base_titration');
      expect(engine, isNotNull);
      expect(engine?.engineId, equals('acid_base_titration'));
      expect(engine?.subject, equals(PracticalSubject.chemistry));
      expect(engine?.supportedModes.length, equals(3));
    });

    test('Future engine (e.g. Ohm\'s Law) can be dynamically registered without core code changes', () {
      expect(registry.isEngineRegistered('ohms_law'), isFalse);

      final ohmsLawEngine = MockOhmsLawEngine();
      registry.registerEngine(ohmsLawEngine);

      expect(registry.isEngineRegistered('ohms_law'), isTrue);
      final resolved = registry.resolveEngine('ohms_law');
      expect(resolved, isNotNull);
      expect(resolved?.engineId, equals('ohms_law'));
      expect(resolved?.subject, equals(PracticalSubject.physics));

      final physicsEngines = registry.getEnginesForSubject(PracticalSubject.physics);
      expect(physicsEngines.length, equals(1));
      expect(physicsEngines.first.engineId, equals('ohms_law'));
    });

    test('Unregistered engine returns null and is handled gracefully', () {
      expect(registry.isEngineRegistered('unimplemented_engine'), isFalse);
      expect(registry.resolveEngine('unimplemented_engine'), isNull);
    });

    test('Catalog Repository contains 27 authentic SomaSmart practicals', () {
      final repo = PracticalRepositoryImpl();
      final all = repo.getAllPracticals();
      expect(all.length, equals(27));

      final oChem = repo.getPracticalsByLevelAndSubject(
        level: PracticalLevel.oLevel,
        subject: PracticalSubject.chemistry,
      );
      expect(oChem.length, equals(9));

      final oPhys = repo.getPracticalsByLevelAndSubject(
        level: PracticalLevel.oLevel,
        subject: PracticalSubject.physics,
      );
      expect(oPhys.length, equals(3));

      final oBio = repo.getPracticalsByLevelAndSubject(
        level: PracticalLevel.oLevel,
        subject: PracticalSubject.biology,
      );
      expect(oBio.length, equals(2));

      final aChem = repo.getPracticalsByLevelAndSubject(
        level: PracticalLevel.aLevel,
        subject: PracticalSubject.chemistry,
      );
      expect(aChem.length, equals(7));

      final aPhys = repo.getPracticalsByLevelAndSubject(
        level: PracticalLevel.aLevel,
        subject: PracticalSubject.physics,
      );
      expect(aPhys.length, equals(3));

      final aBio = repo.getPracticalsByLevelAndSubject(
        level: PracticalLevel.aLevel,
        subject: PracticalSubject.biology,
      );
      expect(aBio.length, equals(3));
    });

    test('Practical lookup by ID returns correct practical model', () {
      final repo = PracticalRepositoryImpl();
      final titration = repo.getPracticalById('titration');
      expect(titration, isNotNull);
      expect(titration?.title, equals('Acid–Base Titration (HCl vs NaOH)'));
      expect(titration?.hasSimulationEngine, isTrue);
      expect(titration?.simulationEngineId, equals('acid_base_titration'));

      final nonExistent = repo.getPracticalById('invalid_id');
      expect(nonExistent, isNull);
    });
  });
}
