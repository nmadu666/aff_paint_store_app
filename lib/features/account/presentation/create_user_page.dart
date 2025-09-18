import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_user_model.dart';
import '../../auth/application/app_user_provider.dart';
import '../application/user_management_provider.dart';

/// Trang cho phép quản trị viên tạo một AppUser mới.
class CreateUserPage extends ConsumerStatefulWidget {
  const CreateUserPage({super.key});

  @override
  ConsumerState<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends ConsumerState<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedKiotVietUserId;
  String? _selectedBranchRefId;
  UserRole _selectedRole = UserRole.saler; // Mặc định là saler

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final notifier = ref.read(userManagementProvider.notifier);
      try {
        await notifier.createUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          kiotVietUserId: _selectedKiotVietUserId,
          branchId: _selectedBranchRefId,
          role: _selectedRole,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo người dùng thành công!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tạo người dùng: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(userManagementProvider).isLoading;
    final allBranchesAsync = ref.watch(allBranchesProvider);
    final allKiotVietUsersAsync = ref.watch(allKiotVietUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo người dùng mới'),
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _createUser),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Vui lòng nhập email hợp lệ.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Dropdown for KiotViet User
              allKiotVietUsersAsync.when(
                data: (users) => DropdownButtonFormField<String>(
                  value: _selectedKiotVietUserId,
                  decoration: const InputDecoration(
                    labelText: 'Người dùng KiotViet (Tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                  items: users.map((user) {
                    return DropdownMenuItem<String>(value: user.key, child: Text(user.value));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedKiotVietUserId = value),
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
                    labelText: 'Chi nhánh (Tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                  items: branches.map((branch) {
                    return DropdownMenuItem<String>(value: branch.id, child: Text(branch.branchName));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedBranchRefId = value),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Lỗi tải chi nhánh: $e'),
              ),
              const SizedBox(height: 16),
              // Dropdown for Role
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Vai trò', border: OutlineInputBorder()),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem<UserRole>(
                    value: role,
                    child: Text(role == UserRole.admin ? 'Quản trị viên' : 'Nhân viên bán hàng'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedRole = value);
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