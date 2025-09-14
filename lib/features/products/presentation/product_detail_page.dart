import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/cart_item.dart';
import '../../../data/models/color_data_model.dart';
import '../../../data/models/product_model.dart';
import '../../cart/application/cart_provider.dart';

/// Một trang để hiển thị thông tin chi tiết về một sản phẩm (SKU).
class ProductDetailPage extends ConsumerWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override 
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Phần hiển thị ảnh chính nếu có
          if (product.images != null && product.images!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  product.images!.first,
                  height: 200,
                  fit: BoxFit.cover,
                  // Thêm builder để có trải nghiệm người dùng tốt hơn khi tải ảnh
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: Icon(Icons.image_not_supported, size: 50)),
                    );
                  },
                ),
              ),
            ),

          // Phần thông tin chính
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (product.fullName != null && product.fullName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        product.fullName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    context,
                    icon: Icons.price_change,
                    label: 'Giá gốc',
                    value: product.basePrice != null
                        ? currencyFormatter.format(product.basePrice)
                        : 'Chưa có giá',
                    valueStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Phần thông số kỹ thuật
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _buildDetailListTile(
                    icon: Icons.qr_code_2,
                    label: 'Mã sản phẩm',
                    value: product.code,
                  ),
                  const Divider(height: 1),
                  _buildDetailListTile(
                    icon: Icons.straighten,
                    label: 'Đơn vị',
                    value: product.unit ?? 'N/A',
                  ),
                  if (product.unitValue != null) ...[
                    const Divider(height: 1),
                    _buildDetailListTile(
                      icon: Icons.science,
                      label: 'Dung tích',
                      value: '${product.unitValue} L',
                    ),
                  ],
                  if (product.base != null) ...[
                    const Divider(height: 1),
                    _buildDetailListTile(
                      icon: Icons.opacity,
                      label: 'Gốc sơn',
                      value: product.base!,
                    ),
                  ],
                  if (product.categoryName != null) ...[
                    const Divider(height: 1),
                    _buildDetailListTile(
                      icon: Icons.category,
                      label: 'Danh mục',
                      value: product.categoryName!,
                    ),
                  ],
                  if (product.tradeMarkName != null) ...[
                    const Divider(height: 1),
                    _buildDetailListTile(
                      icon: Icons.branding_watermark,
                      label: 'Thương hiệu',
                      value: product.tradeMarkName!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Phần mô tả
          if (product.description != null && product.description!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mô tả',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(product.description!),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Nút thêm vào giỏ hàng
          _AddToCartButton(product: product),
        ],
      ),
    );
  }

  // Widget trợ giúp để hiển thị một dòng thông tin chi tiết.
  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String label, required String value, TextStyle? valueStyle}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: valueStyle ?? Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ],
    );
  }

  // Widget trợ giúp để hiển thị thông tin dưới dạng ListTile.
  Widget _buildDetailListTile({required IconData icon, required String label, required String value}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      dense: true,
    );
  }
}

/// Nút "Thêm vào giỏ hàng" có quản lý trạng thái loading.
class _AddToCartButton extends ConsumerStatefulWidget {
  final Product product;
  const _AddToCartButton({required this.product});

  @override
  ConsumerState<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends ConsumerState<_AddToCartButton> {
  bool _isLoading = false;

  /// Hàm xử lý việc thêm sản phẩm vào giỏ hàng.
  Future<void> _addItemToCart() async {
    // Chỉ cần kiểm tra sản phẩm có giá là có thể thêm.
    if (widget.product.basePrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sản phẩm này không thể thêm vào giỏ hàng.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Tạo một đối tượng CartItem cho sản phẩm gốc (chưa pha màu).
      final newItem = CartItem(
        sku: widget.product,
        // Sử dụng một đối tượng ColorData mặc định cho màu trắng/gốc.
        color: const ColorData(
          id: 'base_white',
          name: 'Màu trắng gốc',
          code: 'White',
          hexCode: '#FFFFFF', ncs: '', trademarkRef: '', collectionRefs: [],
        ),
        // Giá của sản phẩm gốc không có phí pha màu.
        priceDetails: (
          basePrice: widget.product.basePrice!,
          colorPrice: 0,
          finalPrice: widget.product.basePrice!,
        ),
        quantity: 1,
      );

      // Gọi notifier để thêm vào giỏ hàng.
      ref.read(cartProvider.notifier).addItem(newItem);

      // Hiển thị thông báo thành công.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm sản phẩm vào giỏ hàng.')),
        );
      }
    } catch (e) {
      // Xử lý lỗi nếu có.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Điều kiện để thêm vào giỏ hàng giờ chỉ cần sản phẩm có giá.
    final canAddToCart = widget.product.basePrice != null;

    return ElevatedButton.icon(
      onPressed: (canAddToCart && !_isLoading) ? _addItemToCart : null,
      icon: _isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.add_shopping_cart),
      label: Text(_isLoading ? 'Đang thêm...' : 'Thêm vào giỏ hàng'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
