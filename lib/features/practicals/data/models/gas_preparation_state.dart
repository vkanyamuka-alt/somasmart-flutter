import 'package:flutter/foundation.dart';
import '../models/practical_model.dart';
import '../models/practical_score_result.dart';

/// Supported Gases for Laboratory Preparation Practical
enum PreparedGasType {
  oxygen,
  carbonDioxide,
  hydrogen;

  String get formula {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'O₂';
      case PreparedGasType.carbonDioxide:
        return 'CO₂';
      case PreparedGasType.hydrogen:
        return 'H₂';
    }
  }

  String get nameEn {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'Oxygen Gas (O₂)';
      case PreparedGasType.carbonDioxide:
        return 'Carbon Dioxide Gas (CO₂)';
      case PreparedGasType.hydrogen:
        return 'Hydrogen Gas (H₂)';
    }
  }

  String get nameSw {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'Gesi ya Oksijeni (O₂)';
      case PreparedGasType.carbonDioxide:
        return 'Gesi ya Dioksidi ya Kaboni (CO₂)';
      case PreparedGasType.hydrogen:
        return 'Gesi ya Haidrojeni (H₂)';
    }
  }

  String get solidFormula {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'MnO₂';
      case PreparedGasType.carbonDioxide:
        return 'CaCO₃';
      case PreparedGasType.hydrogen:
        return 'Zn';
    }
  }

  String get liquidFormula {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'H₂O₂';
      case PreparedGasType.carbonDioxide:
        return '2.0M HCl';
      case PreparedGasType.hydrogen:
        return '2.0M HCl';
    }
  }

  String get solidNameEn {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'Manganese(IV) Oxide (MnO₂) Powder';
      case PreparedGasType.carbonDioxide:
        return 'Calcium Carbonate / Marble (CaCO₃) Chips';
      case PreparedGasType.hydrogen:
        return 'Granulated Zinc (Zn) Pellets';
    }
  }

  String get solidNameSw {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'Unga wa Manganese(IV) Oxide (MnO₂)';
      case PreparedGasType.carbonDioxide:
        return 'Vipande vya Calcium Carbonate (CaCO₃)';
      case PreparedGasType.hydrogen:
        return 'Chembechembe za Metali ya Zinki (Zn)';
    }
  }

  String get liquidNameEn {
    switch (this) {
      case PreparedGasType.oxygen:
        return '20-volume Hydrogen Peroxide (H₂O₂)';
      case PreparedGasType.carbonDioxide:
        return 'Dilute Hydrochloric Acid (2.0 M HCl)';
      case PreparedGasType.hydrogen:
        return 'Dilute Hydrochloric Acid (2.0 M HCl)';
    }
  }

  String get liquidNameSw {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'Myeyusho wa Hydrogen Peroxide (H₂O₂)';
      case PreparedGasType.carbonDioxide:
        return 'Asidi ya Hydrochloric 2.0 M (HCl)';
      case PreparedGasType.hydrogen:
        return 'Asidi ya Hydrochloric 2.0 M (HCl)';
    }
  }

  String get collectionMethodEn {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'Over water (Downward displacement of water)';
      case PreparedGasType.carbonDioxide:
        return 'Downward delivery (Upward displacement of air)';
      case PreparedGasType.hydrogen:
        return 'Over water (Downward displacement of water)';
    }
  }

  String get collectionMethodSw {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'Juu ya maji (Kusukuma maji chini)';
      case PreparedGasType.carbonDioxide:
        return 'Kushusha chini (Kusukuma hewa juu)';
      case PreparedGasType.hydrogen:
        return 'Juu ya maji (Kusukuma maji chini)';
    }
  }

  String get collectionReasonEn {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'Oxygen is only slightly soluble in water and has similar density to air.';
      case PreparedGasType.carbonDioxide:
        return 'Carbon dioxide is denser than air and moderately soluble in water.';
      case PreparedGasType.hydrogen:
        return 'Hydrogen is practically insoluble in water and much lighter than air.';
    }
  }

  String get collectionReasonSw {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'Oksijeni huyeyuka kidogo sana kwenye maji na ina uzito unaolingana na hewa.';
      case PreparedGasType.carbonDioxide:
        return 'Dioksidi ya kaboni ni nzito kuliko hewa na huyeyuka kiasi kwenye maji.';
      case PreparedGasType.hydrogen:
        return 'Haidrojeni haiyeyuki kabisa kwenye maji na ni nyepesi zaidi kuliko hewa.';
    }
  }

  String get equation {
    switch (this) {
      case PreparedGasType.oxygen:
        return '2H₂O₂ (aq) —[MnO₂]→ 2H₂O (l) + O₂ (g)↑';
      case PreparedGasType.carbonDioxide:
        return 'CaCO₃ (s) + 2HCl (aq) → CaCl₂ (aq) + H₂O (l) + CO₂ (g)↑';
      case PreparedGasType.hydrogen:
        return 'Zn (s) + 2HCl (aq) → ZnCl₂ (aq) + H₂ (g)↑';
    }
  }

  String get testDescriptionEn {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'Insert a glowing wooden splint into the gas jar.';
      case PreparedGasType.carbonDioxide:
        return 'Bubble the gas through clear limewater (calcium hydroxide solution).';
      case PreparedGasType.hydrogen:
        return 'Introduce a burning wooden splint to the mouth of the inverted gas jar.';
    }
  }

  String get testDescriptionSw {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'Ingiza kijiti cha ubao chenye cheche/moshi ndani ya chupa ya gesi.';
      case PreparedGasType.carbonDioxide:
        return 'Pitisha gesi kwenye maji safi ya chokaa (calcium hydroxide).';
      case PreparedGasType.hydrogen:
        return 'Weka kijiti chenye mwali wa moto mdomoni mwa chupa ya gesi.';
    }
  }

  String get testObservationEn {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'The glowing wooden splint relights and bursts into a bright flame.';
      case PreparedGasType.carbonDioxide:
        return 'The clear limewater turns milky white due to insoluble calcium carbonate precipitate.';
      case PreparedGasType.hydrogen:
        return 'The gas ignites with a characteristic sharp squeaky "pop" sound.';
    }
  }

  String get testObservationSw {
    switch (this) {
      case PreparedGasType.oxygen:
        return 'Kijiti chenye cheche kinawaka moto tena kwa mwali mkali.';
      case PreparedGasType.carbonDioxide:
        return 'Maji ya chokaa yanageuka kuwa na ukungu mweupe wa mvua ya calcium carbonate.';
      case PreparedGasType.hydrogen:
        return 'Gesi inawaka kwa kutoa mlio mkali wa "pop".';
    }
  }
}

