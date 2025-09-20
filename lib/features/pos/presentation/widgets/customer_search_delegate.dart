import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/customer_model.dart';
import '../../../customers/application/customer_providers.dart';
import '../../../customers/presentation/customer_edit_page.dart';

/// A search delegate for finding and selecting a customer.
class CustomerSearchDelegate extends SearchDelegate<Customer?> {
  final WidgetRef ref;

  CustomerSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => 'Tìm khách hàng theo SĐT hoặc tên';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Nhập để bắt đầu tìm kiếm.'));
    }

    final filter = (searchTerm: query);
    final customersAsync = ref.watch(paginatedCustomersProvider(filter));

    return customersAsync.when(
      data: (state) {
        if (state.customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Không tìm thấy khách hàng nào.'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Điều hướng đến trang tạo khách hàng mới
                    final newCustomer = await Navigator.of(context).push<Customer?>(
                      MaterialPageRoute(builder: (context) => const CustomerEditPage()),
                    );
                    // Nếu khách hàng được tạo thành công, đóng màn hình tìm kiếm
                    // và trả về khách hàng mới.
                    if (newCustomer != null) {
                      close(context, newCustomer);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo khách hàng mới'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: state.customers.length,
          itemBuilder: (context, index) {
            final customer = state.customers[index];
            return ListTile(
              title: Text(customer.name),
              subtitle: Text(customer.contactNumber ?? 'Chưa có SĐT'),
              onTap: () {
                // Return the selected customer
                close(context, customer);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Đã xảy ra lỗi: $error'),
      ),
    );
  }
}