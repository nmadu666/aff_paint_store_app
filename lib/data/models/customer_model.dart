import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Đại diện cho một khách hàng, với dữ liệu được đồng bộ từ KiotViet.
class Customer extends Equatable {
  final String id;
  final String kiotId;
  final String code;
  final String name;
  final bool? gender;
  final DateTime? birthDate;
  final String? contactNumber;
  final String? address;
  final String? locationName;
  final String? wardName;
  final String? email;
  final String? organization;
  final String? comments;
  final String? taxCode;
  final double? debt;
  final double? totalInvoiced;
  final double? totalPoint;
  final double? totalRevenue;
  final String? retailerId;
  final DateTime? modifiedDate;
  final DateTime? createdDate;
  final double? rewardPoint;
  final String? psidFacebook;

  // --- Các trường tùy chỉnh của ứng dụng ---
  final String? normalizedPhone; // Để tìm kiếm SĐT đã chuẩn hóa
  final String? customerType; // Ví dụ: 'Thợ', 'Đại lý', 'Lẻ'

  const Customer({
    required this.id,
    required this.kiotId,
    required this.code,
    required this.name,
    this.gender,
    this.birthDate,
    this.contactNumber,
    this.address,
    this.locationName,
    this.wardName,
    this.email,
    this.organization,
    this.comments,
    this.taxCode,
    this.debt,
    this.totalInvoiced,
    this.totalPoint,
    this.totalRevenue,
    this.retailerId,
    this.modifiedDate,
    this.createdDate,
    this.rewardPoint,
    this.psidFacebook,
    this.normalizedPhone,
    this.customerType,
  });

  @override
  List<Object?> get props => [
    id,
    kiotId,
    code,
    name,
    gender,
    birthDate,
    contactNumber,
    address,
    locationName,
    wardName,
    email,
    organization,
    comments,
    taxCode,
    debt,
    totalInvoiced,
    totalPoint,
    totalRevenue,
    retailerId,
    modifiedDate,
    createdDate,
    rewardPoint,
    psidFacebook,
    normalizedPhone,
    customerType,
  ];

  /// Tạo một đối tượng Customer từ một DocumentSnapshot của Firestore.
  factory Customer.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw "Dữ liệu Customer không tồn tại từ snapshot: ${snapshot.id}";
    }

    // Hàm tiện ích để chuyển đổi một giá trị động (có thể là String hoặc num) thành double.
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // Hàm tiện ích để chuyển đổi một chuỗi thành DateTime.
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      if (value is Timestamp) return value.toDate();
      return null;
    }

    // Hàm tiện ích để chuyển đổi một giá trị động thành String một cách an toàn.
    String? parseString(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    return Customer(
      id: snapshot.id,
      kiotId: parseString(data['kiot_id']) ?? '',
      code: parseString(data['code']) ?? '',
      name: data['name'] as String? ?? 'Khách hàng không tên',
      gender: data['gender'] as bool?,
      birthDate: parseDate(data['birthDate']),
      contactNumber: parseString(data['contactNumber']),
      address: data['address'] as String?,
      locationName: data['locationName'] as String?,
      wardName: data['wardName'] as String?,
      email: data['email'] as String?,
      organization: data['organization'] as String?,
      comments: data['comments'] as String?,
      taxCode: parseString(data['taxCode']),
      debt: parseDouble(data['debt']),
      totalInvoiced: parseDouble(data['totalInvoiced']),
      totalPoint: parseDouble(data['totalPoint']),
      totalRevenue: parseDouble(data['totalRevenue']),
      retailerId: parseString(data['retailerId']),
      modifiedDate: parseDate(data['modifiedDate']),
      createdDate: parseDate(data['createdDate']),
      rewardPoint: parseDouble(data['rewardPoint']),
      psidFacebook: parseString(data['psidFacebook']),
      // Tạo trường chuẩn hóa nếu nó không tồn tại trong Firestore
      normalizedPhone:
          parseString(data['normalizedPhone']) ??
          parseString(data['contactNumber'])?.replaceAll(RegExp(r'\D'), ''),
      customerType: data['customerType'] as String?,
    );
  }

  /// Chuyển đổi đối tượng Customer thành một Map để lưu vào Firestore.
  Map<String, dynamic> toJson() {
    return {
      'kiot_id': kiotId,
      'code': code,
      'name': name,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'contactNumber': contactNumber,
      'address': address,
      'locationName': locationName,
      'wardName': wardName,
      'email': email,
      'organization': organization,
      'comments': comments,
      'taxCode': taxCode,
      'debt': debt,
      'totalInvoiced': totalInvoiced,
      'totalPoint': totalPoint,
      'totalRevenue': totalRevenue,
      'retailerId': retailerId,
      'modifiedDate': modifiedDate?.toIso8601String(),
      'createdDate': createdDate?.toIso8601String(),
      'rewardPoint': rewardPoint,
      'psidFacebook': psidFacebook,
      'normalizedPhone': contactNumber?.replaceAll(RegExp(r'\D'), ''),
      'customerType': customerType,
    };
  }

  /// Tạo một bản sao của đối tượng Customer với các giá trị được cập nhật.
  Customer copyWith({
    String? id,
    String? kiotId,
    String? code,
    String? name,
    bool? gender,
    DateTime? birthDate,
    String? contactNumber,
    String? address,
    String? locationName,
    String? wardName,
    String? email,
    String? organization,
    String? comments,
    String? taxCode,
    double? debt,
    double? totalInvoiced,
    double? totalPoint,
    double? totalRevenue,
    String? retailerId,
    DateTime? modifiedDate,
    DateTime? createdDate,
    double? rewardPoint,
    String? psidFacebook,
    String? normalizedPhone,
    String? customerType,
  }) {
    return Customer(
      id: id ?? this.id,
      kiotId: kiotId ?? this.kiotId,
      code: code ?? this.code,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      locationName: locationName ?? this.locationName,
      wardName: wardName ?? this.wardName,
      email: email ?? this.email,
      organization: organization ?? this.organization,
      comments: comments ?? this.comments,
      taxCode: taxCode ?? this.taxCode,
      debt: debt ?? this.debt,
      totalInvoiced: totalInvoiced ?? this.totalInvoiced,
      totalPoint: totalPoint ?? this.totalPoint,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      retailerId: retailerId ?? this.retailerId,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      createdDate: createdDate ?? this.createdDate,
      rewardPoint: rewardPoint ?? this.rewardPoint,
      psidFacebook: psidFacebook ?? this.psidFacebook,
      normalizedPhone: normalizedPhone ?? this.normalizedPhone,
      customerType: customerType ?? this.customerType,
    );
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
