import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/product_model.dart';
import '../../../auth/application/app_user_provider.dart';
import '../../../products/application/paginated_products_provider.dart';

/// A search delegate for finding and selecting products.
class ProductSearchDelegate extends SearchDelegate<Product?> {
  final WidgetRef ref;

  ProductSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => 'Tìm sản phẩm theo tên hoặc mã';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Use the same widget for results and suggestions
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Rebuild suggestions as the user types
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(child: Text('Nhập để bắt đầu tìm kiếm.'));
    }

    // ProductFilter là một typedef cho một record, vì vậy chúng ta tạo nó bằng cú pháp record.
    final filter = (categoryId: null, trademarkId: null, searchTerm: query);
    final productsAsync = ref.watch(paginatedProductsProvider(filter));
    final currentBranch = ref.watch(branchProvider).value; // Lấy chi nhánh hiện tại

    return productsAsync.when(
      data: (state) {
        if (state.products.isEmpty) {
          return const Center(child: Text('Không tìm thấy sản phẩm nào.'));
        }
        return ListView.builder(
          itemCount: state.products.length,
          itemBuilder: (context, index) {
            final product = state.products[index];
            final currencyFormat =
                NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

            // Tìm tồn kho cho chi nhánh hiện tại
            double? onHand;
            if (currentBranch != null && currentBranch.kiotId != null) {
              final currentBranchId = int.tryParse(currentBranch.kiotId!);
              if (currentBranchId != null) {
                try {
                  final inventoryForBranch = product.inventories.firstWhere(
                    (inv) => inv['branchId'] == currentBranchId,
                    orElse: () => {},
                  );
                  if (inventoryForBranch.isNotEmpty) {
                    onHand =
                        (inventoryForBranch['onHand'] as num?)?.toDouble();
                  }
                } catch (e) {
                  // Bỏ qua nếu có lỗi
                }
              }
            }

            // Tính tổng tồn kho nếu không tìm thấy tồn kho của chi nhánh
            final totalOnHand = product.inventories.fold<double>(
              0.0,
              (sum, inv) => sum + ((inv['onHand'] as num?)?.toDouble() ?? 0.0),
            );

            final inventoryText = onHand != null
                ? 'Tồn kho: $onHand'
                : 'Tổng tồn: $totalOnHand';

            return ListTile(
              leading: SizedBox(
                width: 56,
                height: 56,
                child: (product.images != null && product.images!.isNotEmpty)
                    ? Image.network(
                        product.images!.first,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2));
                        },
                        errorBuilder: (context, error, stack) {
                          return const Icon(Icons.image_not_supported);
                        },
                      )
                    : const Icon(Icons.inventory_2_outlined),
              ),
              title: Text(product.name),
              subtitle: Text('Mã: ${product.code}\n$inventoryText'),
              isThreeLine: true,
              trailing: Text(
                product.basePrice != null
                    ? currencyFormat.format(product.basePrice)
                    : 'N/A',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                // Return the selected product when tapped
                close(context, product);
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