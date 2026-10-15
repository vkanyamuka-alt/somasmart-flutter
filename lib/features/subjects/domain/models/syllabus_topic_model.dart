/// Topic item in NECTA secondary syllabus.
class SyllabusTopic {
  final String en;
  final String sw;

  const SyllabusTopic({required this.en, required this.sw});
}

/// Note summary entity for notes listed inside a subject.
class SubjectNoteItem {
  final String id;
  final String subjectId;
  final String title;
  final String description;
  final int formLevel;
  final String language;
  final String authorName;
  final int downloads;
  final String? topic;
  /// Raw content body — Markdown, HTML, or plain text.
  final String? textContent;
  /// 'text' (default) or 'pdf'.
  final String fileType;

  const SubjectNoteItem({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.formLevel,
    required this.language,
    required this.authorName,
    this.downloads = 0,
    this.topic,
    this.textContent,
    this.fileType = 'text',
  });

  factory SubjectNoteItem.fromMap(Map<String, dynamic> map) {
    return SubjectNoteItem(
      id: map['id']?.toString() ?? '',
      subjectId: map['subject_id']?.toString() ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      formLevel: (map['form_level'] as num?)?.toInt() ?? 4,
      language: map['language'] as String? ?? 'both',
      authorName: (map['profiles'] is Map
              ? map['profiles']['full_name']
              : null) ??
          map['author_name'] as String? ??
          'SomaSmart Admin',
      downloads: (map['downloads'] as num?)?.toInt() ?? 0,
      topic: map['topic'] as String?,
      textContent: map['text_content'] as String?,
      fileType: map['file_type'] as String? ?? 'text',
    );
  }
}

/// Learning Material entity (Video, Audio, Document) for Understand & Master tab.
class SubjectMaterialItem {
  final String id;
  final String subjectId;
  final String title;
  final String description;
  final String shortDescription;
  final String materialType; // video, audio, document
  final String? externalUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final int formLevel;
  final String language;
  final String? topic;
  final DateTime? publishedAt;

  const SubjectMaterialItem({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    this.shortDescription = '',
    required this.materialType,
    this.externalUrl,
    this.thumbnailUrl,
    this.durationSeconds = 0,
    required this.formLevel,
    this.language = 'both',
    this.topic,
    this.publishedAt,
  });

  factory SubjectMaterialItem.fromMap(Map<String, dynamic> map) {
    return SubjectMaterialItem(
      id: map['id']?.toString() ?? '',
      subjectId: map['subject_id']?.toString() ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      shortDescription: map['short_description'] as String? ?? '',
      materialType: map['material_type'] as String? ?? 'video',
      externalUrl: map['external_url'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
      formLevel: (map['form_level'] as num?)?.toInt() ?? 4,
      language: map['language'] as String? ?? 'both',
      topic: map['topic'] as String?,
      publishedAt: map['published_at'] != null
          ? DateTime.tryParse(map['published_at'] as String)
          : null,
    );
  }
}

/// Memorize item entity (formula, mnemonic, memory_trick) for Memorize tab.
class SubjectMemorizeItem {
  final String id;
  final String subjectId;
  final String topic;
  final int formLevel;
  final String itemType; // formula, mnemonic, memory_trick
  final String title;
  final String content;

  const SubjectMemorizeItem({
    required this.id,
    required this.subjectId,
    required this.topic,
    required this.formLevel,
    required this.itemType,
    required this.title,
    required this.content,
  });