/// Steps in the Gas Preparation Virtual Laboratory Practical
enum GasPrepStep {
  selectGas,
  inspectApparatus,
  assembleAndReact,
  collectGas,
  testAndScore;

  String get labelEn {
    switch (this) {
      case GasPrepStep.selectGas:
        return '1. Select Gas';
      case GasPrepStep.inspectApparatus:
        return '2. Inspect Apparatus';
      case GasPrepStep.assembleAndReact:
        return '3. Assemble & React';
      case GasPrepStep.collectGas:
        return '4. Collect Gas';
      case GasPrepStep.testAndScore:
        return '5. Test & Score';
    }
  }

  String get labelSw {
    switch (this) {
      case GasPrepStep.selectGas:
        return '1. Chagua Gesi';
      case GasPrepStep.inspectApparatus:
        return '2. Kagua Vifaa';
      case GasPrepStep.assembleAndReact:
        return '3. Unganisha & Mmenyuko';
      case GasPrepStep.collectGas:
        return '4. Kusanya Gesi';
      case GasPrepStep.testAndScore:
        return '5. Jaribu & Alama';
    }
  }
}

/// Represents an apparatus item to inspect in Step 2
@immutable
class GasApparatusItem {
  final String id;
  final String nameEn;
  final String nameSw;
  final String specEn;
  final String specSw;
  final bool inspected;

  const GasApparatusItem({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    required this.specEn,
    required this.specSw,
    this.inspected = false,
  });

  GasApparatusItem copyWith({bool? inspected}) {
    return GasApparatusItem(
      id: id,
      nameEn: nameEn,
      nameSw: nameSw,
      specEn: specEn,
      specSw: specSw,
      inspected: inspected ?? this.inspected,
    );
  }
}

/// Comprehensive State for the Laboratory Preparation of Gases Virtual Laboratory
@immutable
class GasPreparationState {
  final GasPrepStep step;
  final PreparedGasType selectedGas;
  final List<GasApparatusItem> apparatus;
  final bool isSolidAdded;
  final bool isLiquidAdded;
  final bool isGenerating;
  final double collectedVolumeMl; // 0.0 to 100.0 mL
  final bool isGasJarFull;
  final bool isTestPerformed;
  final bool testPassed;
  final String? studentObservationNote;
  final int experimentDurationSeconds;
  final PracticalMode practicalMode;
  final PracticalScoreResult? scoreResult;

