import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/color_collection_model.dart';
import 'color_providers.dart';

/// Provider to fetch color collections, optionally filtered by trademark.
final colorCollectionsProvider =
    FutureProvider.autoDispose.family<List<ColorCollection>, String?>((ref, trademarkId) {
  final colorRepository = ref.watch(colorRepositoryProvider);
  return colorRepository.getColorCollections(trademarkId: trademarkId);
});