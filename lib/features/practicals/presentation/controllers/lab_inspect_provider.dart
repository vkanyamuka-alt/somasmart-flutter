import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The apparatus the student last tapped on a practical's inspect step, so
/// the bench can show that instrument as active. Keyed by practical name for
/// benches whose state keeps only a per-item `inspected` flag.
final labInspectedProvider =
    StateProvider.autoDispose.family<String?, String>((ref, practical) => null);
