import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user_model.dart';
import '../sources/local/user_local_data_source.dart';

/// Lớp trừu tượng định nghĩa phương thức lấy thông tin người dùng.
abstract class IUserRepository {
  /// Lấy thông tin chi tiết của người dùng bằng UID.
  Future<AppUser?> getUser(String uid);

  /// Cập nhật thông tin của một người dùng bằng UID.
  Future<void> updateUser(
    String uid, {
    String? kiotVietUserId,
    String? branchId,
    required String roleName,
  });

  /// Lấy danh sách tất cả người dùng.
  Future<List<AppUser>> getAllUsers();

  /// Xóa một document người dùng khỏi Firestore.
  Future<void> deleteUserDocument(String uid);

  /// Tạo một document người dùng mới trong Firestore.
  Future<void> createUserDocument({
    required String uid,
    required String email,
    String? kiotVietUserId,
    String? branchId,
    required String roleName,
  });
}

/// Triển khai repository sử dụng Firebase Firestore.
class FirebaseUserRepository implements IUserRepository {
  final FirebaseFirestore _firestore;
  final UserLocalDataSource _localDataSource;

  FirebaseUserRepository(this._firestore, this._localDataSource);

  @override
  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      final appUser = AppUser.fromFirestore(doc);
      await _localDataSource.saveUserData(
        kiotVietUserId: appUser.kiotVietUserRef?.id,
        branchId: appUser.branchRef?.id,
      );
      return appUser;
    }
    return null;
  }

  @override
  Future<void> updateUser(
    String uid, {
    String? kiotVietUserId,
    String? branchId,
    required String roleName,
  }) async {
    final data = {
      'kiotviet_user_ref': kiotVietUserId != null
          ? _firestore.collection('kiotviet_users').doc(kiotVietUserId)
          : null,
      'branch_ref': branchId != null
          ? _firestore.collection('branches').doc(branchId)
          : null,
      'role': roleName,
    };
    await _firestore.collection('users').doc(uid).update(data);
  }

  @override
  Future<List<AppUser>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
  }

  @override
  Future<void> createUserDocument({
    required String uid,
    required String email,
    String? kiotVietUserId,
    String? branchId,
    required String roleName,
  }) async {
    final data = {
      'email': email,
      'kiotviet_user_ref': kiotVietUserId != null
          ? _firestore.collection('kiotviet_users').doc(kiotVietUserId)
          : null,
      'branch_ref': branchId != null
          ? _firestore.collection('branches').doc(branchId)
          : null,
      'role': roleName,
    };
    // Sử dụng `set` để tạo document mới.
    await _firestore.collection('users').doc(uid).set(data);
  }

  @override
  Future<void> deleteUserDocument(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}