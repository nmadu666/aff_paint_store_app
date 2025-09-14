import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import 'cart_provider.dart';

/// Provider này không chứa state, nó chỉ có tác dụng lắng nghe
/// sự thay đổi trạng thái đăng nhập và kích hoạt logic đồng bộ giỏ hàng.
final cartSyncProvider = Provider.autoDispose<void>((ref) {
  User? previousUser = ref.watch(authRepositoryProvider).currentUser;

  ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
    final user = next.value;

    if (user != null && previousUser == null) {
      // Người dùng vừa đăng nhập
      print('🔄 Đồng bộ giỏ hàng: Người dùng đã đăng nhập. Bắt đầu gộp...');
      ref.read(cartProvider.notifier).mergeAndSyncCart(user.uid);
    } else if (user == null && previousUser != null) {
      // Người dùng vừa đăng xuất
      print('🔄 Đồng bộ giỏ hàng: Người dùng đã đăng xuất. Lưu giỏ hàng vào local...');
      ref.read(cartProvider.notifier).persistRemoteCartToLocal(previousUser!.uid);
    }

    // Cập nhật trạng thái người dùng trước đó
    previousUser = user;
  });
});

