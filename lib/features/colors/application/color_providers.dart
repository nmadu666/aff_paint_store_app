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
final colorsByIdsProvider = FutureProvider.autoDispose.family<List<ColorData>, List<String>>((
  ref,
  colorIds,
) async {
  // Nếu danh sách ID rỗng, trả về danh sách rỗng ngay lập tức để tránh gọi API không cần thiết.
  if (colorIds.isEmpty) {
    return [];
  }
  final repository = ref.watch(colorRepositoryProvider);
  final colors = await repository.getColorsByIds(colorIds);

  // Sắp xếp các màu theo độ sáng để có giao diện đẹp mắt hơn.
  // Việc sắp xếp ở đây đảm bảo nó chỉ chạy một lần khi dữ liệu được fetch.
  colors.sort((a, b) => (b.lightness ?? 0).compareTo(a.lightness ?? 0));
  return colors;
});

/// Một record để nhóm các tham số cho provider lấy danh sách gốc sơn.
typedef AvailableBasesFilter = ({
  String colorId,
  String colorMixingProductType
});

/// Provider để lấy danh sách các loại gốc sơn ('A', 'B', 'C'...) có sẵn
/// cho một màu và một loại sản phẩm pha màu cụ thể.
///
/// **Lưu ý:** Cần thêm phương thức `getAvailableBasesForColor` vào `IColorRepository`
/// và `FirebaseColorRepository` để provider này hoạt động.
final availableBasesProvider =
    FutureProvider.autoDispose.family<List<String>, AvailableBasesFilter>((ref, filter) async {
  final repository = ref.watch(colorRepositoryProvider);
  // Giả định phương thức này tồn tại trong repository của bạn.
  return repository.getAvailableBasesForColor(
    colorId: filter.colorId,
    colorMixingProductType: filter.colorMixingProductType,
  );
});
// Có thể thêm các provider khác liên quan đến màu sắc ở đây trong tương lai.
