import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model đại diện cho một người dùng trên hệ thống KiotViet.
///
/// Dữ liệu này thường được lấy từ API của KiotViet và chứa các thông tin
/// chi tiết về nhân viên hoặc người dùng trong cửa hàng.
class KiotVietUser extends Equatable {
  /// ID của người dùng trên KiotViet (ví dụ: 12345).
  final int id;

  /// Tên đăng nhập.
  final String? userName;

  /// Họ và tên đầy đủ.
  final String? givenName;

  /// Địa chỉ.
  final String? address;

  /// Số điện thoại di động.
  final String? mobilePhone;

  /// Địa chỉ email.
  final String? email;

  /// Ghi chú hoặc mô tả về người dùng.
  final String? description;

  /// ID của cửa hàng mà người dùng thuộc về.
  final int? retailerId;

  /// Ngày sinh.
  final DateTime? birthDate;

  /// Ngày tạo tài khoản người dùng.
  final DateTime? createdDate;

  /// Ngày cập nhật thông tin gần nhất.
  final DateTime? modifiedDate;

  const KiotVietUser({
    required this.id,
    this.userName,
    this.givenName,
    this.address,
    this.mobilePhone,
    this.email,
    this.description,
    this.retailerId,
    this.birthDate,
    this.createdDate,
    this.modifiedDate,
  });

  @override
  List<Object?> get props => [
    id,
    userName,
    givenName,
    address,
    mobilePhone,
    email,
    description,
    retailerId,
    birthDate,
    createdDate,
    modifiedDate,
  ];

  /// Tạo một đối tượng KiotVietUser từ một Map (thường là JSON từ API).
  factory KiotVietUser.fromMap(Map<String, dynamic> map) {
    // Hàm tiện ích để chuyển đổi một chuỗi hoặc Timestamp thành DateTime.
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return KiotVietUser(
      id: map['id'] as int,
      userName: map['userName'] as String?,
      givenName: map['givenName'] as String?,
      address: map['address'] as String?,
      mobilePhone: map['mobilePhone'] as String?,
      email: map['email'] as String?,
      description: map['description'] as String?,
      retailerId: map['retailerId'] as int?,
      birthDate: parseDate(map['birthDate']),
      createdDate: parseDate(map['createdDate']),
      modifiedDate: parseDate(map['modifiedDate']),
    );
  }
}
