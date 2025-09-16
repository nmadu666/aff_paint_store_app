import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_model.dart';
import 'customer_repository.dart';

/// Service để gọi đến Firebase Function Proxy cho KiotViet API.
class KiotVietApiService {
  static const String _proxyBaseUrl =
      'https://asia-southeast1-aff-paint-store-app.cloudfunctions.net/kiotVietProxy';

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(
      '$_proxyBaseUrl$endpoint',
    ).replace(queryParameters: queryParams);
    return http.get(uri);
  }

  Future<http.Response> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    return http.post(
      Uri.parse('$_proxyBaseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
  }

  Future<http.Response> put(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    return http.put(
      Uri.parse('$_proxyBaseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
  }

  Future<http.Response> delete(String endpoint) async {
    return http.delete(Uri.parse('$_proxyBaseUrl$endpoint'));
  }
}

/// Implementation của ICustomerRepository sử dụng KiotViet API.
class KiotVietCustomerRepository implements ICustomerRepository {
  final KiotVietApiService _apiService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  KiotVietCustomerRepository(this._apiService);

  CollectionReference<Map<String, dynamic>> get _customersCollection =>
      _firestore.collection('customers');

  @override
  Future<CustomerPage> getCustomers({
    String? searchTerm,
    int limit = 20,
    // KiotViet API dùng currentItem, không dùng lastDoc. Chúng ta sẽ cần tính toán currentItem từ số trang.
    DocumentSnapshot? lastDoc,
    int currentItem = 0,
  }) async {
    final params = {
      'pageSize': limit.toString(),
      'currentItem': currentItem.toString(),
      'includeTotal': 'true',
    };
    if (searchTerm != null && searchTerm.isNotEmpty) {
      params['contactNumber'] = searchTerm; // Giả định tìm theo SĐT
    }

    final response = await _apiService.get('/customers', queryParams: params);

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final customersData = data['data'] as List;
      final total = data['total'] as int;

      final customers = customersData.map((item) {
        // Chuyển đổi dữ liệu từ KiotViet API sang Customer model
        return Customer(
          id: item['id'].toString(),
          kiotId: item['id'].toString(),
          code: item['code'] ?? '',
          name: item['name'] ?? 'N/A',
          gender: item['gender'],
          contactNumber: item['contactNumber'],
          address: item['address'],
          debt: (item['debt'] as num?)?.toDouble(),
          totalRevenue: (item['totalRevenue'] as num?)?.toDouble(),
          totalInvoiced: (item['totalInvoiced'] as num?)?.toDouble(),
          createdDate: item['createdDate'] != null
              ? DateTime.tryParse(item['createdDate'])
              : null,
          modifiedDate: item['modifiedDate'] != null
              ? DateTime.tryParse(item['modifiedDate'])
              : null,
          email: item['email'],
          organization: item['organization'],
          taxCode: item['taxCode'],
          comments: item['comments'],
        );
      }).toList();

      return CustomerPage(
        customers: customers,
        hasMore: (currentItem + customers.length) < total,
        lastDoc: null, // Không áp dụng cho KiotViet
      );
    } else {
      throw Exception(
        'Failed to load customers from KiotViet: ${response.body}',
      );
    }
  }

  @override
  Future<Customer> getCustomerById(String id) async {
    final response = await _apiService.get('/customers/$id');
    if (response.statusCode == 200) {
      final item = json.decode(utf8.decode(response.bodyBytes));
      return Customer(
        id: item['id'].toString(),
        kiotId: item['id'].toString(),
        code: item['code'] ?? '',
        name: item['name'] ?? 'N/A',
        gender: item['gender'],
        contactNumber: item['contactNumber'],
        address: item['address'],
        debt: (item['debt'] as num?)?.toDouble(),
        totalRevenue: (item['totalRevenue'] as num?)?.toDouble(),
        totalInvoiced: (item['totalInvoiced'] as num?)?.toDouble(),
        createdDate: item['createdDate'] != null
            ? DateTime.tryParse(item['createdDate'])
            : null,
        modifiedDate: item['modifiedDate'] != null
            ? DateTime.tryParse(item['modifiedDate'])
            : null,
        email: item['email'],
        organization: item['organization'],
        taxCode: item['taxCode'],
        comments: item['comments'],
      );
    } else {
      throw Exception(
        'Failed to load customer $id from KiotViet: ${response.body}',
      );
    }
  }

  @override
  Future<void> addCustomer(Customer customer) async {
    // 1. Gọi API KiotViet để tạo khách hàng
    final body = {
      'name': customer.name,
      'contactNumber': customer.contactNumber,
      'address': customer.address,
      'gender': customer.gender,
      'email': customer.email,
      'comments': customer.comments,
    };
    final response = await _apiService.post('/customers', body: body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to add customer to KiotViet: ${response.body}');
    }

    // 2. Nếu thành công, lấy dữ liệu trả về và lưu vào Firestore
    final kiotCustomerData = json.decode(utf8.decode(response.bodyBytes));
    final newCustomer = customer.copyWith(
      kiotId: kiotCustomerData['id'].toString(),
      code: kiotCustomerData['code'],
    );
    await _customersCollection.add(newCustomer.toJson());
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    final body = {
      'id': int.tryParse(customer.id),
      'name': customer.name,
      'contactNumber': customer.contactNumber,
      'address': customer.address,
      'gender': customer.gender,
      'email': customer.email,
      'comments': customer.comments,
    };
    // 1. Gọi API KiotViet để cập nhật
    final response = await _apiService.put(
      '/customers/${customer.id}',
      body: body,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to update customer on KiotViet: ${response.body}',
      );
    }

    // 2. Nếu thành công, cập nhật vào Firestore
    // Tìm document trong Firestore bằng kiot_id
    final querySnapshot = await _customersCollection
        .where('kiot_id', isEqualTo: customer.id)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.update(customer.toJson());
    }
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    final response = await _apiService.delete('/customers/$customerId');
    // API KiotViet có thể trả về 200 hoặc 204 cho delete
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to delete customer from KiotViet: ${response.body}',
      );
    }
    // Logic xóa khỏi Firebase có thể thêm ở đây nếu cần
  }
}
