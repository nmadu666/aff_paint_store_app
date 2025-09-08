import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/cart_item.dart';
import '../../quotes/presentation/quote_detail_page.dart';
import '../application/cart_provider.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Text(
                'Giỏ hàng của bạn đang trống.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _CartItemTile(
                        item: item,
                        formatter: currencyFormatter,
                      );
                    },
                  ),
                ),
                _buildTotalSection(context, cartTotal, currencyFormatter),
              ],
            ),
    );
  }

  Widget _buildTotalSection(
    BuildContext context,
    double total,
    NumberFormat formatter,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng cộng:', style: Theme.of(context).textTheme.titleLarge),
              Text(
                formatter.format(total),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Điều hướng đến trang tạo báo giá hoặc thanh toán
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Chức năng tạo báo giá sẽ được phát triển sau.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              child: const Text('Tạo báo giá'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  final NumberFormat formatter;

  const _CartItemTile({required this.item, required this.formatter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: hexToColor(item.color.hexCode),
          ),
          title: Text(
            item.parentProduct.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.sku.name),
              Text('Màu: ${item.color.code}'),
              Text(
                '${formatter.format(item.priceDetails.finalPrice)} x ${item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              // Gọi notifier để xóa sản phẩm
              ref.read(cartProvider.notifier).removeItem(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã xóa "${item.parentProduct.name}" khỏi giỏ hàng.',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
