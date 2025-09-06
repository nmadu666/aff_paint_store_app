import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/color_data_model.dart';
import '../../../data/repositories/color_repository.dart';

/// Provider cho Repository của Color.
final colorRepositoryProvider = Provider<IColorRepository>((ref) {
  return FirebaseColorRepository();
});

/// Provider để lấy danh sách các đối tượng ColorData từ một danh sách các ID.
///
/// Sử dụng `FutureProvider.family` để có thể truyền vào một danh sách `colorIds`.
/// Riverpod sẽ cache kết quả dựa trên danh sách ID này.
final colorsByIdsProvider = FutureProvider.family<List<ColorData>, List<String>>((
  ref,
  colorIds,
) async {
  // Nếu danh sách ID rỗng, trả về danh sách rỗng ngay lập tức để tránh gọi API không cần thiết.
  if (colorIds.isEmpty) {
    return [];
  }
  final repository = ref.watch(colorRepositoryProvider);
  return repository.getColorsByIds(colorIds);
});

// Có thể thêm các provider khác liên quan đến màu sắc ở đây trong tương lai.
