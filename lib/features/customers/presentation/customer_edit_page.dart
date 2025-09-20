import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/customer_model.dart';
import '../application/customer_providers.dart';

/// Trang để chỉnh sửa thông tin của một khách hàng.
class CustomerEditPage extends ConsumerStatefulWidget {
  final Customer? customer; // Nullable: nếu null là chế độ tạo mới.

  const CustomerEditPage({super.key, this.customer});

  @override
  ConsumerState<CustomerEditPage> createState() => _CustomerEditPageState();
}

class _CustomerEditPageState extends ConsumerState<CustomerEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _commentsController;
  bool? _gender;

  bool _isLoading = false;
  // Xác định xem có phải đang ở chế độ chỉnh sửa không.
  bool get _isEditMode => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name);
    _phoneController = TextEditingController(
      text: widget.customer?.contactNumber,
    );
    _addressController = TextEditingController(text: widget.customer?.address);
    _emailController = TextEditingController(text: widget.customer?.email);
    _commentsController = TextEditingController(
      text: widget.customer?.comments,
    );
    _gender = widget.customer?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        if (_isEditMode) {
          // Logic cập nhật
          final updatedCustomer = widget.customer!.copyWith(
            name: _nameController.text,
            contactNumber: _phoneController.text,
            address: _addressController.text,
            email: _emailController.text,
            comments: _commentsController.text,
            gender: _gender,
            modifiedDate: DateTime.now(),
          );
          await ref
              .read(customerRepositoryProvider)
              .updateCustomer(updatedCustomer);
        } else {
          // Logic tạo mới
          final newCustomer = Customer(
            id: '', // ID sẽ được Firestore tự động tạo
            kiotId: '',
            code: '',
            name: _nameController.text,
            contactNumber: _phoneController.text.isNotEmpty
                ? _phoneController.text
                : null,
            address: _addressController.text.isNotEmpty
                ? _addressController.text
                : null,
            email: _emailController.text.isNotEmpty
                ? _emailController.text
                : null,
            comments: _commentsController.text.isNotEmpty
                ? _commentsController.text
                : null,
            gender: _gender,
            createdDate: DateTime.now(),
            modifiedDate: DateTime.now(),
          );
          final createdCustomer = await ref.read(customerRepositoryProvider).addCustomer(newCustomer);
          if (mounted) {
            // Pop với khách hàng vừa tạo
            Navigator.of(context).pop(createdCustomer);
          }
          return; // Dừng hàm ở đây để không chạy logic pop bên dưới
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_isEditMode ? 'Cập nhật' : 'Tạo'} khách hàng thành công!',
              ),
            ),
          );
          // Pop với kết quả `true` để báo hiệu cho trang chi tiết cần làm mới.
          Navigator.of(context).pop(true); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi khi ${_isEditMode ? 'cập nhật' : 'tạo mới'}: $e',
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Chỉnh sửa khách hàng' : 'Tạo khách hàng mới',
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveCustomer,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên khách hàng'),
              validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
            ),
            DropdownButtonFormField<bool?>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Giới tính'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Không xác định')),
                DropdownMenuItem(value: true, child: Text('Nam')),
                DropdownMenuItem(value: false, child: Text('Nữ')),
              ],
              onChanged: (value) => setState(() => _gender = value),
            ),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Địa chỉ'),
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextFormField(
              controller: _commentsController,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
