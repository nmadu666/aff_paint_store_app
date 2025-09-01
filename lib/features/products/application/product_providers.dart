import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

/// Provider cho Repository
///
/// Provider này tạo ra một instance của FirebaseProductRepository.
/// Chúng ta sử dụng `Provider` thay vì tạo instance trực tiếp trong UI
/// để có thể dễ dàng thay thế bằng một implementation giả (mock) khi viết test.
final productRepositoryProvider = Provider<IProductRepository>((ref) {
  return FirebaseProductRepository();
});

/// Định nghĩa một kiểu dữ liệu cho bộ lọc để code dễ đọc hơn.
/// Đây là một Dart Record, cho phép nhóm nhiều giá trị lại với nhau.
typedef ProductFilter = ({String? categoryId, String? trademarkId});

/// Provider để lấy dữ liệu sản phẩm có lọc
///
/// Chúng ta sử dụng `FutureProvider.family` để có thể truyền tham số (bộ lọc) vào.
/// Riverpod sẽ tự động cache kết quả dựa trên giá trị của bộ lọc.
final productsProvider = FutureProvider.family<List<Product>, ProductFilter>((
  ref,
  filter,
) async {
  // Lấy instance của repository từ provider đã định nghĩa ở trên.
  final productRepository = ref.watch(productRepositoryProvider);

  // Gọi phương thức getProducts với các bộ lọc được truyền vào.
  return productRepository.getProducts(
    categoryId: filter.categoryId,
    trademarkId: filter.trademarkId,
  );
});
