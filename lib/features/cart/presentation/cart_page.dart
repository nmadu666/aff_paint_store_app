import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/cart_item.dart';
import '../application/cart_provider.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Yêu cầu giữ lại trạng thái của widget này.

  @override
  Widget build(BuildContext context) {
    super.build(context); // Quan trọng: phải gọi super.build khi dùng mixin.

    final cartItems = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return cartItems.isEmpty
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

// Helper function để chuyển đổi chuỗi hex thành Color.
// Được sao chép ở đây để tránh import không cần thiết.
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
            // Nếu có parentProduct, hiển thị tên của nó, nếu không thì hiển thị tên SKU.
            item.parentProduct?.name ?? item.sku.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chỉ hiển thị tên SKU ở dòng phụ nếu có parentProduct.
              if (item.parentProduct != null) Text(item.sku.name),
              Text('Màu: ${item.color.code}'),
              Text(
                '${formatter.format(item.priceDetails.finalPrice)} x ${item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // Thay thế nút xóa bằng bộ điều khiển số lượng.
          trailing: _QuantityControl(item: item),
        ),
      ),
    );
  }
}

/// Widget để tăng/giảm số lượng sản phẩm trong giỏ hàng.
class _QuantityControl extends ConsumerWidget {
  final CartItem item;

  const _QuantityControl({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nút giảm số lượng
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                // Hiển thị icon thùng rác nếu số lượng là 1
                item.quantity == 1 ? Icons.delete_outline : Icons.remove,
                size: 18,
                color: item.quantity == 1 ? Colors.red : Colors.black,
              ),
              onPressed: () {
                ref
                    .read(cartProvider.notifier)
                    .updateQuantity(item.id, item.quantity - 1);
              },
            ),
          ),
          // Hiển thị số lượng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          // Nút tăng số lượng
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add, size: 18),
              onPressed: () {
                ref
                    .read(cartProvider.notifier)
                    .updateQuantity(item.id, item.quantity + 1);
              },
            ),
          ),
        ],
      ),
    );
  }
}
