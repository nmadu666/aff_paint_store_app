import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Đại diện cho một khách hàng.
class Customer extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? normalizedPhone; // Trường để tìm kiếm SĐT đã chuẩn hóa
  final String? email;
  final String? address;
  final String? customerType; // Ví dụ: 'Thợ', 'Đại lý', 'Lẻ'
  final String? notes;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.normalizedPhone,
    this.email,
    this.address,
    this.customerType,
    this.notes,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    normalizedPhone,
    email,
    address,
    customerType,
    notes,
  ];

  /// Tạo một đối tượng Customer từ một DocumentSnapshot của Firestore.
  factory Customer.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw "Dữ liệu Customer không tồn tại từ snapshot: ${snapshot.id}";
    }
    return Customer(
      id: snapshot.id,
      name: data['name'] as String? ?? 'Khách hàng không tên',
      phone: data['phone'] as String?,
      normalizedPhone: data['normalizedPhone'] as String?,
      email: data['email'] as String?,
      address: data['address'] as String?,
      customerType: data['customerType'] as String?,
      notes: data['notes'] as String?,
    );
  }

  /// Chuyển đổi đối tượng Customer thành một Map để lưu vào Firestore.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      // Tự động tạo trường chuẩn hóa khi lưu
      'normalizedPhone': phone?.replaceAll(RegExp(r'\D'), ''),
      'email': email,
      'address': address,
      'customerType': customerType,
      'notes': notes,
    };
  }
}

/// Đại diện cho một trang dữ liệu khách hàng từ một truy vấn có phân trang.
class CustomerPage {
  final List<Customer> customers;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;

  const CustomerPage({
    required this.customers,
    required this.hasMore,
    this.lastDoc,
  });
}
