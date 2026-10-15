import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/practical_model.dart';
import 'gas_preparation_engine.dart';
import 'microscope_engine.dart';
import 'ohms_law_engine.dart';
import 'optics_engine.dart';
import 'osmosis_engine.dart';
import 'pendulum_engine.dart';
import 'practical_simulation_engine.dart';
import 'rates_of_reaction_engine.dart';
import 'titration_engine.dart';

final practicalEngineRegistryProvider = Provider<PracticalEngineRegistry>((ref) {
  final registry = PracticalEngineRegistry();
  // Pre-register Engine #1: Acid–Base Titration
  registry.registerEngine(AcidBaseTitrationEngine());
  // Pre-register Engine #2: Ohm's Law Verification
  registry.registerEngine(OhmsLawEngine());
  // Pre-register Engine #3: Light Microscope Cell Staining
  registry.registerEngine(MicroscopeEngine());
  // Pre-register Engine #4: Simple Pendulum Gravitational Acceleration
  registry.registerEngine(PendulumEngine());
  // Pre-register Engine #5: Refraction & Prism (Determination of Refractive Index)
  registry.registerEngine(OpticsEngine());
  // Pre-register Engine #6: Osmosis in Potato Tissues
  registry.registerEngine(OsmosisEngine());
  // Pre-register Engine #7: Rates of Chemical Reactions (Thiosulfate & Acid)
  registry.registerEngine(RatesOfReactionEngine());
  // Pre-register Engine #8: Laboratory Preparation of Gases
  registry.registerEngine(GasPreparationEngine());
  return registry;
});

/// Extensible Registry for Virtual Laboratory Simulation Engines.
/// Allows dynamic registration and lookup of simulation engines without large switch/if-else chains.
class PracticalEngineRegistry {
  static final PracticalEngineRegistry _instance = PracticalEngineRegistry._internal();

  factory PracticalEngineRegistry() => _instance;

  PracticalEngineRegistry._internal() {
    registerEngine(AcidBaseTitrationEngine());
    registerEngine(OhmsLawEngine());
    registerEngine(MicroscopeEngine());
    registerEngine(PendulumEngine());
    registerEngine(OpticsEngine());
    registerEngine(OsmosisEngine());
    registerEngine(RatesOfReactionEngine());
    registerEngine(GasPreparationEngine());
  }

  final Map<String, PracticalSimulationEngine<dynamic, dynamic>> _engines = {};

  /// Registers a new simulation engine into the framework
  void registerEngine(PracticalSimulationEngine<dynamic, dynamic> engine) {
    _engines[engine.engineId] = engine;
  }

  /// Unregisters an engine by its engine ID (useful in tests)
  void unregisterEngine(String engineId) {
    _engines.remove(engineId);
  }

  /// Determines whether a simulation engine is implemented and registered
  bool isEngineRegistered(String engineId) {
    if (engineId == 'gas-prep' || engineId == 'gas_prep' || engineId == 'gas-preparation') {
      return _engines.containsKey('gas_preparation');
    }
    if (engineId == 'reaction-rates' || engineId == 'rates-of-reaction' || engineId == 'reaction_rates') {
      return _engines.containsKey('rates_of_reaction');
    }
    if (engineId == 'osmosis-bio') return _engines.containsKey('osmosis');
    if (engineId == 'optics-phys') return _engines.containsKey('optics');
    if (engineId == 'pendulum-phys') return _engines.containsKey('pendulum');
    if (engineId == 'microscope-bio') return _engines.containsKey('microscope');
    if (engineId == 'ohms-phys') return _engines.containsKey('ohms_law');
    return _engines.containsKey(engineId);
  }

  /// Resolves an engine by engine ID
  PracticalSimulationEngine<dynamic, dynamic>? resolveEngine(String engineId) {
    if (engineId == 'gas-prep' || engineId == 'gas_prep' || engineId == 'gas-preparation') {
      return _engines['gas_preparation'];
    }
    if (engineId == 'reaction-rates' || engineId == 'rates-of-reaction' || engineId == 'reaction_rates') {
      return _engines['rates_of_reaction'];
    }
    if (engineId == 'osmosis-bio') return _engines['osmosis'];
    if (engineId == 'optics-phys') return _engines['optics'];
    if (engineId == 'pendulum-phys') return _engines['pendulum'];
    if (engineId == 'microscope-bio') return _engines['microscope'];
    if (engineId == 'ohms-phys') return _engines['ohms_law'];
    return _engines[engineId];
  }

  /// Finds all engines registered for a given subject
  List<PracticalSimulationEngine<dynamic, dynamic>> getEnginesForSubject(PracticalSubject subject) {
    return _engines.values.where((e) => e.subject == subject).toList();
  }

  /// Returns all currently registered engine IDs
  List<String> get registeredEngineIds => List.unmodifiable(_engines.keys);

  /// Clears all registered engines (useful for isolated unit testing)
  void clear() {
    _engines.clear();
  }
}
