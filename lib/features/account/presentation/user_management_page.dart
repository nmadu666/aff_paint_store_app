import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/app_user_provider.dart';
import '../application/user_management_provider.dart';
import 'edit_user_page.dart';
import 'create_user_page.dart';

/// Trang hiển thị danh sách tất cả người dùng cho quản trị viên.
class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allUsersAsync = ref.watch(allAppUsersProvider);
    final currentUser = ref.watch(appUserProvider).value;

    // Hàm hiển thị hộp thoại xác nhận xóa
    Future<bool> _showDeleteConfirmDialog(String userEmail) async {
      final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: Text('Bạn có chắc chắn muốn xóa người dùng "$userEmail"? Hành động này không thể hoàn tác.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Hủy'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Xóa'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
      return result ?? false;
    }

    // Lắng nghe trạng thái để hiển thị lỗi
    ref.listen<AsyncValue<void>>(userManagementProvider, (_, state) {
      state.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa người dùng: $error')),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateUserPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo mới'),
      ),
      body: allUsersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Không có người dùng nào.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(allAppUsersProvider.future),
            child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              // Không cho phép admin tự xóa chính mình
              final canDelete = currentUser?.id != user.id;

              return Dismissible(
                key: ValueKey(user.id),
                direction: canDelete ? DismissDirection.endToStart : DismissDirection.none,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await _showDeleteConfirmDialog(user.email);
                },
                onDismissed: (direction) {
                  ref.read(userManagementProvider.notifier).deleteUser(user.id, user.email);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(user.email),
                    subtitle: Text('Vai trò: ${user.roleAsString}'),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditUserPage(userToEdit: user),
                        ),
                      ).then((_) {
                        // Làm mới lại danh sách sau khi chỉnh sửa
                        ref.invalidate(allAppUsersProvider);
                      });
                    },
                  ),
                ),
              );
            },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Lỗi tải danh sách người dùng: $error'),
        ),
      ),
    );
  }
}
