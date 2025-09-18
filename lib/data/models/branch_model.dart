import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model đại diện cho một chi nhánh trong hệ thống.
///
/// Dữ liệu này được lấy từ collection `branches` trên Firestore.
class Branch extends Equatable {
  /// ID của document trên Firestore.
  final String id;

  /// ID của chi nhánh từ hệ thống KiotViet.
  final String? kiotId;

  /// Tên của chi nhánh.
  final String branchName;

  /// Mã của chi nhánh.
  final String? branchCode;

  /// Số điện thoại liên hệ của chi nhánh.
  final String? contactNumber;

  /// ID của cửa hàng (gian hàng) mà chi nhánh này thuộc về.
  final int? retailerId;

  /// Địa chỉ email của chi nhánh.
  final String? email;

  /// Địa chỉ cụ thể của chi nhánh.
  final String? address;

  /// Thời gian cập nhật gần nhất của thông tin chi nhánh.
  final DateTime? modifiedDate;

  /// Thời gian tạo chi nhánh.
  final DateTime? createdDate;

  const Branch({
    required this.id,
    required this.kiotId,
    required this.branchName,
    this.branchCode,
    this.contactNumber,
    this.retailerId,
    this.email,
    this.address,
    this.modifiedDate,
    this.createdDate,
  });

  @override
  List<Object?> get props => [
    id,
    kiotId,
    branchName,
    branchCode,
    contactNumber,
    retailerId,
    email,
    address,
    modifiedDate,
    createdDate,
  ];

  /// Tạo một đối tượng Branch từ một DocumentSnapshot của Firestore.
  factory Branch.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // Hàm tiện ích để chuyển đổi một Timestamp của Firestore thành DateTime.
    DateTime? parseTimestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      return null;
    }

    return Branch(
      id: doc.id,
      kiotId: data['kiot_id'], // Lấy ID từ KiotViet
      branchName: data['name'] as String,
      branchCode: data['code'] as String?,
      contactNumber: data['phone'] as String?,
      retailerId: data['retailerId'] as int?,
      email: data['email'] as String?,
      address: data['address'] as String?,
      modifiedDate: parseTimestamp(data['modifiedDate']),
      createdDate: parseTimestamp(data['createdDate']),
    );
  }
}
