import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/category_model.dart';
import '../../../data/models/trademark_model.dart';
import '../../../data/repositories/filter_repository.dart';

/// Provider cho FilterRepository.
final filterRepositoryProvider = Provider<IFilterRepository>((ref) {
  return FirebaseFilterRepository();
});

/// Provider để lấy danh sách tất cả các danh mục.
/// `.autoDispose` giúp tự động dọn dẹp state khi không còn được sử dụng.
final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final repository = ref.watch(filterRepositoryProvider);
  return repository.getCategories();
});

/// Provider để lấy danh sách tất cả các thương hiệu.
final trademarksProvider = FutureProvider.autoDispose<List<Trademark>>((ref) async {
  final repository = ref.watch(filterRepositoryProvider);
  return repository.getTrademarks();
});

