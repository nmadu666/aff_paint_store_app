import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/presentation/app_scaffold.dart';
import '../application/app_user_provider.dart';
import 'auth_page.dart';

/// Một widget "cổng" để quyết định hiển thị trang đăng nhập hay trang chính của ứng dụng.
///
/// Nó lắng nghe `appUserProvider` để xác định trạng thái xác thực của người dùng.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(appUserProvider);

    return appUserAsync.when(
      data: (appUser) {
        // Nếu có đối tượng AppUser (đã đăng nhập và có dữ liệu), hiển thị màn hình chính.
        if (appUser != null) {
          return const AppScaffold();
        }
        // Nếu không, hiển thị màn hình đăng nhập.
        return const AuthPage();
      },
      // Trong khi tải dữ liệu người dùng, hiển thị màn hình chờ.
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      // Nếu có lỗi, hiển thị thông báo lỗi.
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Đã xảy ra lỗi: $error'))),
    );
  }
}
