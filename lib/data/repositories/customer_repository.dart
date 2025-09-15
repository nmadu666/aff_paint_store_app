import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

/// Interface cho repository quản lý dữ liệu khách hàng.
abstract class ICustomerRepository {
  /// Lấy một trang khách hàng, có phân trang và tìm kiếm.
  Future<CustomerPage> getCustomers({
    String? searchTerm,
    int limit,
    DocumentSnapshot? lastDoc,
  });

  /// Lấy thông tin chi tiết một khách hàng bằng ID.
  Future<Customer> getCustomerById(String id);

  /// Thêm một khách hàng mới.
  Future<void> addCustomer(Customer customer);

  /// Cập nhật thông tin một khách hàng.
  Future<void> updateCustomer(Customer customer);
}

/// Implementation của ICustomerRepository sử dụng Firebase Firestore.
class FirebaseCustomerRepository implements ICustomerRepository {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('customers');
  static const _defaultLimit = 20;

  @override
  Future<CustomerPage> getCustomers({
    String? searchTerm,
    int limit = _defaultLimit,
    DocumentSnapshot? lastDoc,
  }) async {
    Query<Map<String, dynamic>> query = _collection.orderBy('name');

    // Logic tìm kiếm cơ bản.
    // Lưu ý: Firestore không hỗ trợ tìm kiếm "contains" hiệu quả.
    // Để tìm kiếm toàn văn bản, hãy cân nhắc sử dụng dịch vụ của bên thứ ba như Algolia.
    if (searchTerm != null && searchTerm.isNotEmpty) {
      final normalizedSearch = searchTerm.replaceAll(RegExp(r'\D'), '');
      if (double.tryParse(normalizedSearch) != null &&
          normalizedSearch.length > 2) {
        // Ưu tiên tìm kiếm theo SĐT nếu chuỗi nhập vào chủ yếu là số
        query = _collection
            .orderBy('normalizedPhone')
            .where('normalizedPhone', isGreaterThanOrEqualTo: normalizedSearch)
            .where(
              'normalizedPhone',
              isLessThanOrEqualTo: '$normalizedSearch\uf8ff',
            );
      } else {
        // Tìm kiếm theo tên
        query = query
            .where('name', isGreaterThanOrEqualTo: searchTerm)
            .where('name', isLessThanOrEqualTo: '$searchTerm\uf8ff');
      }
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final querySnapshot = await query.limit(limit).get();
    final customers = querySnapshot.docs
        .map((doc) => Customer.fromFirestore(doc))
        .toList();

    return CustomerPage(
      customers: customers,
      hasMore: customers.length == limit,
      lastDoc: querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null,
    );
  }

  @override
  Future<Customer> getCustomerById(String id) async {
    final doc = await _collection.doc(id).get();
    return Customer.fromFirestore(doc);
  }

  @override
  Future<void> addCustomer(Customer customer) {
    return _collection.add(customer.toJson());
  }

  @override
  Future<void> updateCustomer(Customer customer) {
    return _collection.doc(customer.id).update(customer.toJson());
  }
}
