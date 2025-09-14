import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/auth_page.dart';

/// Trang placeholder cho mục "Tài khoản".
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theo dõi trạng thái đăng nhập của người dùng.
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      // Trạng thái đang tải (thường rất nhanh)
      loading: () => const Center(child: CircularProgressIndicator()),
      // Có lỗi khi lấy trạng thái
      error: (err, stack) => Center(child: Text('Lỗi: $err')),
      // Đã có dữ liệu
      data: (user) {
        if (user == null) {
          // Nếu người dùng chưa đăng nhập
          return _buildLoggedOutView(context);
        } else {
          // Nếu người dùng đã đăng nhập
          return _buildLoggedInView(
            context,
            ref,
            user.email ?? 'Không có email',
          );
        }
      },
    );
  }

  /// Giao diện khi người dùng chưa đăng nhập.
  Widget _buildLoggedOutView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Vui lòng đăng nhập để sử dụng đầy đủ tính năng.'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => const AuthPage()));
            },
            child: const Text('Đăng nhập / Đăng ký'),
          ),
        ],
      ),
    );
  }

  /// Giao diện khi người dùng đã đăng nhập.
  Widget _buildLoggedInView(BuildContext context, WidgetRef ref, String email) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chào mừng trở lại!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('Email: $email'),
          const Spacer(), // Đẩy nút đăng xuất xuống dưới cùng
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
