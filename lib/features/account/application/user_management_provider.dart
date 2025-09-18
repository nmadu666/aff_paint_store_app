import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_user_model.dart';
import '../../auth/application/app_user_provider.dart';
import '../../auth/application/auth_providers.dart';

/// Notifier này xử lý logic nghiệp vụ cho việc quản trị viên cập nhật
/// thông tin của một người dùng khác.
class UserManagementNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  UserManagementNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> updateUser({
    required String userId, // ID của người dùng cần cập nhật
    String? kiotVietUserId,
    String? branchId,
    required UserRole role,
  }) async {
    state = const AsyncValue.loading();
    try {
      final userRepository = _ref.read(userRepositoryProvider);
      await userRepository.updateUser(
        userId, // Sử dụng ID của người dùng được truyền vào
        kiotVietUserId: kiotVietUserId,
        branchId: branchId,
        roleName: role.name,
      );

      // Vô hiệu hóa các provider để chúng tự động làm mới dữ liệu.
      _ref.invalidate(allAppUsersProvider); // Làm mới danh sách người dùng.

      // Nếu người dùng được chỉnh sửa là người dùng hiện tại,
      // cũng làm mới thông tin của họ.
      final currentUser = _ref.read(appUserProvider).value;
      if (currentUser?.id == userId) {
        _ref.invalidate(appUserProvider);
        _ref.invalidate(kiotVietUserProvider);
        _ref.invalidate(branchProvider);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> createUser({
    required String email,
    required String password,
    String? kiotVietUserId,
    String? branchId,
    required UserRole role,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Tạo người dùng trong Firebase Auth.
      final authRepository = _ref.read(authRepositoryProvider);
      final userCredential =
          await authRepository.createUserWithEmailAndPassword(email, password);
      final newUser = userCredential.user;

      if (newUser == null) {
        throw Exception('Không thể tạo tài khoản trong Firebase Auth.');
      }

      // 2. Tạo document người dùng trong Firestore.
      final userRepository = _ref.read(userRepositoryProvider);
      await userRepository.createUserDocument(
        uid: newUser.uid,
        email: email,
        kiotVietUserId: kiotVietUserId,
        branchId: branchId,
        roleName: role.name,
      );

      // 3. Làm mới danh sách người dùng.
      _ref.invalidate(allAppUsersProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteUser(String userId, String userEmail) async {
    state = const AsyncValue.loading();
    try {
      // BƯỚC 1: Gọi Cloud Function để xóa người dùng khỏi Firebase Authentication.
      // Đây là bước bắt buộc và an toàn để xóa tài khoản xác thực.
      // Thay 'your-region' bằng region của project Firebase của bạn (ví dụ: 'us-central1').
      final callable = FirebaseFunctions.instanceFor(region: 'asia-southeast1')
          .httpsCallable('deleteAuthUser');
      final result = await callable.call<Map<String, dynamic>>({
        'uid': userId,
        'email': userEmail,
      });

      // Kiểm tra kết quả từ Cloud Function.
      if (result.data['success'] != true) {
        throw Exception(
          result.data['error'] ?? 'Lỗi không xác định từ Cloud Function.',
        );
      }

      // BƯỚC 2: Nếu xóa tài khoản Auth thành công, xóa document trong Firestore.
      final userRepository = _ref.read(userRepositoryProvider);
      await userRepository.deleteUserDocument(userId);

      // BƯỚC 3: Làm mới lại danh sách người dùng trên UI.
      _ref.invalidate(allAppUsersProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Provider để truy cập UserManagementNotifier từ UI.
final userManagementProvider =
    StateNotifierProvider.autoDispose<UserManagementNotifier, AsyncValue<void>>(
        (ref) {
  return UserManagementNotifier(ref);
});