  const GasPreparationState({
    required this.step,
    this.selectedGas = PreparedGasType.oxygen,
    required this.apparatus,
    this.isSolidAdded = false,
    this.isLiquidAdded = false,
    this.isGenerating = false,
    this.collectedVolumeMl = 0.0,
    this.isGasJarFull = false,
    this.isTestPerformed = false,
    this.testPassed = false,
    this.studentObservationNote,
    this.experimentDurationSeconds = 0,
    this.practicalMode = PracticalMode.guidedPractice,
    this.scoreResult,
  });

  /// Factory for the initial state of the practical
  factory GasPreparationState.initial(PracticalMode mode) {
    return GasPreparationState(
      step: GasPrepStep.selectGas,
      practicalMode: mode,
      apparatus: const [
        GasApparatusItem(
          id: 'generator_flask',
          nameEn: 'Flat-bottomed Generator Flask',
          nameSw: 'Chupa ya Kuzalishia Gesi',
          specEn: '250 mL borosilicate flask with two-hole rubber stopper.',
          specSw: 'Chupa ya glasi ya 250 mL yenye kizibo cha mpira chenye matundu mawili.',
        ),
        GasApparatusItem(
          id: 'thistle_funnel',
          nameEn: 'Thistle Funnel (Safety Delivery)',
          nameSw: 'Faneli ya Thistle ya Usalama',
          specEn: 'Long stem dipping below liquid level to prevent gas backflow.',
          specSw: 'Bomba refu linalozama chini ya kioevu kuzuia gesi isirudi nyuma.',
        ),
        GasApparatusItem(
          id: 'delivery_tube',
          nameEn: 'Glass Delivery Tube',
          nameSw: 'Bomba la Kupitishia Gesi',
          specEn: 'Right-angled bent tube routing gas to collection vessel.',
          specSw: 'Bomba la kioo lililopinda kupitisha gesi kwenye chombo cha ukusanyaji.',
        ),
        GasApparatusItem(
          id: 'pneumatic_trough',
          nameEn: 'Pneumatic Water Trough',
          nameSw: 'Bwawa la Maji la Pneumatic',
          specEn: 'Holds water reservoir for downward displacement of water.',
          specSw: 'Lina maji ya kutosha kwa ajili ya kusukuma maji chini.',
        ),
        GasApparatusItem(
          id: 'beehive_shelf',
          nameEn: 'Beehive Shelf Stand',
          nameSw: 'Rafu ya Beehive',
          specEn: 'Submerged ceramic stand supporting the inverted gas jar.',
          specSw: 'Kiti cha kauri kinachoshikilia chupa ya gesi iliyogeuzwa.',
        ),
        GasApparatusItem(
          id: 'gas_jar',
          nameEn: 'Graduated Gas Collection Jar',
          nameSw: 'Chupa ya Kukusanyia Gesi',
          specEn: '100 mL heavy-walled jar for gas capture and testing.',
          specSw: 'Chupa ya 100 mL kwa ajili ya kuhifadhi na kupimia gesi.',
        ),
      ],
    );
  }

  bool get allApparatusInspected => apparatus.every((item) => item.inspected);

  GasPreparationState copyWith({
    GasPrepStep? step,
    PreparedGasType? selectedGas,
    List<GasApparatusItem>? apparatus,
    bool? isSolidAdded,
    bool? isLiquidAdded,
    bool? isGenerating,
    double? collectedVolumeMl,
    bool? isGasJarFull,
    bool? isTestPerformed,
    bool? testPassed,
    String? studentObservationNote,
    int? experimentDurationSeconds,
    PracticalMode? practicalMode,
    PracticalScoreResult? scoreResult,
  }) {
    return GasPreparationState(
      step: step ?? this.step,
      selectedGas: selectedGas ?? this.selectedGas,
      apparatus: apparatus ?? this.apparatus,
      isSolidAdded: isSolidAdded ?? this.isSolidAdded,
      isLiquidAdded: isLiquidAdded ?? this.isLiquidAdded,
      isGenerating: isGenerating ?? this.isGenerating,
      collectedVolumeMl: collectedVolumeMl ?? this.collectedVolumeMl,
      isGasJarFull: isGasJarFull ?? this.isGasJarFull,
      isTestPerformed: isTestPerformed ?? this.isTestPerformed,
      testPassed: testPassed ?? this.testPassed,
      studentObservationNote: studentObservationNote ?? this.studentObservationNote,
      experimentDurationSeconds: experimentDurationSeconds ?? this.experimentDurationSeconds,
      practicalMode: practicalMode ?? this.practicalMode,
      scoreResult: scoreResult ?? this.scoreResult,
    );
  }
}
