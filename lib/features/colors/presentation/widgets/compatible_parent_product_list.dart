import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/color_data_model.dart';
import '../../../../data/models/parent_product_model.dart';
import '../../../products/application/product_providers.dart';

/// Một widget hiển thị danh sách các `ParentProduct` tương thích với một màu
/// và cho phép người dùng chọn một sản phẩm.
///
/// Widget này tự quản lý việc lấy dữ liệu bằng cách sử dụng
/// `compatibleParentProductsProvider`.
class CompatibleParentProductList extends ConsumerWidget {
  /// Màu được chọn, dùng để tìm các sản phẩm tương thích.
  final ColorData color;

  /// Callback được gọi khi người dùng chọn một `ParentProduct` từ danh sách.
  final ValueChanged<ParentProduct> onParentProductSelected;

  const CompatibleParentProductList({
    super.key,
    required this.color,
    required this.onParentProductSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theo dõi provider để lấy danh sách các sản phẩm cha tương thích.
    final compatibleProductsAsync = ref.watch(compatibleParentProductsProvider(color));

    // Sử dụng `when` để xử lý các trạng thái khác nhau của FutureProvider.
    return compatibleProductsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Không tìm thấy dòng sản phẩm nào có thể pha được màu này.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Hiển thị danh sách sản phẩm nếu có dữ liệu.
        return ListView.builder(
          shrinkWrap: true, // Để ListView chỉ chiếm không gian cần thiết.
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: ListTile(
                title: Text(product.name),
                subtitle: Text(product.category),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Gọi callback khi người dùng nhấn vào một sản phẩm.
                  onParentProductSelected(product);
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Đã xảy ra lỗi: $error', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

