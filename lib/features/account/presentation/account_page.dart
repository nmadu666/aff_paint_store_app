import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_user_model.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/app_user_provider.dart';
import '../../auth/presentation/auth_page.dart';
import 'edit_profile_page.dart';
import 'user_management_page.dart';

/// Trang placeholder cho mục "Tài khoản".
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theo dõi provider người dùng của ứng dụng.
    final appUserAsync = ref.watch(appUserProvider);

    return appUserAsync.when(
      // Trạng thái đang tải (thường rất nhanh)
      loading: () => const Center(child: CircularProgressIndicator()),
      // Có lỗi khi lấy trạng thái
      error: (err, stack) => Center(child: Text('Lỗi: $err')),
      // Đã có dữ liệu
      data: (user) {
        // user ở đây là một đối tượng AppUser?
        if (user == null) {
          // Nếu người dùng chưa đăng nhập
          return _buildLoggedOutView(context);
        } else {
          // Nếu người dùng đã đăng nhập
          return _buildLoggedInView(context, ref, user);
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
  Widget _buildLoggedInView(BuildContext context, WidgetRef ref, AppUser user) {
    // Lắng nghe thông tin chi tiết của KiotViet user và Branch
    final kiotVietUserAsync = ref.watch(kiotVietUserProvider);
    final branchAsync = ref.watch(branchProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hiển thị tên nhân viên KiotViet nếu có
          kiotVietUserAsync.when(
            data: (kiotVietUser) {
              if (kiotVietUser != null && kiotVietUser.givenName != null) {
                return Text(
                  'Xin chào, ${kiotVietUser.givenName}!',
                  style: Theme.of(context).textTheme.headlineSmall,
                );
              }
              // Fallback nếu không có tên
              return Text(
                'Chào mừng trở lại!',
                style: Theme.of(context).textTheme.headlineSmall,
              );
            },
            loading: () =>
                const SizedBox.shrink(), // Không hiển thị gì khi đang tải
            error: (e, st) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          Text('Email: ${user.email}'),
          const SizedBox(height: 8),
          Text('Vai trò: ${user.roleAsString}'),
          const SizedBox(height: 8),
          // Hiển thị thông tin chi nhánh
          branchAsync.when(
            data: (branch) {
              if (branch != null) {
                return Text('Chi nhánh: ${branch.branchName}');
              }
              return const Text('Chi nhánh: Chưa được gán');
            },
            loading: () => const Text('Chi nhánh: Đang tải...'),
            error: (e, st) => const Text('Chi nhánh: Lỗi tải dữ liệu'),
          ),
          const SizedBox(height: 16),
          // Chỉ hiển thị nút chỉnh sửa nếu người dùng là admin
          if (user.role == UserRole.admin)
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Chỉnh sửa thông tin cá nhân'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const UserManagementPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.manage_accounts),
                    label: const Text('Quản lý người dùng'),
                  ),
                ],
              ),
            ),
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