  factory SubjectMemorizeItem.fromMap(Map<String, dynamic> map) {
    return SubjectMemorizeItem(
      id: map['id']?.toString() ?? '',
      subjectId: map['subject_id']?.toString() ?? '',
      topic: map['topic'] as String? ?? '',
      formLevel: (map['form_level'] as num?)?.toInt() ?? 4,
      itemType: map['item_type'] as String? ?? 'formula',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
    );
  }
}

/// Official NECTA syllabus topics dictionary matching React `syllabusData.js`.
const Map<String, Map<int, List<SyllabusTopic>>> syllabusTopicsData = {
  'mathematics': {
    1: [
      SyllabusTopic(en: 'Numbers', sw: 'Namba'),
      SyllabusTopic(en: 'Fractions', sw: 'Sehemu'),
      SyllabusTopic(en: 'Decimals and Percentages', sw: 'Desimali na Asilimia'),
      SyllabusTopic(en: 'Units', sw: 'Vipimo'),
      SyllabusTopic(en: 'Approximations', sw: 'Kukadiria'),
      SyllabusTopic(en: 'Geometry', sw: 'Jiometri'),
      SyllabusTopic(en: 'Algebra', sw: 'Aljebra'),
      SyllabusTopic(en: 'Numbers Relations', sw: 'Uhusiano wa Namba'),
      SyllabusTopic(en: 'Formulae', sw: 'Fomula'),
      SyllabusTopic(en: 'Coordinate Geometry', sw: 'Jiometri ya Kuratibu'),
    ],
    2: [
      SyllabusTopic(en: 'Exponents and Radicals', sw: 'Kielezi na Mzizi'),
      SyllabusTopic(en: 'Algebra', sw: 'Aljebra'),
      SyllabusTopic(en: 'Quadratic Equations', sw: 'Milinganyo ya Kipeo cha Pili'),
      SyllabusTopic(en: 'Logarithms', sw: 'Logariti'),
      SyllabusTopic(en: 'Congruence', sw: 'Ulinganifu'),
      SyllabusTopic(en: 'Similarity', sw: 'Mfanano'),
      SyllabusTopic(en: 'Geometric Transformations', sw: 'Mabadiliko ya Kijiometri'),
      SyllabusTopic(en: 'Pythagoras Theorem', sw: 'Nadharia ya Pythagoras'),
      SyllabusTopic(en: 'Trigonometry', sw: 'Trigonometria'),
      SyllabusTopic(en: 'Sets', sw: 'Seti'),
      SyllabusTopic(en: 'Statistics', sw: 'Takwimu'),
      SyllabusTopic(en: 'Rates and Variations', sw: 'Viwango na Mabadiliko'),
    ],
    3: [
      SyllabusTopic(en: 'Relations', sw: 'Uhusiano'),
      SyllabusTopic(en: 'Functions', sw: 'Kazi'),
      SyllabusTopic(en: 'Statistics', sw: 'Takwimu'),
      SyllabusTopic(en: 'Sequences and Series', sw: 'Mfuatano na Mfululizo'),
      SyllabusTopic(en: 'Circles', sw: 'Duara'),
      SyllabusTopic(en: 'The Earth as a Sphere', sw: 'Dunia kama tufe'),
    ],
    4: [
      SyllabusTopic(en: 'Coordinate Geometry', sw: 'Jiometri ya Kuratibu'),
      SyllabusTopic(en: 'Vectors', sw: 'Vekta'),
      SyllabusTopic(en: 'Matrices', sw: 'Matriki'),
      SyllabusTopic(en: 'Linear Programming', sw: 'U programu wa Linear'),
      SyllabusTopic(en: 'Probability', sw: 'Nafasi (Uwezekano)'),
      SyllabusTopic(en: 'Trigonometry', sw: 'Trigonometria'),
    ],
  },
  'physics': {
    1: [
      SyllabusTopic(en: 'Introduction to Physics', sw: 'Utangulizi wa Fizikia'),
      SyllabusTopic(en: 'Introduction to Laboratory Practice', sw: 'Utangulizi wa Mazoezi ya Maabara'),
      SyllabusTopic(en: 'Measurement', sw: 'Vipimo'),
      SyllabusTopic(en: 'Force', sw: 'Nguvu'),
      SyllabusTopic(en: "Archimedes' Principle and Law of Flotation", sw: 'Kanuni ya Archimedes na Sheria ya Kuelea'),
      SyllabusTopic(en: 'Structure and Properties of Matter', sw: 'Muundo na Sifa za Mata'),
      SyllabusTopic(en: 'Pressure', sw: 'Shinikizo'),
      SyllabusTopic(en: 'Work, Energy, and Power', sw: 'Kazi, Nishati, na Nguvu'),
    ],
    2: [
      SyllabusTopic(en: 'Static Electricity', sw: 'Umeme Tuli'),
      SyllabusTopic(en: 'Current Electricity', sw: 'Umeme Mwendo'),
      SyllabusTopic(en: 'Magnetism', sw: 'Usumaku'),
      SyllabusTopic(en: 'Forces in Equilibrium', sw: 'Nguvu katika Msawazo'),
      SyllabusTopic(en: 'Simple Machines', sw: 'Mashine Sahili'),
      SyllabusTopic(en: 'Motion in a Straight Line', sw: 'Mwendo katika Mstari Mnyooka'),
      SyllabusTopic(en: "Newton's Laws of Motion", sw: 'Sheria za Newton za Mwendo'),
      SyllabusTopic(en: 'Temperature', sw: 'Halijoto'),
      SyllabusTopic(en: 'Sustainable Energy Sources', sw: 'Vyanzo Endelevu vya Nishati'),
    ],
    3: [
      SyllabusTopic(en: 'Application of Vectors', sw: 'Matumizi ya Vekta'),
      SyllabusTopic(en: 'Friction', sw: 'Msuguano'),
      SyllabusTopic(en: 'Light', sw: 'Mwanga'),
      SyllabusTopic(en: 'Optical Instruments', sw: 'Vifaa vya Macho'),
      SyllabusTopic(en: 'Thermal Expansion', sw: 'Mpanuko wa Joto'),
      SyllabusTopic(en: 'Transfer of Thermal Energy', sw: 'Uhamisho wa Nishati ya Joto'),
      SyllabusTopic(en: 'Measurement of Thermal Energy', sw: 'Vipimo vya Nishati ya Joto'),
      SyllabusTopic(en: 'Vapour and Humidity', sw: 'Mvuke na Unyevunyevu'),
      SyllabusTopic(en: 'Current Electricity', sw: 'Umeme Mwendo (Hali ya Juu)'),
    ],
    4: [
      SyllabusTopic(en: 'Waves', sw: 'Mawimbi'),
      SyllabusTopic(en: 'Electromagnetism', sw: 'Usumaku-Umeme'),
      SyllabusTopic(en: 'Radioactivity', sw: 'Mionzi (Radioactivity)'),
      SyllabusTopic(en: 'Thermionic Emission', sw: 'Utoaji wa Thermionic'),
      SyllabusTopic(en: 'Electronics', sw: 'Elektroniki'),
      SyllabusTopic(en: 'Elementary Astronomy', sw: 'Astronomia ya Msingi'),
      SyllabusTopic(en: 'Geophysics', sw: 'Fizikia ya Dunia (Geophysics)'),
    ],
  },
  'chemistry': {
    1: [
      SyllabusTopic(en: 'Introduction to Chemistry', sw: 'Utangulizi wa Kemia'),
      SyllabusTopic(en: 'Laboratory Practice and Safety', sw: 'Mazoezi na Usalama wa Maabara'),
      SyllabusTopic(en: 'Heat Sources and Flames', sw: 'Vyanzo vya Moto na Moto'),
      SyllabusTopic(en: 'The Scientific Procedure', sw: 'Njia ya Kisayansi'),
      SyllabusTopic(en: 'Matter', sw: 'Mata'),
      SyllabusTopic(en: 'Air, Combustion, Rusting, and Fire Fighting', sw: 'Hewa, Uteketezaji, Kutu, na Kuzima Moto'),
    ],
    2: [
      SyllabusTopic(en: 'Oxygen', sw: 'Oksijeni'),
      SyllabusTopic(en: 'Hydrogen', sw: 'Hidrojeni'),
      SyllabusTopic(en: 'Water', sw: 'Maji'),
      SyllabusTopic(en: 'Fuels and Energy', sw: 'Mafuta na Nishati'),
      SyllabusTopic(en: 'Atomic Structure', sw: 'Muundo wa Atomu'),
      SyllabusTopic(en: 'Periodic Classification', sw: 'Mviringo wa Upimaji wa Elementi'),
      SyllabusTopic(en: 'Formula, Bonding, and Nomenclature', sw: 'Fomula, Muunganisho, na Majina ya Kemikali'),
    ],
    3: [
      SyllabusTopic(en: 'Chemical Equations', sw: 'Milinganyo ya Kemikali'),
      SyllabusTopic(en: 'Hardness of Water', sw: 'Ugumu wa Maji'),
      SyllabusTopic(en: 'Acids, Bases, and Salts', sw: 'Asidi, Besi, na Chumvi'),
      SyllabusTopic(en: 'The Mole Concept and Related Calculations', sw: 'Dhana ya Mole na Mahesabu yake'),
      SyllabusTopic(en: 'Volumetric Analysis', sw: 'Uchambuzi wa Kiasi (Titration)'),
      SyllabusTopic(en: 'Ionic Theory and Electrolysis', sw: 'Nadharia ya Ioni na Elektrolisisi'),
      SyllabusTopic(en: 'Extraction of Metals', sw: 'Uchimbaji wa Metali'),
      SyllabusTopic(en: 'Compounds of Metals', sw: 'Misombo ya Metali'),
    ],
    4: [
      SyllabusTopic(en: 'Non-metals and Their Compounds', sw: 'Zisizo za Metali na Misombo Yake'),
      SyllabusTopic(en: 'Introduction to Organic Chemistry', sw: 'Utangulizi wa Kemia Kikaboni'),
      SyllabusTopic(en: 'Soil Chemistry', sw: 'Kemia ya Udongo'),
      SyllabusTopic(en: 'Pollution', sw: 'Uchafuzi wa Mazingira'),
      SyllabusTopic(en: 'Qualitative Analysis', sw: 'Uchambuzi wa Ubora'),
    ],
  },
  'biology': {
    1: [
      SyllabusTopic(en: 'Introduction to Biology', sw: 'Utangulizi wa Biolojia'),
      SyllabusTopic(en: 'Safety in Our Environment', sw: 'Usalama katika Mazingira Yetu'),
      SyllabusTopic(en: 'Health and Hygiene', sw: 'Afya na Usafi'),
      SyllabusTopic(en: 'Cell Structure and Organization', sw: 'Muundo na Uratibu wa Seli'),
      SyllabusTopic(en: 'Classification of Living Things', sw: 'Uainishaji wa Viumbe Hai'),
    ],
    2: [
      SyllabusTopic(en: 'Classification of Living Things', sw: 'Uainishaji wa Viumbe Hai'),
      SyllabusTopic(en: 'Nutrition', sw: 'Lishe'),
      SyllabusTopic(en: 'Balance of Nature', sw: 'Ulinganifu wa Asili'),
      SyllabusTopic(en: 'Transportation of Materials in Living Things', sw: 'Usafirishaji wa Nyenzo kwenye Viumbe Hai'),
      SyllabusTopic(en: 'Gaseous Exchange and Respiration', sw: 'Kubadilishana Hewa na Upumuaji'),
    ],
    3: [
      SyllabusTopic(en: 'Classification of Living Things', sw: 'Uainishaji wa Viumbe Hai'),
      SyllabusTopic(en: 'Movement and Locomotion', sw: 'Mwendo na Uhamaji'),
      SyllabusTopic(en: 'Coordination', sw: 'Uratibu (Coordination)'),
      SyllabusTopic(en: 'Excretion', sw: 'Uondoaji Taka (Excretion)'),
      SyllabusTopic(en: 'Regulation (Homeostasis)', sw: 'Udhibiti (Homeostasis)'),
      SyllabusTopic(en: 'Reproduction', sw: 'Uzazi'),
    ],
    4: [
      SyllabusTopic(en: 'Growth in Plants and Animals', sw: 'Ukuaji katika Mimea na Wanyama'),
      SyllabusTopic(en: 'Genetics', sw: 'Jenetiki'),
      SyllabusTopic(en: 'Classification of Living Things', sw: 'Uainishaji wa Viumbe Hai'),
      SyllabusTopic(en: 'Evolution', sw: 'Mabadiliko ya Viumbe (Evolution)'),
      SyllabusTopic(en: 'HIV/AIDS and Other STIs', sw: 'VVU/UKIMWI na Magonjwa ya Zinaa'),
    ],
  },
  'geography': {
    1: [
      SyllabusTopic(en: 'Concept of Geography', sw: 'Dhana ya Jiografia'),
      SyllabusTopic(en: 'The Solar System', sw: 'Mfumo wa Jua'),
      SyllabusTopic(en: 'Structure of the Earth', sw: 'Muundo wa Dunia'),
      SyllabusTopic(en: "Major Features of the Earth's Surface", sw: 'Sifa Kuu za Uso wa Dunia'),
      SyllabusTopic(en: 'Weather', sw: 'Hali ya Hewa'),
      SyllabusTopic(en: 'Climate', sw: 'Tabianchi'),
      SyllabusTopic(en: 'Map Work', sw: 'Kazi za Ramani'),
    ],
    2: [
      SyllabusTopic(en: 'Agriculture', sw: 'Kilimo'),
      SyllabusTopic(en: 'Livestock keeping', sw: 'Ufugaji wa Wanyama'),
      SyllabusTopic(en: 'Water management for economic development', sw: 'Usimamizi wa Maji kwa Maendeleo ya Uchumi'),
      SyllabusTopic(en: 'Exploitation of forest resources', sw: 'Matumizi ya Rasilimali za Misitu'),
      SyllabusTopic(en: 'Mining industry', sw: 'Viwanda vya Madini'),
      SyllabusTopic(en: 'Tourism', sw: 'Utalii'),
      SyllabusTopic(en: 'Manufacturing industry', sw: 'Viwanda vya Uzalishaji'),
      SyllabusTopic(en: 'Power and Energy resources', sw: 'Rasilimali za Nguvu na Nishati'),
      SyllabusTopic(en: 'Transport', sw: 'Usafirishaji'),
    ],
    3: [
      SyllabusTopic(en: 'Structure of the Earth', sw: 'Muundo wa Dunia'),
      SyllabusTopic(en: 'Forces that affect the earth structure', sw: 'Nguvu Zinazoathiri Muundo wa Dunia'),
      SyllabusTopic(en: 'Soil', sw: 'Udongo'),
      SyllabusTopic(en: 'Elementary Surveying and Research', sw: 'Utafiti na Upimaji wa Msingi'),
      SyllabusTopic(en: 'Map Reading and Interpretation', sw: 'Usomaji na Utafsiri wa Ramani'),
      SyllabusTopic(en: 'Photograph Interpretation', sw: 'Utafsiri wa Picha'),
    ],
    4: [
      SyllabusTopic(en: 'Human population', sw: 'Idadi ya Watu'),
      SyllabusTopic(en: 'Settlement', sw: 'Makazi'),
      SyllabusTopic(en: 'Environmental issues and management', sw: 'Masuala ya Mazingira na Usimamizi wake'),
      SyllabusTopic(en: 'Sustainable use of resources', sw: 'Matumizi Endelevu ya Rasilimali'),
      SyllabusTopic(en: 'Regional focal studies', sw: 'Masomo Maalum ya Kanda'),
      SyllabusTopic(en: 'Climate and natural vegetation', sw: 'Tabianchi na Uoto wa Asili'),
    ],
  },
  'history': {
    1: [
      SyllabusTopic(en: 'Meaning and importance of History', sw: 'Maana na Umuhimu wa Historia'),
      SyllabusTopic(en: 'Sources of historical information', sw: 'Vyanzo vya Habari za Kihistoria'),
      SyllabusTopic(en: 'Theories of the origin of human beings', sw: 'Nadharia za Chimbuko la Mwanadamu'),
      SyllabusTopic(en: 'Stages of human evolution', sw: 'Hatua za Mageuzi ya Mwanadamu'),
      SyllabusTopic(en: 'Pre-colonial African societies', sw: 'Jamii za Afrika Kabla ya Ukoloni'),
      SyllabusTopic(en: 'Development of social and political systems', sw: 'Ukuaji wa Mifumo ya Kijamii na Kisiasa'),
    ],
    2: [
      SyllabusTopic(en: 'Early external contacts', sw: 'Mawasiliano ya Awali ya Nje'),
      SyllabusTopic(en: 'The slave trade in East Africa', sw: 'Biashara ya Watumwa Afrika Mashariki'),
      SyllabusTopic(en: 'Establishment of colonial rule', sw: 'Kuanzishwa kwa Utawala wa Kikoloni'),
      SyllabusTopic(en: 'Colonial administrative systems', sw: 'Mifumo ya Utawala wa Kikoloni'),
      SyllabusTopic(en: 'Colonial economy', sw: 'Uchumi wa Kikoloni'),
    ],
    3: [
      SyllabusTopic(en: 'Colonial economy', sw: 'Uchumi wa Kikoloni'),
      SyllabusTopic(en: 'Colonial social services', sw: 'Huduma za Kijamii za Kikoloni'),
      SyllabusTopic(en: 'Crisis in the world capitalist system', sw: 'Mgogoro wa Mfumo wa Kibepari Duniani'),
      SyllabusTopic(en: 'Nationalism and decolonization', sw: 'Utaifa na Ukombozi'),
      SyllabusTopic(en: 'Influence of external forces on decolonization', sw: 'Ushawishi wa Nguvu za Nje kwenye Ukombozi'),
    ],
    4: [
      SyllabusTopic(en: 'Nationalism and decolonization', sw: 'Utaifa na Ukombozi'),
      SyllabusTopic(en: 'Changes after independence', sw: 'Mabadiliko Baada ya Uhuru'),
      SyllabusTopic(en: 'Poverty and development', sw: 'Umaskini na Maendeleo'),
      SyllabusTopic(en: 'Africa in international affairs', sw: 'Afrika katika Masuala ya Kimataifa'),
      SyllabusTopic(en: 'Globalization', sw: 'Utandawazi'),
    ],
  },
  'civics': {
    1: [
      SyllabusTopic(en: 'Our Nation', sw: 'Taifa Letu'),
      SyllabusTopic(en: 'Promotion of life skills', sw: 'Kukuza Stadi za Maisha'),
      SyllabusTopic(en: 'Responsible citizenship', sw: 'Uraia Wajibikaji'),
      SyllabusTopic(en: 'Human rights', sw: 'Haki za Binadamu'),
      SyllabusTopic(en: 'Gender', sw: 'Jinsia'),
    ],
    2: [
      SyllabusTopic(en: 'Family', sw: 'Familia'),
      SyllabusTopic(en: 'Road safety education', sw: 'Elimu ya Usalama Barabarani'),
      SyllabusTopic(en: 'Work', sw: 'Kazi'),
      SyllabusTopic(en: 'Democracy', sw: 'Demokrasia'),
      SyllabusTopic(en: 'Government of Tanzania', sw: 'Serikali ya Tanzania'),
    ],
    3: [
      SyllabusTopic(en: 'Our Culture', sw: 'Utamaduni Wetu'),
      SyllabusTopic(en: 'Poverty', sw: 'Umaskini'),
      SyllabusTopic(en: 'Globalization', sw: 'Utandawazi'),
      SyllabusTopic(en: 'Economic and social development', sw: 'Maendeleo ya Kiuchumi na Kijamii'),
      SyllabusTopic(en: 'Social problems', sw: 'Changamoto za Kijamii'),
    ],
    4: [
      SyllabusTopic(en: 'Government of Tanzania', sw: 'Serikali ya Tanzania'),
      SyllabusTopic(en: 'Democratic process', sw: 'Mchakato wa Kidemokrasia'),
      SyllabusTopic(en: 'Human rights', sw: 'Haki za Binadamu'),
      SyllabusTopic(en: 'International cooperation', sw: 'Ushirikiano wa Kimataifa'),
    ],
  },
  'english': {
    1: [
      SyllabusTopic(en: 'Listening and Understanding', sw: 'Kusikiliza na Kuelewa'),
      SyllabusTopic(en: 'Speaking', sw: 'Kuzungumza'),
      SyllabusTopic(en: 'Reading', sw: 'Kusoma'),
      SyllabusTopic(en: 'Writing', sw: 'Kuandika'),
    ],
    2: [
      SyllabusTopic(en: 'Listening and Understanding', sw: 'Kusikiliza na Kuelewa'),
      SyllabusTopic(en: 'Speaking', sw: 'Kuzungumza'),
      SyllabusTopic(en: 'Reading', sw: 'Kusoma'),
      SyllabusTopic(en: 'Writing', sw: 'Kuandika'),
    ],
    3: [
      SyllabusTopic(en: 'Listening and Understanding', sw: 'Kusikiliza na Kuelewa'),
      SyllabusTopic(en: 'Speaking', sw: 'Kuzungumza'),
      SyllabusTopic(en: 'Reading', sw: 'Kusoma'),
      SyllabusTopic(en: 'Writing', sw: 'Kuandika'),
    ],
    4: [
      SyllabusTopic(en: 'Listening and Understanding', sw: 'Kusikiliza na Kuelewa'),
      SyllabusTopic(en: 'Speaking', sw: 'Kuzungumza'),
      SyllabusTopic(en: 'Reading', sw: 'Kusoma'),
      SyllabusTopic(en: 'Writing', sw: 'Kuandika'),
    ],
  },
  'kiswahili': {
    1: [
      SyllabusTopic(en: 'Lugha na Mawasiliano', sw: 'Lugha na Mawasiliano'),
      SyllabusTopic(en: 'Sarufi na Uainishaji wa Maneno', sw: 'Sarufi na Uainishaji wa Maneno'),
      SyllabusTopic(en: 'Fasihi Simulizi na Tanzu Zake', sw: 'Fasihi Simulizi na Tanzu Zake'),
      SyllabusTopic(en: 'Uandishi na Utungaji wa Barua na Insha', sw: 'Uandishi na Utungaji wa Barua na Insha'),
      SyllabusTopic(en: 'Historia ya Kiswahili na Chimbuko Lake', sw: 'Historia ya Kiswahili na Chimbuko Lake'),
    ],
    2: [
      SyllabusTopic(en: 'Matumizi ya Lugha na Vipasho Vyake', sw: 'Matumizi ya Lugha na Vipasho Vyake'),
      SyllabusTopic(en: 'Sarufi na Viambishi vya Maneno', sw: 'Sarufi na Viambishi vya Maneno'),
      SyllabusTopic(en: 'Fasihi simulizi (Hadithi na Semi)', sw: 'Fasihi simulizi (Hadithi na Semi)'),
      SyllabusTopic(en: 'Uandishi wa Kazi za Kiofisi na Kumbukumbu', sw: 'Uandishi wa Kazi za Kiofisi na Kumbukumbu'),
      SyllabusTopic(en: 'Ukuaji na Ueneaji wa Kiswahili Enzi ya Wajerumani na Waarabu', sw: 'Ukuaji na Ueneaji wa Kiswahili Enzi ya Wajerumani na Waarabu'),
    ],
    3: [
      SyllabusTopic(en: 'Sarufi (Nyakati, Hali na Mnyambuliko wa Vitenzi)', sw: 'Sarufi (Nyakati, Hali na Mnyambuliko wa Vitenzi)'),
      SyllabusTopic(en: 'Uandishi (Insha za Jadili na Hoja)', sw: 'Uandishi (Insha za Jadili na Hoja)'),
      SyllabusTopic(en: 'Fasihi Andishi (Riwaya na Tamthiliya)', sw: 'Fasihi Andishi (Riwaya na Tamthiliya)'),
      SyllabusTopic(en: 'Uchambuzi wa Ushairi wa Kiswahili', sw: 'Uchambuzi wa Ushairi wa Kiswahili'),
      SyllabusTopic(en: 'Kiswahili kama Lugha ya Taifa na Kimataifa', sw: 'Kiswahili kama Lugha ya Taifa na Kimataifa'),
    ],
    4: [
      SyllabusTopic(en: 'Sarufi (Upambanuzi wa Sentensi na Muundo wa Virai)', sw: 'Sarufi (Upambanuzi wa Sentensi na Muundo wa Virai)'),
      SyllabusTopic(en: 'Uandishi (Ripoti, CV na Hotuba)', sw: 'Uandishi (Ripoti, CV na Hotuba)'),
      SyllabusTopic(en: 'Uchambuzi wa Vitabu Maalum vya Fasihi', sw: 'Uchambuzi wa Vitabu Maalum vya Fasihi'),
      SyllabusTopic(en: 'Kiswahili na Maendeleo ya Sayansi na Teknolojia', sw: 'Kiswahili na Maendeleo ya Sayansi na Teknolojia'),
      SyllabusTopic(en: 'Mbinu za Mawasiliano Rasmi na Mikutano', sw: 'Mbinu za Mawasiliano Rasmi na Mikutano'),
    ],
  },
};
