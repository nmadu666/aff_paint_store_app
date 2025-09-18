import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_user_model.dart';
import '../../auth/application/app_user_provider.dart';

/// Notifier này xử lý logic nghiệp vụ cho việc cập nhật thông tin AppUser.
class EditProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  EditProfileNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> updateAppUser({
    String? kiotVietUserId, // Tên biến vẫn giữ nguyên
    String? branchId,
    required UserRole role,
  }) async {
    state = const AsyncValue.loading();
    try {
      final currentUser = _ref.read(appUserProvider).value;
      if (currentUser == null) {
        throw Exception('Không tìm thấy người dùng hiện tại.');
      }

      final userRepository = _ref.read(userRepositoryProvider);
      await userRepository.updateUser(
        currentUser.id,
        kiotVietUserId: kiotVietUserId,
        branchId: branchId,
        roleName: role.name,
      );

      // Vô hiệu hóa các provider để chúng tự động làm mới dữ liệu từ Firestore.
      _ref.invalidate(appUserProvider);
      _ref.invalidate(kiotVietUserProvider);
      _ref.invalidate(branchProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Provider để truy cập EditProfileNotifier từ UI.
final editProfileProvider =
    StateNotifierProvider.autoDispose<EditProfileNotifier, AsyncValue<void>>((
      ref,
    ) {
      return EditProfileNotifier(ref);
    });
