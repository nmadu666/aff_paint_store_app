import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/color_data_model.dart';
import '../models/parent_product_model.dart';
import '../models/product_model.dart';

/// Lớp chứa kết quả của một trang dữ liệu sản phẩm.
class ProductPage {
  final List<Product> products;
  final DocumentSnapshot? lastDoc; // Document cuối cùng để làm con trỏ cho trang tiếp theo.
  final bool hasMore; // Cho biết có còn trang để tải hay không.

  const ProductPage({
    required this.products,
    this.lastDoc,
    required this.hasMore,
  });
}

/// Lớp trừu tượng định nghĩa các phương thức cần có để lấy dữ liệu sản phẩm.
abstract class IProductRepository {
  /// Lấy danh sách sản phẩm, có thể lọc theo categoryId và trademarkId.
  /// Có thể tìm kiếm theo `searchTerm` trên tên và mã sản phẩm.
  /// Nếu không có bộ lọc nào được cung cấp, nó sẽ trả về tất cả sản phẩm.
  Future<ProductPage> getProducts(
      {String? categoryId, String? trademarkId, String? searchTerm, int limit = 20, DocumentSnapshot? lastDoc});

  /// Lấy danh sách các ParentProduct phù hợp với một màu cụ thể.
  Future<List<ParentProduct>> getCompatibleParentProducts(ColorData color);

  /// Lấy danh sách các SKU (Product) thuộc về một ParentProduct.
  Future<List<Product>> getSkusForParent(String parentProductId);

  /// Lấy một ParentProduct duy nhất bằng ID.
  Future<ParentProduct> getParentProductById(String id);
}

/// Triển khai repository sử dụng Firebase Firestore.
class FirebaseProductRepository implements IProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<ProductPage> getProducts({
    String? categoryId,
    String? trademarkId,
    String? searchTerm,
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    print(
      '🔍 [ProductRepo] Lấy trang sản phẩm: categoryId=$categoryId, trademarkId=$trademarkId, searchTerm=$searchTerm, limit=$limit',
    );

    // Lưu ý: Tìm kiếm (searchTerm) và phân trang (pagination) thường không đi cùng nhau
    // trong Firestore nếu không có dịch vụ tìm kiếm bên thứ ba (như Algolia).
    // Logic dưới đây giả định rằng khi có searchTerm, chúng ta sẽ không phân trang
    // và tải tất cả kết quả phù hợp (hành vi cũ).
    if (searchTerm != null && searchTerm.isNotEmpty) {
      // Đây là phần logic cũ, không phân trang, để xử lý tìm kiếm.
      // Nó sẽ tải tất cả sản phẩm và lọc phía client.
      print('⚠️ [ProductRepo] Chế độ tìm kiếm, sẽ tải tất cả và lọc phía client.');
      final allProducts = await _getAllProductsForFilter(categoryId, trademarkId);
      final normalizedSearchTerm = searchTerm.toLowerCase().trim();
      final filteredProducts = allProducts.where((product) {
        return product.name.toLowerCase().contains(normalizedSearchTerm) ||
            product.code.toLowerCase().contains(normalizedSearchTerm);
      }).toList();
      return ProductPage(products: filteredProducts, hasMore: false);
    }

    // Logic phân trang mới (khi không có searchTerm)
    // Giả định collection 'products' đã được phi chuẩn hóa với các trường 'categoryId' và 'trademarkId'.
    Query query = _firestore.collection('products').orderBy('name');

    // Áp dụng bộ lọc
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    if (trademarkId != null) {
      query = query.where('trademarkId', isEqualTo: trademarkId);
    }

    // Áp dụng con trỏ phân trang
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    // Giới hạn số lượng kết quả
    final snapshot = await query.limit(limit).get();

    final products = snapshot.docs.map((doc) => Product.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();
    final bool hasMore = products.length == limit;
    final DocumentSnapshot? newLastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    return ProductPage(products: products, hasMore: hasMore, lastDoc: newLastDoc);
  }
  
  // Hàm trợ giúp để giữ lại logic cũ cho việc tìm kiếm (không phân trang)
  Future<List<Product>> _getAllProductsForFilter(String? categoryId, String? trademarkId) async {
     Query query = _firestore.collection('products');
      if (categoryId != null) query = query.where('categoryId', isEqualTo: categoryId);
      if (trademarkId != null) query = query.where('trademarkId', isEqualTo: trademarkId);
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Product.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();
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

  @override
  Future<ParentProduct> getParentProductById(String id) async {
    final doc = await _firestore.collection('parent_products').doc(id).get();
    if (!doc.exists) {
      throw Exception('Không tìm thấy sản phẩm cha với ID: $id');
    }
    return ParentProduct.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>);
  }
}

/// Ghi chú về tối ưu hóa:
/// Mặc dù cách tiếp cận trên hoạt động tốt với cấu trúc dữ liệu hiện tại,
/// một cách tối ưu hơn trong tương lai là "phi chuẩn hóa" (denormalize) dữ liệu.
/// Bằng cách thêm trực tiếp các trường `categoryId` và `trademarkId` vào mỗi
/// document trong collection `products`, bạn có thể thực hiện lọc chỉ với một
/// truy vấn duy nhất, hiệu quả và đơn giản hơn rất nhiều.
