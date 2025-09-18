import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_user_model.dart';
import '../../auth/application/app_user_provider.dart';
import '../application/user_management_provider.dart';

/// Trang cho phép quản trị viên chỉnh sửa thông tin của một AppUser khác.
class EditUserPage extends ConsumerStatefulWidget {
  final AppUser userToEdit;

  const EditUserPage({super.key, required this.userToEdit});

  @override
  ConsumerState<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends ConsumerState<EditUserPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedKiotVietUserId;
  String? _selectedBranchRefId;
  late UserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    // Khởi tạo giá trị ban đầu từ người dùng được truyền vào.
    _selectedKiotVietUserId = widget.userToEdit.kiotVietUserRef?.id;
    _selectedBranchRefId = widget.userToEdit.branchRef?.id;
    _selectedRole = widget.userToEdit.role;
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final notifier = ref.read(userManagementProvider.notifier);
      await notifier.updateUser(
        userId: widget.userToEdit.id,
        kiotVietUserId: _selectedKiotVietUserId,
        branchId: _selectedBranchRefId,
        role: _selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công!')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(userManagementProvider, (_, state) {
      state.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật: $error')),
          );
        },
      );
    });

    final isSaving = ref.watch(userManagementProvider).isLoading;
    final allBranchesAsync = ref.watch(allBranchesProvider);
    final allKiotVietUsersAsync = ref.watch(allKiotVietUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sửa: ${widget.userToEdit.email}'),
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveProfile),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dropdown for KiotViet User
              allKiotVietUsersAsync.when(
                data: (users) => DropdownButtonFormField<String>(
                  value: _selectedKiotVietUserId,
                  decoration: const InputDecoration(
                    labelText: 'Người dùng KiotViet',
                    border: OutlineInputBorder(),
                  ),
                  items: users.map((user) {
                    return DropdownMenuItem<String>(
                      value: user.key, // Document ID
                      child: Text(user.value), // Given Name
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedKiotVietUserId = value;
                    });
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Lỗi tải người dùng KiotViet: $e'),
              ),
              const SizedBox(height: 16),

              // Dropdown for Branch
              allBranchesAsync.when(
                data: (branches) => DropdownButtonFormField<String>(
                  value: _selectedBranchRefId,
                  decoration: const InputDecoration(
                    labelText: 'Chi nhánh',
                    border: OutlineInputBorder(),
                  ),
                  items: branches.map((branch) {
                    return DropdownMenuItem<String>(
                      value: branch.id,
                      child: Text(branch.branchName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBranchRefId = value;
                    });
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Lỗi tải chi nhánh: $e'),
              ),
              const SizedBox(height: 16),

              // Dropdown for Role
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Vai trò',
                  border: OutlineInputBorder(),
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem<UserRole>(
                    value: role,
                    child: Text(role == UserRole.admin ? 'Quản trị viên' : 'Nhân viên bán hàng'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
                validator: (value) => value == null ? 'Vui lòng chọn vai trò' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}