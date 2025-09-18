import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum định nghĩa các vai trò của người dùng trong hệ thống.
enum UserRole { admin, saler }

/// Model đại diện cho người dùng của ứng dụng, chứa các thông tin
/// mở rộng ngoài thông tin xác thực của Firebase.
class AppUser {
  final String id; // Tương ứng với Firebase Auth UID
  final String email;
  final UserRole role;
  final DocumentReference?
  kiotVietUserRef; // Tham chiếu đến document người dùng trên KiotViet
  final DocumentReference? branchRef; // Tham chiếu đến chi nhánh trên Firestore

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.kiotVietUserRef,
    this.branchRef,
  });

  /// Tạo một đối tượng AppUser từ một DocumentSnapshot của Firestore.
  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      role: _roleFromString(data['role']),
      kiotVietUserRef: data['kiotviet_user_ref'] as DocumentReference?,
      branchRef: data['branch_ref'] as DocumentReference?,
    );
  }

  /// Chuyển đổi một chuỗi thành giá trị enum UserRole.
  static UserRole _roleFromString(String? roleString) {
    switch (roleString) {
      case 'admin':
        return UserRole.admin;
      case 'saler':
        return UserRole.saler;
      default:
        // Mặc định là 'saler' nếu không có hoặc không hợp lệ.
        return UserRole.saler;
    }
  }

  /// Chuyển đổi UserRole thành chuỗi để dễ đọc.
  String get roleAsString {
    switch (role) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.saler:
        return 'Nhân viên bán hàng';
    }
  }
}
