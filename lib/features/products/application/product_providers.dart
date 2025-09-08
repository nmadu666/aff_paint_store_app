import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/color_data_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/parent_product_model.dart';
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

/// Provider để lấy danh sách các ParentProduct tương thích với một màu đã chọn.
///
/// Sử dụng `FutureProvider.family` để truyền vào đối tượng `ColorData`.
/// Riverpod sẽ cache kết quả dựa trên giá trị của đối tượng màu (nhờ Equatable).
/// `.autoDispose` sẽ tự động hủy trạng thái khi không còn được sử dụng.
final compatibleParentProductsProvider =
    FutureProvider.autoDispose.family<List<ParentProduct>, ColorData>((
  ref,
  color,
) async {
  // Lấy instance của repository từ provider đã định nghĩa ở trên.
  final productRepository = ref.watch(productRepositoryProvider);
  return productRepository.getCompatibleParentProducts(color);
});

/// Provider để lấy tất cả các SKU (sản phẩm con) cho một `ParentProduct` ID.
///
/// Sử dụng `.family` để truyền vào `parentProductId`.
/// Riverpod sẽ cache kết quả dựa trên ID này.
final skusForParentProvider =
    FutureProvider.autoDispose.family<List<Product>, String>((ref, parentProductId) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getSkusForParent(parentProductId);
});
