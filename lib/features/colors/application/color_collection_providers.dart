import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/color_collection_model.dart';
import '../../../data/repositories/color_collection_repository.dart';

/// Provider cho Repository của ColorCollection.
///
/// Tương tự như productRepositoryProvider, việc này giúp cho việc testing
/// và quản lý dependency dễ dàng hơn.
final colorCollectionRepositoryProvider = Provider<IColorCollectionRepository>((
  ref,
) {
  return FirebaseColorCollectionRepository();
});

/// Provider để lấy danh sách các bộ sưu tập màu, có thể lọc theo thương hiệu.
///
/// Sử dụng `FutureProvider.family` để có thể truyền vào `trademarkId`.
/// Riverpod sẽ cache kết quả dựa trên `trademarkId`. Nếu `trademarkId` là null,
/// nó sẽ lấy tất cả các bộ sưu tập.
final colorCollectionsProvider =
    FutureProvider.autoDispose.family<List<ColorCollection>, String?>((
      ref,
      trademarkId,
    ) async {
      final repository = ref.watch(colorCollectionRepositoryProvider);
      return repository.getColorCollections(trademarkId: trademarkId);
    });
