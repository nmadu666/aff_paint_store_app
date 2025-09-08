import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/color_data_model.dart';
import '../../../data/models/parent_product_model.dart';
import '../../../data/models/product_model.dart';
import '../../quotes/presentation/quote_detail_page.dart';
import '../application/product_providers.dart';
import '../../colors/application/color_providers.dart';

/// Một trang cho phép người dùng chọn một SKU (dung tích) cụ thể
/// từ một `ParentProduct` đã chọn, dựa trên sự tương thích với một `ColorData`.
class SkuSelectionPage extends ConsumerWidget {
  final ColorData color;
  final ParentProduct parentProduct;

  const SkuSelectionPage({
    super.key,
    required this.color,
    required this.parentProduct,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Lấy danh sách tất cả các SKU cho sản phẩm cha.
    final skusAsync = ref.watch(skusForParentProvider(parentProduct.id));

    // 2. Lấy danh sách các loại gốc sơn ('A', 'B'...) phù hợp với màu đã chọn.
    final availableBasesAsync = ref.watch(
      availableBasesProvider((
        colorId: color.id,
        colorMixingProductType: parentProduct.colorMixingProductType,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(parentProduct.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(context, skusAsync, availableBasesAsync),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<Product>> skusAsync,
    AsyncValue<List<String>> basesAsync,
  ) {
    // Xử lý trạng thái loading và error của cả hai provider.
    if (skusAsync.isLoading || basesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (skusAsync.hasError || basesAsync.hasError) {
      final error = skusAsync.error ?? basesAsync.error;
      return Center(child: Text("Đã xảy ra lỗi: $error"));
    }

    // Khi cả hai đều có dữ liệu.
    final allSkus = skusAsync.value!;
    final availableBases = basesAsync.value!;

    // 3. Lọc danh sách SKU để chỉ giữ lại những SKU có gốc sơn phù hợp.
    final compatibleSkus = allSkus.where((sku) {
      return sku.base != null && availableBases.contains(sku.base);
    }).toList();

    if (compatibleSkus.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Không có dung tích nào của dòng sản phẩm "${parentProduct.name}" phù hợp để pha màu "${color.name}".',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    // 4. Hiển thị danh sách các SKU tương thích.
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: compatibleSkus.length,
      itemBuilder: (context, index) {
        final sku = compatibleSkus[index];
        final priceText = sku.basePrice != null
            ? '${sku.basePrice!.toStringAsFixed(0)}đ'
            : 'Chưa có giá';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(child: Text(sku.base ?? '?')),
            title: Text(sku.name),
            subtitle: Text(
              'Dung tích: ${sku.unitValue ?? 'N/A'}L - Giá gốc: $priceText',
            ),
            trailing: const Icon(Icons.add_shopping_cart),
            onTap: () {
              print('Đã chọn SKU: ${sku.name} (ID: ${sku.id})');
              // Điều hướng đến trang báo giá chi tiết
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QuoteDetailPage(
                    sku: sku,
                    parentProduct: parentProduct,
                    color: color,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
