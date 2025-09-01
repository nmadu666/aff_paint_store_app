import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

/// Lớp trừu tượng định nghĩa các phương thức cần có để lấy dữ liệu sản phẩm.
abstract class IProductRepository {
  /// Lấy danh sách sản phẩm, có thể lọc theo categoryId và trademarkId.
  ///
  /// Nếu không có bộ lọc nào được cung cấp, nó sẽ trả về tất cả sản phẩm.
  Future<List<Product>> getProducts({String? categoryId, String? trademarkId});
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

    // Bước 2: Lấy danh sách các ĐƯỜNG DẪN (String) của sản phẩm cha.
    // *** SỬA LỖI QUAN TRỌNG: So sánh chuỗi đường dẫn thay vì đối tượng DocumentReference ***
    final parentRefPaths = parentSnapshot.docs
        .map((doc) => doc.reference.path)
        .toList();

    // Bước 3: Truy vấn collection `products` bằng `whereIn`.
    // Xử lý giới hạn 30 mục của `whereIn` bằng cách chia thành các lô.
    print('📦 [ProductRepo] Bước 2: Chuẩn bị truy vấn sản phẩm con...');
    final List<Product> allProducts = [];
    const chunkSize = 30;

    // Chia danh sách parentRefs thành các lô nhỏ hơn.
    final List<List<String>> chunks = [];
    for (var i = 0; i < parentRefPaths.length; i += chunkSize) {
      chunks.add(
        parentRefPaths.sublist(
          i,
          i + chunkSize > parentRefPaths.length
              ? parentRefPaths.length
              : i + chunkSize,
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
}

/// Ghi chú về tối ưu hóa:
/// Mặc dù cách tiếp cận trên hoạt động tốt với cấu trúc dữ liệu hiện tại,
/// một cách tối ưu hơn trong tương lai là "phi chuẩn hóa" (denormalize) dữ liệu.
/// Bằng cách thêm trực tiếp các trường `categoryId` và `trademarkId` vào mỗi
/// document trong collection `products`, bạn có thể thực hiện lọc chỉ với một
/// truy vấn duy nhất, hiệu quả và đơn giản hơn rất nhiều.
