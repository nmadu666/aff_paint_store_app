import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/color_data_model.dart';
import '../models/parent_product_model.dart';
import '../models/product_model.dart';

/// Lớp trừu tượng định nghĩa các phương thức cần có để lấy dữ liệu sản phẩm.
abstract class IProductRepository {
  /// Lấy danh sách sản phẩm, có thể lọc theo categoryId và trademarkId.
  ///
  /// Nếu không có bộ lọc nào được cung cấp, nó sẽ trả về tất cả sản phẩm.
  Future<List<Product>> getProducts({String? categoryId, String? trademarkId});

  /// Lấy danh sách các ParentProduct phù hợp với một màu cụ thể.
  Future<List<ParentProduct>> getCompatibleParentProducts(ColorData color);

  /// Lấy danh sách các SKU (Product) thuộc về một ParentProduct.
  Future<List<Product>> getSkusForParent(String parentProductId);
}

/// Triển khai repository sử dụng Firebase Firestore.
class FirebaseProductRepository implements IProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Product>> getProducts({
    String? categoryId,
    String? trademarkId,
  }) async {
    // Log để kiểm tra các bộ lọc đầu vào
    print(
      '🔍 [ProductRepo] Bắt đầu lấy sản phẩm với bộ lọc: categoryId=$categoryId, trademarkId=$trademarkId',
    );

    // Nếu không có bộ lọc, lấy tất cả sản phẩm một cách hiệu quả.
    if (categoryId == null && trademarkId == null) {
      final snapshot = await _firestore.collection('products').get();
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
      print(
        '✅ [ProductRepo] Không có bộ lọc. Lấy được ${products.length} sản phẩm.',
      );
      return products;
    }

    // Bước 1: Xây dựng và thực thi truy vấn trên `parent_products`.
    print('📄 [ProductRepo] Bước 1: Truy vấn collection "parent_products"...');
    Query parentQuery = _firestore.collection('parent_products');

    if (categoryId != null) {
      // Giả định categoryId là một string khớp với trường 'category'
      parentQuery = parentQuery.where('category', isEqualTo: categoryId);
    }
    if (trademarkId != null) {
      parentQuery = parentQuery.where('trademark_ref', isEqualTo: trademarkId);
    }

    final parentSnapshot = await parentQuery.get();
    print(
      '📄 [ProductRepo] Bước 1: Tìm thấy ${parentSnapshot.docs.length} sản phẩm cha phù hợp.',
    );

    if (parentSnapshot.docs.isEmpty) {
      return []; // Không có sản phẩm cha nào khớp, trả về danh sách rỗng.
    }

    // Bước 2: Lấy danh sách các DocumentReference của sản phẩm cha.
    final parentRefs = parentSnapshot.docs.map((doc) => doc.reference).toList();

    // Bước 3: Truy vấn collection `products` bằng `whereIn`.
    // Xử lý giới hạn 30 mục của `whereIn` bằng cách chia thành các lô.
    print('📦 [ProductRepo] Bước 2: Chuẩn bị truy vấn sản phẩm con...');
    final List<Product> allProducts = [];
    const chunkSize =
        30; // Firestore 'in' and 'array-contains-any' queries are limited to 30 items.

    // Chia danh sách parentRefs thành các lô nhỏ hơn.
    final List<List<DocumentReference>> chunks = [];
    for (var i = 0; i < parentRefs.length; i += chunkSize) {
      chunks.add(
        parentRefs.sublist(
          i,
          i + chunkSize > parentRefs.length ? parentRefs.length : i + chunkSize,
        ),
      );
    }

    // Thực hiện các truy vấn song song cho từng lô.
    final futures = chunks.map(
      (chunk) => _firestore
          .collection('products')
          .where('parent_product_ref', whereIn: chunk)
          .get(),
    );

    final snapshots = await Future.wait(futures);

    // Gộp kết quả từ tất cả các truy vấn.
    for (final snapshot in snapshots) {
      allProducts.addAll(
        snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
      );
    }

    print(
      '✅ [ProductRepo] Bước 3: Hoàn tất. Tổng số sản phẩm lấy được: ${allProducts.length}.',
    );
    return allProducts;
  }

  @override
  Future<List<ParentProduct>> getCompatibleParentProducts(
    ColorData color,
  ) async {
    // 1. Lấy tất cả các `colorMixingProductType` có sẵn cho màu này
    //    từ sub-collection 'color_pricings'.
    print(
      '🔍 [ProductRepo] Lấy các loại sản phẩm tương thích cho màu: ${color.name} (ID: ${color.id})',
    );
    final pricingSnapshot = await _firestore
        .collection('colors')
        .doc(color.id)
        .collection('color_pricings')
        .get();

    if (pricingSnapshot.docs.isEmpty) {
      print(
        'ℹ️ [ProductRepo] Không tìm thấy thông tin giá (pricing) cho màu ${color.id}. Sẽ không có sản phẩm tương thích.',
      );
      return [];
    }

    // Lấy danh sách các product type duy nhất.
    final availableProductTypes = pricingSnapshot.docs
        .map((doc) => doc.data()['color_mixing_product_type'] as String?)
        .where((type) => type != null && type.isNotEmpty)
        .toSet() // toSet để loại bỏ các giá trị trùng lặp
        .toList();

    if (availableProductTypes.isEmpty) {
      print(
        'ℹ️ [ProductRepo] Không có "color_mixing_product_type" hợp lệ trong thông tin giá của màu ${color.id}.',
      );
      return [];
    }
    print(
      '📄 [ProductRepo] Các loại sản phẩm tìm thấy cho màu: $availableProductTypes',
    );

    // 2. Truy vấn `parent_products`
    //    - Lọc theo `trademarkRef` của màu.
    //    - Lọc theo danh sách `colorMixingProductType` tìm được.
    //    Firestore `whereIn` giới hạn 30 phần tử, nhưng số lượng product types cho một màu
    //    thường rất nhỏ nên không cần chia nhỏ (chunking) ở đây.
    print(
      '📦 [ProductRepo] Truy vấn "parent_products" với trademarkRef=${color.trademarkRef} và productTypes=$availableProductTypes',
    );
    final parentProductsQuery = _firestore
        .collection('parent_products')
        .where('trademark_ref', isEqualTo: color.trademarkRef)
        .where('color_mixing_product_type', whereIn: availableProductTypes);

    final parentProductsSnapshot = await parentProductsQuery.get();

    final results = parentProductsSnapshot.docs
        .map((doc) => ParentProduct.fromFirestore(doc))
        .toList();

    print(
      '✅ [ProductRepo] Tìm thấy ${results.length} ParentProduct tương thích.',
    );
    return results;
  }

  @override
  Future<List<Product>> getSkusForParent(String parentProductId) async {
    print(
      '📦 [ProductRepo] Lấy các SKU cho ParentProduct ID: $parentProductId',
    );
    // Tạo một DocumentReference đến sản phẩm cha.
    // Truy vấn bằng DocumentReference là cách chính xác và an toàn nhất.
    final parentDocRef = _firestore
        .collection('parent_products')
        .doc(parentProductId);

    final snapshot = await _firestore
        .collection('products')
        .where('parent_product_ref', isEqualTo: parentDocRef)
        .get();

    final skus = snapshot.docs
        .map((doc) => Product.fromFirestore(doc))
        .toList();
    // Sắp xếp các SKU theo dung tích để hiển thị một cách hợp lý.
    skus.sort((a, b) => (a.unitValue ?? 0).compareTo(b.unitValue ?? 0));
    print('✅ [ProductRepo] Tìm thấy ${skus.length} SKU.');
    return skus;
  }
}

/// Ghi chú về tối ưu hóa:
/// Mặc dù cách tiếp cận trên hoạt động tốt với cấu trúc dữ liệu hiện tại,
/// một cách tối ưu hơn trong tương lai là "phi chuẩn hóa" (denormalize) dữ liệu.
/// Bằng cách thêm trực tiếp các trường `categoryId` và `trademarkId` vào mỗi
/// document trong collection `products`, bạn có thể thực hiện lọc chỉ với một
/// truy vấn duy nhất, hiệu quả và đơn giản hơn rất nhiều.
