import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/customer_model.dart';
import '../application/customer_providers.dart';
import 'customer_edit_page.dart';

/// Trang hiển thị thông tin chi tiết của một khách hàng.
class CustomerDetailPage extends ConsumerWidget {
  final String customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerByIdProvider(customerId));

    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return customerAsync.when(
      data: (customer) => Scaffold(
        appBar: AppBar(
          title: Text(customer.name),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  // Điều hướng đến trang chỉnh sửa
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) =>
                          CustomerEditPage(customer: customer),
                    ),
                  );
                  // Nếu trang edit trả về true (đã lưu thành công),
                  // chúng ta làm mới (invalidate) provider của trang chi tiết
                  // để nó fetch lại dữ liệu mới nhất từ API.
                  if (result == true && context.mounted) {
                    ref.invalidate(customerByIdProvider(customerId));
                  }
                } else if (value == 'delete') {
                  // Hiển thị hộp thoại xác nhận xóa
                  _showDeleteConfirmationDialog(context, ref, customer);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Chỉnh sửa'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Xóa'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildMainInfoCard(context, customer),
            const SizedBox(height: 16),
            _buildFinancialCard(context, customer, currencyFormatter),
            const SizedBox(height: 16),
            _buildDetailedInfoCard(context, customer),
            const SizedBox(height: 16),
            _buildDateInfoCard(context, customer, dateFormatter),
          ],
        ),
      ),
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SelectableText('Lỗi tải khách hàng: $err'),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa khách hàng "${customer.name}" không? Hành động này không thể hoàn tác.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Đóng dialog
                try {
                  await ref
                      .read(customerRepositoryProvider)
                      .deleteCustomer(customer.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa khách hàng.')),
                    );
                    // Pop với kết quả `true` để báo hiệu cho trang danh sách cần làm mới.
                    Navigator.of(context).pop(true);
                  }
                } catch (e) {
                  // Xử lý lỗi nếu có
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainInfoCard(BuildContext context, Customer customer) {
    String genderText;
    if (customer.gender == true) {
      genderText = 'Nam';
    } else if (customer.gender == false) {
      genderText = 'Nữ';
    } else {
      genderText = 'Không xác định';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (customer.code.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Chip(label: Text('Mã: ${customer.code}')),
              ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              icon: Icons.phone,
              label: 'Số điện thoại',
              value: customer.contactNumber ?? 'Chưa có',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              icon: Icons.wc,
              label: 'Giới tính',
              value: genderText,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              icon: Icons.location_on,
              label: 'Địa chỉ',
              value: customer.address ?? 'Chưa có',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(
    BuildContext context,
    Customer customer,
    NumberFormat formatter,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tài chính', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              icon: Icons.money_off,
              label: 'Công nợ',
              value: formatter.format(customer.debt ?? 0),
              valueStyle: TextStyle(
                color: (customer.debt ?? 0) > 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              icon: Icons.trending_up,
              label: 'Tổng doanh thu',
              value: formatter.format(customer.totalRevenue ?? 0),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              icon: Icons.receipt_long,
              label: 'Tổng đã bán',
              value: formatter.format(customer.totalInvoiced ?? 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedInfoCard(BuildContext context, Customer customer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (customer.email != null && customer.email!.isNotEmpty)
              _buildDetailListTile(
                icon: Icons.email,
                label: 'Email',
                value: customer.email!,
              ),
            if (customer.organization != null &&
                customer.organization!.isNotEmpty) ...[
              const Divider(height: 1),
              _buildDetailListTile(
                icon: Icons.business,
                label: 'Tổ chức',
                value: customer.organization!,
              ),
            ],
            if (customer.taxCode != null && customer.taxCode!.isNotEmpty) ...[
              const Divider(height: 1),
              _buildDetailListTile(
                icon: Icons.description,
                label: 'Mã số thuế',
                value: customer.taxCode!,
              ),
            ],
            if (customer.comments != null && customer.comments!.isNotEmpty) ...[
              const Divider(height: 1),
              _buildDetailListTile(
                icon: Icons.comment,
                label: 'Ghi chú',
                value: customer.comments!,
                isNote: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfoCard(
    BuildContext context,
    Customer customer,
    DateFormat formatter,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (customer.createdDate != null)
              _buildDetailListTile(
                icon: Icons.add_circle_outline,
                label: 'Ngày tạo',
                value: formatter.format(customer.createdDate!),
              ),
            if (customer.modifiedDate != null) ...[
              const Divider(height: 1),
              _buildDetailListTile(
                icon: Icons.edit_calendar,
                label: 'Cập nhật lần cuối',
                value: formatter.format(customer.modifiedDate!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: valueStyle ?? Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailListTile({
    required IconData icon,
    required String label,
    required String value,
    bool isNote = false,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: isNote ? Text(value) : null,
      trailing: isNote
          ? null
          : Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      dense: true,
    );
  }
}
