import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/cart_item.dart';
import '../../../data/models/color_data_model.dart';
import '../../../data/models/parent_product_model.dart';
import '../../../data/models/product_model.dart';
import '../../cart/application/cart_provider.dart';
import '../application/quote_providers.dart';
import 'quote_calculator.dart';

/// Trang hiển thị báo giá chi tiết cho một sản phẩm sơn pha màu.
class QuoteDetailPage extends ConsumerWidget {
  final Product sku;
  final ParentProduct parentProduct;
  final ColorData color;

  const QuoteDetailPage({
    super.key,
    required this.sku,
    required this.parentProduct,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theo dõi provider để lấy giá cuối cùng đã được tính toán.
    final priceAsync = ref.watch(
      finalPriceProvider((
        sku: sku,
        parentProduct: parentProduct,
        color: color,
      )),
    );

    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo giá chi tiết'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProductInfo(context),
          const SizedBox(height: 24),
          _buildColorInfo(context),
          const SizedBox(height: 24),
          _buildPriceListSelector(context),
          const Divider(height: 48),
          _buildFinalPrice(context, ref, priceAsync, currencyFormatter),
        ],
      ),
    );
  }

  /// Widget hiển thị thông tin sản phẩm.
  Widget _buildProductInfo(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.format_paint, size: 40),
        title: Text(
          parentProduct.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(sku.name),
      ),
    );
  }

  /// Widget hiển thị thông tin màu sắc.
  Widget _buildColorInfo(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hexToColor(color.hexCode),
          radius: 20,
        ),
        title: Text(
          color.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Mã màu: ${color.code}'),
      ),
    );
  }

  /// Widget cho phép chọn bảng giá (hiện tại đang bị vô hiệu hóa).
  Widget _buildPriceListSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn bảng giá:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        // Dropdown được vô hiệu hóa theo yêu cầu.
        DropdownButtonFormField<String>(
          value: 'chung',
          items: const [
            DropdownMenuItem(value: 'chung', child: Text('Bảng giá chung')),
          ],
          onChanged: null, // `null` sẽ vô hiệu hóa Dropdown.
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Lưu ý: Chức năng chọn nhiều bảng giá đang được xây dựng.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ],
    );
  }

  /// Widget hiển thị giá cuối cùng, xử lý các trạng thái loading/error.
  Widget _buildFinalPrice(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<QuotePriceDetails> priceDetailsAsync,
    NumberFormat formatter,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return priceDetailsAsync.when(
      data: (details) {
        return Column(
          children: [
            _PriceRow(
              label: 'Giá gốc sản phẩm',
              price: formatter.format(details.basePrice),
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            _PriceRow(
              label: 'Phí pha màu',
              price: formatter.format(details.colorPrice),
              style: textTheme.bodyLarge,
            ),
            const Divider(thickness: 1.5, height: 32),
            _PriceRow(
              label: 'THÀNH TIỀN',
              price: formatter.format(details.finalPrice),
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              priceStyle: textTheme.displaySmall?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Tạo một đối tượng CartItem từ thông tin hiện tại.
                final newItem = CartItem(
                  sku: sku,
                  parentProduct: parentProduct,
                  color: color,
                  priceDetails: details,
                );
                // Gọi notifier để thêm sản phẩm vào giỏ hàng.
                ref.read(cartProvider.notifier).addItem(newItem);

                // Hiển thị thông báo và quay lại trang trước.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã thêm sản phẩm vào giỏ hàng.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Thêm vào giỏ hàng'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                textStyle: textTheme.titleMedium,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          'Lỗi tính giá: $err',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// Helper function to convert hex string to Color.
// Copied from color_detail_page.dart to make this file self-contained.
Color hexToColor(String hexCode) {
  final buffer = StringBuffer();
  if (hexCode.length == 6 || hexCode.length == 7) buffer.write('ff');
  buffer.write(hexCode.replaceFirst('#', ''));
  try {
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    return Colors.grey;
  }
}

/// Một widget con để hiển thị một hàng trong bảng chi tiết giá.
class _PriceRow extends StatelessWidget {
  final String label;
  final String price;
  final TextStyle? style;
  final TextStyle? priceStyle;

  const _PriceRow({
    required this.label,
    required this.price,
    this.style,
    this.priceStyle,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodyLarge;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style ?? defaultStyle),
        Text(price, style: priceStyle ?? style ?? defaultStyle),
      ],
    );
  }
}
